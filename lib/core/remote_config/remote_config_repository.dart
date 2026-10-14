import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../../ads/ad_config.dart';
import '../../ads/ad_placement.dart';
import '../../models/subscription_tier.dart';
import 'invoice_limits_remote_config.dart';

/// Single Firebase Remote Config reader. Screens read flags from here.
class RemoteConfigRepository {
  RemoteConfigRepository._();
  static final RemoteConfigRepository instance = RemoteConfigRepository._();

  static const adConfigVersionKey = 'ad_config_version';

  bool _ready = false;
  StreamSubscription<RemoteConfigUpdate>? _updates;
  void Function()? onApplied;

  Future<void> ensureReady() async {
    if (_ready) return;
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 2),
      minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 12),
    ));
    await remoteConfig.setDefaults(defaults);
    try {
      await remoteConfig.fetchAndActivate().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Remote Config fetch used cache or defaults: $e');
      try {
        await remoteConfig.activate();
      } catch (_) {}
    }
    _updates ??= remoteConfig.onConfigUpdated.listen((_) async {
      try {
        await remoteConfig.activate();
        onApplied?.call();
      } catch (e) {
        debugPrint('Remote Config realtime update failed: $e');
      }
    });
    _ready = true;
    await _publishVersion();
  }

  Future<void> refresh() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetch();
    await remoteConfig.activate();
    await _publishVersion();
  }

  FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;

  bool flag(String key, {required bool fallback}) {
    if (!_ready) return fallback;
    return _rc.getBool(key);
  }

  int number(String key, {required int fallback}) {
    if (!_ready) return fallback;
    final asString = _rc.getString(key).trim();
    if (asString.isNotEmpty) {
      final parsed = int.tryParse(asString);
      if (parsed != null) return parsed;
    }
    return _rc.getInt(key);
  }

  String text(String key, {required String fallback}) {
    if (!_ready) return fallback;
    final value = _rc.getString(key).trim();
    return value.isEmpty ? fallback : value;
  }

  bool get adsEnabled => flag('ads_enabled', fallback: true);

  bool placementEnabled(AdPlacement placement) =>
      flag(placement.remoteKey, fallback: placement.defaultEnabled);

  int get interstitialMinIntervalSec =>
      number('interstitial_min_interval_sec', fallback: 90).clamp(0, 86400);

  int get interstitialMaxPerSession =>
      number('interstitial_max_per_session', fallback: 4).clamp(0, 100);

  int get interstitialMaxPerDay =>
      number('interstitial_max_per_day', fallback: 12).clamp(0, 200);

  int get appOpenMinIntervalMin =>
      number('app_open_min_interval_min', fallback: 240).clamp(0, 10080);

  int get appOpenMaxPerDay => number('app_open_max_per_day', fallback: 4).clamp(0, 50);

  int get appOpenMinBackgroundSec =>
      number('app_open_min_background_sec', fallback: 30).clamp(0, 3600);

  bool get adsGraceUntilFirstInvoice =>
      flag('ads_grace_until_first_invoice', fallback: true);

  bool get interstitialNavScreens => flag('ad_interstitial_nav_screens', fallback: false);

  int get rewardedDailyCap => number('rewarded_daily_cap', fallback: 10).clamp(0, 100);

  bool get referralEnabled => flag('referral_enabled', fallback: true);

  String get adConfigVersion => text(adConfigVersionKey, fallback: '1');

  String get paywallAfterSettingsMode =>
      text('paywall_after_settings_mode', fallback: 'once_per_day');

  /// A is the weekly card. B highlights weekly as the value plan. C leads with features.
  String get paywallVariant {
    final value = text('paywall_variant', fallback: 'A').toUpperCase();
    if (value == 'B' || value == 'C') return value;
    return 'A';
  }

  int get newUserBoostDays => number('free_invoice_new_user_boost_days', fallback: 7).clamp(0, 90);

  int get newUserBoostPerDay => number('free_invoice_new_user_boost_per_day', fallback: 5).clamp(0, 999);

  bool get watermarkFooterFree => flag('watermark_footer_free', fallback: true);

  bool get reviewPromptEnabled => flag('review_prompt_enabled', fallback: true);

  bool get weeklySummaryEnabled => flag('weekly_summary_enabled', fallback: true);

  int get minSupportedVersion => number('min_supported_version', fallback: 0).clamp(0, 1000000);

  String get announcementId => text('announcement_id', fallback: '');

  String get announcementTitle => text('announcement_title', fallback: '');

  String get announcementBody => text('announcement_body', fallback: '');

  String get marketDefaultsJson => text('market_defaults_json', fallback: _marketDefaultsFallback);

  static const _marketDefaultsFallback =
      '{"PK":{"bank":"HBL","wallet":"JazzCash"},"IN":{"bank":"HDFC","wallet":"UPI"},"default":{"bank":"Bank name","wallet":"Wallet"}}';

  Future<void> _publishVersion() async {
    try {
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'ad_config_version',
        value: adConfigVersion,
      );
    } catch (e) {
      debugPrint('ad_config_version user property skipped: $e');
    }
  }

  static Map<String, Object> get defaults => {
        'ads_enabled': true,
        'push_notifications_enabled': true,
        'ad_native_android': AdConfig.defaultAndroidNative,
        'ad_interstitial_android': AdConfig.defaultAndroidInterstitial,
        'ad_app_open_android': AdConfig.defaultAndroidAppOpen,
        'ad_banner_android': AdConfig.defaultAndroidBanner,
        'ad_rewarded_android': AdConfig.defaultAndroidRewarded,
        'paywall_close_delay_seconds': 5,
        for (final placement in AdPlacement.all) placement.remoteKey: placement.defaultEnabled,
        'ad_interstitial_nav_screens': false,
        'interstitial_min_interval_sec': 90,
        'interstitial_max_per_session': 4,
        'interstitial_max_per_day': 12,
        'interstitial_main_every_n_taps': 3,
        'interstitial_main_first_tap': true,
        'app_open_min_interval_min': 240,
        'app_open_max_per_day': 4,
        'app_open_min_background_sec': 30,
        'ads_grace_until_first_invoice': true,
        'ads_grace_first_session_minutes': 0,
        'native_cache_ttl_min': 50,
        'ad_load_retry_max': 3,
        'ad_load_retry_backoff_sec': 5,
        'rewarded_daily_cap': 10,
        'banner_type': 'adaptive_anchored',
        'banner_refresh_sec': 60,
        'paywall_after_settings_mode': 'once_per_day',
        'paywall_after_onboarding': true,
        'paywall_on_launch_free': true,
        'paywall_on_launch_every_n_launches': 1,
        'paywall_variant': 'A',
        'plans_enabled': 'weekly,monthly,yearly',
        'paywall_default_plan': 'yearly',
        'free_invoices_per_day': 3,
        'free_ai_credits_per_month': 3,
        'free_invoice_new_user_boost_days': 7,
        'free_invoice_new_user_boost_per_day': 5,
        'referral_enabled': true,
        'referral_referrer_ai_credits': 5,
        'referral_referee_ai_credits': 3,
        'referral_referrer_template_tokens': 1,
        'referral_referee_template_tokens': 1,
        'referral_monthly_cap': 20,
        'referral_milestones_json':
            '[{"count":1,"type":"template_token","amount":1},{"count":3,"type":"pro_days","amount":3},{"count":5,"type":"ai_credits","amount":10},{"count":10,"type":"pro_days","amount":30}]',
        'watermark_footer_free': true,
        'review_prompt_enabled': true,
        'weekly_summary_enabled': true,
        'mediation_enabled': false,
        'min_supported_version': 0,
        'announcement_id': '',
        'announcement_title': '',
        'announcement_body': '',
        'market_defaults_json': _marketDefaultsFallback,
        'invoice_link_enabled': false,
        adConfigVersionKey: '1',
        InvoiceLimitsRemoteConfig.remoteKeyFree: SubscriptionTier.free.dailyInvoiceLimit,
        InvoiceLimitsRemoteConfig.remoteKeyPremium: SubscriptionTier.premium.dailyInvoiceLimit,
      };
}
