import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
        notifyListeners();
      },
    );

    await loadProducts();
    await restorePurchases(silent: true);
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
      final response = await _iap.queryProductDetails(SubscriptionProducts.allPaidProductIds);
      if (response.error != null) {
        lastError = response.error!.message;
      }
      _products.clear();
      for (final p in response.productDetails) {
        _products[p.id] = p;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Subscription IDs not in store yet: ${response.notFoundIDs}');
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
      lastError = 'Store or product unavailable';
      notifyListeners();
      return false;
    }
    purchasePending = true;
    lastError = null;
    notifyListeners();

    final param = PurchaseParam(productDetails: product);
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
    if (!silent) {
      purchasePending = true;
      notifyListeners();
    }
    try {
      await _iap.restorePurchases();
      if (!silent) {
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      }
      return currentTier != SubscriptionTier.free ? 'Subscription restored' : 'No active subscription found';
    } catch (e) {
      lastError = e.toString();
      return 'Restore failed';
    } finally {
      if (!silent) {
        purchasePending = false;
        notifyListeners();
      }
    }
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
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
    notifyListeners();
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
