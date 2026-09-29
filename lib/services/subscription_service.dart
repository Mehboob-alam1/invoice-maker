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
import 'user_firestore_service.dart';

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

    await loadProducts();
    await refreshEntitlementsFromStore(silent: true);
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

    for (final purchase in purchases) {
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
    _completeRestoreBatch();
    notifyListeners();
  }

  Future<void> _revokeToFreeIfNeeded() async {
    if (_invoiceProvider.subscriptionTier == SubscriptionTier.free) return;
    _invoiceProvider.setSubscriptionTier(SubscriptionTier.free);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await UserFirestoreService.instance.recordSubscription(
        uid: uid,
        tier: SubscriptionTier.free,
        productId: 'none',
      );
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(pendingRenewPromptKey, true);
    } catch (_) {}
  }

  void _grantPurchase(PurchaseDetails purchase) {
    final tier = SubscriptionProducts.tierForProductId(purchase.productID);
    if (tier == null) return;
    _invoiceProvider.setSubscriptionTier(tier);
    lastGrantedProductId = purchase.productID;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    UserFirestoreService.instance.recordSubscription(
      uid: uid,
      tier: tier,
      productId: purchase.productID,
      purchaseId: purchase.purchaseID,
    );
  }

  Future<void> syncTierToFirestoreIfNeeded() async {
    if (currentTier == SubscriptionTier.free) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await UserFirestoreService.instance.syncLocalSubscription(
      uid: uid,
      tier: currentTier,
      productId: lastGrantedProductId,
    );
  }
}
