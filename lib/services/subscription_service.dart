import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/subscription_products.dart';
import '../models/subscription_tier.dart';
import '../providers/invoice_provider.dart';
import 'user_database_service.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

/// Google Play / App Store auto-renewing subscriptions (Premium & Pro).
class SubscriptionService extends ChangeNotifier {
  SubscriptionService(this._invoiceProvider);

  final InvoiceProvider _invoiceProvider;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool storeAvailable = false;
  bool loadingProducts = false;
  bool purchasePending = false;
  String? lastError;

  final Map<String, ProductDetails> _products = {};

  String? lastGrantedProductId;

  bool _sawPaidProductThisCheck = false;
  Completer<void>? _restoreBatchDone;

  /// Set when Play restore finds no active subscription (prompt renew on home).
  static const pendingRenewPromptKey = 'pending_subscription_renew_prompt';

  /// Shown once on the paywall after a paid plan ends.
  static const winBackEligibleKey = 'paywall_winback_eligible';

  SubscriptionTier get currentTier => _invoiceProvider.subscriptionTier;

  bool get isPro => currentTier == SubscriptionTier.pro;

  ProductDetails? productFor(SubscriptionTier tier, {required bool yearly}) {
    if (tier == SubscriptionTier.free) return null;
    final id = SubscriptionProducts.productIdFor(tier, yearly: yearly);
    return _products[id];
  }

