import 'package:flutter/foundation.dart';

import '../core/constants/production_ad_units.dart';

class AdConfig {
  AdConfig._();

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const androidAppId = 'ca-app-pub-3843970042444074~9694723819';

  /// Optional HTTP override (CDN). Primary source is Firebase Remote Config.
  static const String? remoteAdConfigUrl = null;

  // Google sample ad units (development / store review only).
  static const testAndroidNative = 'ca-app-pub-3940256099942544/2247696110';
  static const testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const testAndroidAppOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const testAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const _testPublisherId = '3940256099942544';

  static String get defaultAndroidNative => _pick(
        production: ProductionAdUnits.androidNative,
        test: testAndroidNative,
      );

  static String get defaultAndroidInterstitial => _pick(
        production: ProductionAdUnits.androidInterstitial,
        test: testAndroidInterstitial,
      );

  static String get defaultAndroidAppOpen => _pick(
        production: ProductionAdUnits.androidAppOpen,
        test: testAndroidAppOpen,
      );

  static String get defaultAndroidBanner => _pick(
        production: ProductionAdUnits.androidBanner,
        test: testAndroidBanner,
      );

  static String get defaultAndroidRewarded => _pick(
        production: ProductionAdUnits.androidRewarded,
        test: testAndroidRewarded,
      );

  static String _pick({required String production, required String test}) {
    if (kDebugMode) return test;
    if (ProductionAdUnits.isValidUnit(production)) return production;
    return test;
  }

  /// True if [unitId] is a Google demo / test ad unit (avoid in production).
  static bool isTestAdUnit(String unitId) => unitId.contains(_testPublisherId);

  static bool get releaseShouldUseRemoteConfigUnits =>
      !kDebugMode && !ProductionAdUnits.isConfigured;
}
