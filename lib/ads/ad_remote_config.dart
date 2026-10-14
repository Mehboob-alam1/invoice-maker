import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/production_ad_units.dart';
import '../core/remote_config/invoice_limits_remote_config.dart';
import '../core/remote_config/remote_config_repository.dart';
import 'ad_config.dart';
import 'ad_consent.dart';
import 'ad_placement.dart';

/// AdMob unit IDs + global toggles from Firebase Remote Config (with HTTP + local fallbacks).
class AdRemoteConfig {
  AdRemoteConfig._();
  static final AdRemoteConfig instance = AdRemoteConfig._();

  static bool _loaded = false;
  static bool get isLoaded => _loaded;

  bool _adsEnabled = true;
  bool _pushNotificationsEnabled = true;

  String _androidNative = AdConfig.defaultAndroidNative;
  String _androidInterstitial = AdConfig.defaultAndroidInterstitial;
  String _androidAppOpen = AdConfig.defaultAndroidAppOpen;
  String _androidBanner = AdConfig.defaultAndroidBanner;
  String _androidRewarded = AdConfig.defaultAndroidRewarded;

  final Map<String, bool> _placementEnabled = {
    for (final placement in AdPlacement.all) placement.remoteKey: placement.defaultEnabled,
  };

  /// Bumps when Remote Config is applied so on-screen ads can hide.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  int _paywallCloseDelaySeconds = 5;

  /// Remote Config key: set to `false` to turn off ads for everyone.
  bool get adsEnabled => _adsEnabled;

  /// Optional kill switch for prompting notification permission.
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;

  String get nativeAdUnitId =>
      AdConfig.useTestAdUnits ? AdConfig.testAndroidNative : _androidNative;

  String get interstitialAdUnitId =>
      AdConfig.useTestAdUnits ? AdConfig.testAndroidInterstitial : _androidInterstitial;

  String get appOpenAdUnitId =>
      AdConfig.useTestAdUnits ? AdConfig.testAndroidAppOpen : _androidAppOpen;

  String get bannerAdUnitId {
    if (AdConfig.useTestAdUnits) return AdConfig.testAndroidBanner;
    return ProductionAdUnits.isValidUnit(_androidBanner) ? _androidBanner : AdConfig.defaultAndroidBanner;
  }

  /// Debug uses Google's collapsible sample. Release uses the live banner unit.
  String get collapsibleBannerAdUnitId {
    if (AdConfig.useTestAdUnits) return AdConfig.testAndroidCollapsibleBanner;
    return bannerAdUnitId;
  }

  String get rewardedAdUnitId {
    if (AdConfig.useTestAdUnits) return AdConfig.testAndroidRewarded;
    return ProductionAdUnits.isValidUnit(_androidRewarded)
        ? _androidRewarded
        : AdConfig.defaultAndroidRewarded;
  }

  /// Master switch, the per-screen switch, and consent must all allow the ad.
  bool isPlacementEnabled(AdPlacement placement) =>
      _adsEnabled &&
      (_placementEnabled[placement.remoteKey] ?? placement.defaultEnabled) &&
      AdConsent.instance.canRequestAds;

  int get paywallCloseDelaySeconds => _paywallCloseDelaySeconds;

  Future<void> load() async {
    if (_loaded) return;
    RemoteConfigRepository.instance.onApplied = applyActive;
    await RemoteConfigRepository.instance.ensureReady();
    applyActive();
    await _loadFromHttpUrlIfConfigured();
    _loaded = true;
  }

  Future<void> refresh() async {
    try {
      await RemoteConfigRepository.instance.refresh();
      applyActive();
    } catch (e) {
      debugPrint('AdRemoteConfig.refresh: $e');
    }
  }

  void applyActive() {
    _applyRemoteConfigValues(FirebaseRemoteConfig.instance);
    revision.value++;
  }

  void _applyRemoteConfigValues(FirebaseRemoteConfig remoteConfig) {
    _adsEnabled = remoteConfig.getBool('ads_enabled');
    _pushNotificationsEnabled = remoteConfig.getBool('push_notifications_enabled');

    void pickString(String key, void Function(String v) setter) {
      final v = remoteConfig.getString(key).trim();
      if (v.isNotEmpty) setter(v);
    }

    pickString('ad_native_android', (v) => _androidNative = v);
    pickString('ad_interstitial_android', (v) => _androidInterstitial = v);
    pickString('ad_app_open_android', (v) => _androidAppOpen = v);
    pickString('ad_banner_android', (v) => _androidBanner = v);
    pickString('ad_rewarded_android', (v) => _androidRewarded = v);
    _paywallCloseDelaySeconds = remoteConfig.getInt('paywall_close_delay_seconds');
    if (_paywallCloseDelaySeconds < 0) _paywallCloseDelaySeconds = 0;
    for (final placement in AdPlacement.all) {
      _placementEnabled[placement.remoteKey] = remoteConfig.getBool(placement.remoteKey);
    }

    InvoiceLimitsRemoteConfig.instance.applyFrom(remoteConfig);

    if (!kDebugMode) {
      for (final id in [
        _androidNative,
        _androidInterstitial,
        _androidAppOpen,
      ]) {
        if (AdConfig.isTestAdUnit(id)) {
          debugPrint(
            'AdRemoteConfig: WARNING — release build is using Google TEST ad unit $id. '
            'Set production IDs in Firebase Remote Config.',
          );
        }
      }
    }
  }

  Future<void> _loadFromHttpUrlIfConfigured() async {
    final url = AdConfig.remoteAdConfigUrl?.trim();
    if (url == null || url.isEmpty) return;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        _applyMap(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('AdRemoteConfig: HTTP config failed ($e).');
    }
  }

  void _applyMap(Map<String, dynamic> map) {
    final ads = map['ads_enabled'];
    if (ads is bool) _adsEnabled = ads;
    if (ads is String) _adsEnabled = ads.toLowerCase() == 'true';

    final push = map['push_notifications_enabled'];
    if (push is bool) _pushNotificationsEnabled = push;
    if (push is String) _pushNotificationsEnabled = push.toLowerCase() == 'true';

    void pick(String key, void Function(String v) setter) {
      final v = map[key];
      if (v is String && v.trim().isNotEmpty) setter(v.trim());
    }

    pick('ad_native_android', (v) => _androidNative = v);
    pick('ad_interstitial_android', (v) => _androidInterstitial = v);
    pick('ad_app_open_android', (v) => _androidAppOpen = v);
    pick('ad_banner_android', (v) => _androidBanner = v);
    pick('ad_rewarded_android', (v) => _androidRewarded = v);

    final delay = map['paywall_close_delay_seconds'];
    if (delay is int) _paywallCloseDelaySeconds = delay;
    if (delay is num) _paywallCloseDelaySeconds = delay.round();
    if (_paywallCloseDelaySeconds < 0) _paywallCloseDelaySeconds = 0;

    for (final placement in AdPlacement.all) {
      final raw = map[placement.remoteKey];
      if (raw is bool) _placementEnabled[placement.remoteKey] = raw;
      if (raw is String) {
        _placementEnabled[placement.remoteKey] = raw.toLowerCase() != 'false';
      }
    }

    pick('android_native', (v) => _androidNative = v);
    pick('android_interstitial', (v) => _androidInterstitial = v);
    pick('android_app_open', (v) => _androidAppOpen = v);

    InvoiceLimitsRemoteConfig.instance.applyFromMap(map);
  }
}
