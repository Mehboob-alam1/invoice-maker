import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../models/subscription_tier.dart';

/// Daily invoice caps from Firebase Remote Config (overrides [SubscriptionTier] defaults).
class InvoiceLimitsRemoteConfig {
  InvoiceLimitsRemoteConfig._();
  static final InvoiceLimitsRemoteConfig instance = InvoiceLimitsRemoteConfig._();

  static const remoteKeyFree = 'free_daily_invoice_limit';
  static const remoteKeyPremium = 'premium_daily_invoice_limit';

  int _freeDailyLimit = SubscriptionTier.free.dailyInvoiceLimit;
  int _premiumDailyLimit = SubscriptionTier.premium.dailyInvoiceLimit;

  int get freeDailyLimit => _freeDailyLimit;

  int get premiumDailyLimit => _premiumDailyLimit;

  int limitForTier(SubscriptionTier tier) => switch (tier) {
        SubscriptionTier.free => _freeDailyLimit,
        SubscriptionTier.premium => _premiumDailyLimit,
        SubscriptionTier.pro => SubscriptionTier.pro.dailyInvoiceLimit,
      };

  void applyFrom(FirebaseRemoteConfig remoteConfig) {
    _freeDailyLimit = _readLimit(
      remoteConfig,
      remoteKeyFree,
      SubscriptionTier.free.dailyInvoiceLimit,
    );
    _premiumDailyLimit = _readLimit(
      remoteConfig,
      remoteKeyPremium,
      SubscriptionTier.premium.dailyInvoiceLimit,
    );
  }

  void applyFromMap(Map<String, dynamic> map) {
    _freeDailyLimit = _readLimitFromMap(
      map,
      remoteKeyFree,
      SubscriptionTier.free.dailyInvoiceLimit,
    );
    _premiumDailyLimit = _readLimitFromMap(
      map,
      remoteKeyPremium,
      SubscriptionTier.premium.dailyInvoiceLimit,
    );
  }

  static int _readLimit(FirebaseRemoteConfig remoteConfig, String key, int fallback) {
    final asString = remoteConfig.getString(key).trim();
    if (asString.isNotEmpty) {
      final parsed = int.tryParse(asString);
      if (parsed != null) return _clampLimit(parsed);
    }
    final asInt = remoteConfig.getInt(key);
    if (asInt != 0) return _clampLimit(asInt);
    return fallback;
  }

  static int _readLimitFromMap(Map<String, dynamic> map, String key, int fallback) {
    final v = map[key];
    if (v is int) return _clampLimit(v);
    if (v is num) return _clampLimit(v.toInt());
    if (v is String) {
      final parsed = int.tryParse(v.trim());
      if (parsed != null) return _clampLimit(parsed);
    }
    return fallback;
  }

  /// `-1` = unlimited; `0` = no invoices per day.
  static int _clampLimit(int value) => value.clamp(-1, 999);
}
