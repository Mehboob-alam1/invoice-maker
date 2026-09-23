import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ad_config.dart';

/// Loads AdMob unit IDs from a remote JSON endpoint (Firebase Remote Config–style keys).
/// Falls back to [AdConfig] test IDs when fetch fails or URL is empty.
class AdRemoteConfig {
  AdRemoteConfig._();
  static final AdRemoteConfig instance = AdRemoteConfig._();

  static bool _loaded = false;
  static bool get isLoaded => _loaded;

  String _androidNative = AdConfig.defaultAndroidNative;
  String _iosNative = AdConfig.defaultIosNative;
  String _androidInterstitial = AdConfig.defaultAndroidInterstitial;
  String _iosInterstitial = AdConfig.defaultIosInterstitial;
  String _androidAppOpen = AdConfig.defaultAndroidAppOpen;
  String _iosAppOpen = AdConfig.defaultIosAppOpen;

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

  /// Remote JSON keys (match Firebase Remote Config parameter names).
  Future<void> load() async {
    if (_loaded) return;
    final url = AdConfig.remoteAdConfigUrl?.trim();
    if (url != null && url.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          _applyMap(jsonDecode(response.body) as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('AdRemoteConfig: fetch failed ($e), using defaults.');
      }
    }
    _loaded = true;
  }

  void _applyMap(Map<String, dynamic> map) {
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

    // Alternate flat keys
    pick('android_native', (v) => _androidNative = v);
    pick('ios_native', (v) => _iosNative = v);
    pick('android_interstitial', (v) => _androidInterstitial = v);
    pick('ios_interstitial', (v) => _iosInterstitial = v);
    pick('android_app_open', (v) => _androidAppOpen = v);
    pick('ios_app_open', (v) => _iosAppOpen = v);
  }
}