  Future<void> initialize() async {
    storeAvailable = await _iap.isAvailable();
    if (!storeAvailable) {
      notifyListeners();
      return;
    }

    _purchaseSub ??= _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) {
        lastError = e.toString();
        purchasePending = false;
        _completeRestoreBatch();
        notifyListeners();
      },
    );
    notifyListeners();
    unawaited(_loadCatalogAndEntitlements());
  }

  Future<void> _loadCatalogAndEntitlements() async {
    try {
      await loadProducts();
      await refreshEntitlementsFromStore(silent: true);
    } catch (error) {
      debugPrint('SubscriptionService background refresh: $error');
    }
  }

  /// Play Store is the source of truth. After restore, downgrade if no active SKU.
  Future<void> refreshEntitlementsFromStore({bool silent = false}) async {
    if (!storeAvailable) return;
    _sawPaidProductThisCheck = false;
    _restoreBatchDone = Completer<void>();
    if (!silent) {
      purchasePending = true;
      notifyListeners();
    }
    try {
      await _iap.restorePurchases();
      await _restoreBatchDone!.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('SubscriptionService: restore batch timed out');
        },
      );
      if (!_sawPaidProductThisCheck) {
        await _revokeToFreeIfNeeded();
      }
    } catch (e) {
      lastError = e.toString();
      debugPrint('SubscriptionService.refreshEntitlementsFromStore: $e');
    } finally {
      _restoreBatchDone = null;
      if (!silent) {
        purchasePending = false;
        notifyListeners();
      }
    }
  }

  void _completeRestoreBatch() {
    final done = _restoreBatchDone;
    if (done != null && !done.isCompleted) {
      done.complete();
    }
  }

  Future<void> disposeService() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
  }

  Future<void> loadProducts() async {
    if (!storeAvailable) return;
    loadingProducts = true;
    lastError = null;
    notifyListeners();

    try {
      final response = await _iap.queryProductDetails(SubscriptionProducts.storeProductIds);
      if (response.error != null) {
        lastError = response.error!.message;
      }
      _products.clear();
      for (final p in response.productDetails) {
        _products[p.id] = p;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'Subscription IDs not in Play Console yet: ${response.notFoundIDs}. '
          'Create auto-renewing subscriptions with these exact product IDs.',
        );
      }
    } finally {
      loadingProducts = false;
      notifyListeners();
    }
  }

  String? priceForProduct(String productId) => _products[productId]?.price;

  /// Play offer tagged winback, or whose offer id contains "win". Null when Play has no discount.
  ({String token, String price})? get winBackOffer {
    final product = _products[SubscriptionProducts.weekly];
    if (product is! GooglePlayProductDetails) return null;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (offers == null) return null;
    SubscriptionOfferDetailsWrapper? match;
    for (final offer in offers) {
      if (offer.offerId == null) continue;
      final id = offer.offerId!.toLowerCase();
      final tags = offer.offerTags.map((tag) => tag.toLowerCase());
      if (id.contains('win') || tags.any((tag) => tag.contains('win'))) {
        match = offer;
        break;
      }
    }
    if (match == null) return null;
    final price = match.pricingPhases.isEmpty ? product.price : match.pricingPhases.first.formattedPrice;
    return (token: match.offerIdToken, price: price);
  }

  Future<bool> purchaseProductId(String productId, {String? offerToken}) async {
    final product = _products[productId];
    if (!storeAvailable || product == null) {
      lastError = 'Store or product unavailable. Check Play Console product IDs.';
      notifyListeners();
      return false;
    }
    purchasePending = true;
    _syncAdsHeld(pending: true);
    lastError = null;
    notifyListeners();

    final PurchaseParam param = Platform.isAndroid
        ? GooglePlayPurchaseParam(productDetails: product, offerToken: offerToken)
        : PurchaseParam(productDetails: product);

    try {
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        purchasePending = false;
        _syncAdsHeld(pending: false);
        notifyListeners();
      }
      return started;
    } catch (e) {
      lastError = e.toString();
      purchasePending = false;
      _syncAdsHeld(pending: false);
      notifyListeners();
      return false;
    }
  }

  void _syncAdsHeld({required bool pending, bool grace = false}) {
    _invoiceProvider.setAdsHeld(pending || grace || purchasePending);
  }

  String priceLabel(SubscriptionTier tier, {required bool yearly, String fallback = '—'}) {
    final p = productFor(tier, yearly: yearly);
    if (p == null) return fallback;
    return p.price;
  }

  Future<bool> purchaseTier(SubscriptionTier tier, {required bool yearly}) async {
    if (tier == SubscriptionTier.free) return false;
    final product = productFor(tier, yearly: yearly);
    if (!storeAvailable || product == null) {
      lastError = 'Store or product unavailable. Check Play Console product IDs.';
      notifyListeners();
      return false;
    }
    purchasePending = true;
    lastError = null;
    notifyListeners();

    final PurchaseParam param = Platform.isAndroid
        ? GooglePlayPurchaseParam(productDetails: product)
        : PurchaseParam(productDetails: product);

    try {
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      lastError = e.toString();
      purchasePending = false;
      notifyListeners();
      return false;
    }
  }

  Future<String> restorePurchases({bool silent = false}) async {
    if (!storeAvailable) {
      return silent ? '' : 'Store unavailable';
    }
    await refreshEntitlementsFromStore(silent: silent);
    if (lastError != null) return 'Restore failed';
    return currentTier != SubscriptionTier.free ? 'Subscription restored' : 'No active subscription found';
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    SubscriptionTier bestFromBatch = SubscriptionTier.free;
    var grace = false;

    for (final purchase in purchases) {
      if (purchase is GooglePlayPurchaseDetails) {
        final raw = purchase.billingClientPurchase.originalJson.toLowerCase();
        if (raw.contains('grace')) grace = true;
        if (purchase.billingClientPurchase.pendingPurchaseUpdate != null) {
          purchasePending = true;
        }
      }
      switch (purchase.status) {
        case PurchaseStatus.pending:
          purchasePending = true;
          break;
        case PurchaseStatus.error:
          purchasePending = false;
          lastError = purchase.error?.message ?? 'Purchase failed';
          break;
        case PurchaseStatus.canceled:
          purchasePending = false;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (SubscriptionProducts.allPaidProductIds.contains(purchase.productID)) {
            _sawPaidProductThisCheck = true;
            final tier = SubscriptionProducts.tierForProductId(purchase.productID);
            if (tier != null && tier.index > bestFromBatch.index) {
              bestFromBatch = tier;
            }
            _grantPurchase(purchase);
          }
          purchasePending = false;
          lastError = null;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }

    if (bestFromBatch != SubscriptionTier.free) {
      _invoiceProvider.setSubscriptionTier(bestFromBatch);
    }
    _syncAdsHeld(pending: purchasePending, grace: grace);
    _completeRestoreBatch();
    notifyListeners();
  }

  Future<void> _revokeToFreeIfNeeded() async {
    if (_invoiceProvider.subscriptionTier == SubscriptionTier.free) return;
    _invoiceProvider.setSubscriptionTier(SubscriptionTier.free);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await UserDatabaseService.instance.recordSubscription(
        uid: uid,
        tier: SubscriptionTier.free,
        productId: 'none',
      );
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(pendingRenewPromptKey, true);
      await prefs.setBool(winBackEligibleKey, true);
    } catch (_) {}
  }

  void _grantPurchase(PurchaseDetails purchase) {
    final tier = SubscriptionProducts.tierForProductId(purchase.productID);
    if (tier == null) return;
    _invoiceProvider.setSubscriptionTier(tier);
    lastGrantedProductId = purchase.productID;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    UserDatabaseService.instance.recordSubscription(
      uid: uid,
      tier: tier,
      productId: purchase.productID,
      purchaseId: purchase.purchaseID,
    );
  }

  Future<void> syncTierToCloudIfNeeded() async {
    if (currentTier == SubscriptionTier.free) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await UserDatabaseService.instance.syncLocalSubscription(
      uid: uid,
      tier: currentTier,
      productId: lastGrantedProductId,
    );
  }
}
