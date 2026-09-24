import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ad_config.dart';

/// AdMob unit IDs + global toggles from Firebase Remote Config (with HTTP + local fallbacks).
class AdRemoteConfig {
  AdRemoteConfig._();
  static final AdRemoteConfig instance = AdRemoteConfig._();

  static bool _loaded = false;
  static bool get isLoaded => _loaded;

  bool _adsEnabled = true;
  bool _pushNotificationsEnabled = true;

  String _androidNative = AdConfig.defaultAndroidNative;
  String _iosNative = AdConfig.defaultIosNative;
  String _androidInterstitial = AdConfig.defaultAndroidInterstitial;
  String _iosInterstitial = AdConfig.defaultIosInterstitial;
  String _androidAppOpen = AdConfig.defaultAndroidAppOpen;
  String _iosAppOpen = AdConfig.defaultIosAppOpen;

  /// Remote Config key: set to `false` to turn off ads for everyone.
  bool get adsEnabled => _adsEnabled;

  /// Optional kill switch for prompting notification permission.
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;

  String get nativeAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) return _iosNative;
    return _androidNative;
  }

  String get interstitialAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) return _iosInterstitial;
    return _androidInterstitial;
  }

  String get appOpenAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) return _iosAppOpen;
    return _androidAppOpen;
  }

  Future<void> load() async {
    if (_loaded) return;

    await _loadFromFirebaseRemoteConfig();
    await _loadFromHttpUrlIfConfigured();

    _loaded = true;
  }

  /// Re-fetch Remote Config (e.g. on app resume).
  Future<void> refresh() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetch();
      await remoteConfig.activate();
      _applyRemoteConfigValues(remoteConfig);
    } catch (e) {
      debugPrint('AdRemoteConfig.refresh: $e');
    }
  }

  Future<void> _loadFromFirebaseRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));
      await remoteConfig.setDefaults(<String, dynamic>{
        'ads_enabled': true,
        'push_notifications_enabled': true,
        'ad_native_android': AdConfig.defaultAndroidNative,
        'ad_native_ios': AdConfig.defaultIosNative,
        'ad_interstitial_android': AdConfig.defaultAndroidInterstitial,
        'ad_interstitial_ios': AdConfig.defaultIosInterstitial,
        'ad_app_open_android': AdConfig.defaultAndroidAppOpen,
        'ad_app_open_ios': AdConfig.defaultIosAppOpen,
      });
      await remoteConfig.fetchAndActivate();
      _applyRemoteConfigValues(remoteConfig);
    } catch (e) {
      debugPrint('AdRemoteConfig: Firebase Remote Config failed ($e), using defaults.');
    }
  }

  void _applyRemoteConfigValues(FirebaseRemoteConfig remoteConfig) {
    _adsEnabled = remoteConfig.getBool('ads_enabled');
    _pushNotificationsEnabled = remoteConfig.getBool('push_notifications_enabled');

    void pickString(String key, void Function(String v) setter) {
      final v = remoteConfig.getString(key).trim();
      if (v.isNotEmpty) setter(v);
    }

    pickString('ad_native_android', (v) => _androidNative = v);
    pickString('ad_native_ios', (v) => _iosNative = v);
    pickString('ad_interstitial_android', (v) => _androidInterstitial = v);
    pickString('ad_interstitial_ios', (v) => _iosInterstitial = v);
    pickString('ad_app_open_android', (v) => _androidAppOpen = v);
    pickString('ad_app_open_ios', (v) => _iosAppOpen = v);
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
    pick('ad_native_ios', (v) => _iosNative = v);
    pick('ad_interstitial_android', (v) => _androidInterstitial = v);
    pick('ad_interstitial_ios', (v) => _iosInterstitial = v);
    pick('ad_app_open_android', (v) => _androidAppOpen = v);
    pick('ad_app_open_ios', (v) => _iosAppOpen = v);

    pick('android_native', (v) => _androidNative = v);
    pick('ios_native', (v) => _iosNative = v);
    pick('android_interstitial', (v) => _androidInterstitial = v);
    pick('ios_interstitial', (v) => _iosInterstitial = v);
    pick('android_app_open', (v) => _androidAppOpen = v);
    pick('ios_app_open', (v) => _iosAppOpen = v);
  }
}
