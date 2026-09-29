import 'package:flutter/foundation.dart';

import '../core/constants/production_ad_units.dart';

class AdConfig {
  AdConfig._();

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const androidAppId = 'ca-app-pub-3843970042444074~9694723819';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Optional HTTP override (CDN). Primary source is Firebase Remote Config.
  static const String? remoteAdConfigUrl = null;

  // Google sample ad units (development / store review only).
  static const testAndroidNative = 'ca-app-pub-3940256099942544/2247696110';
  static const testIosNative = 'ca-app-pub-3940256099942544/3986624511';
  static const testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const testAndroidAppOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const testIosAppOpen = 'ca-app-pub-3940256099942544/5575463023';

  static const _testPublisherId = '3940256099942544';

  static String get defaultAndroidNative => _pick(
        production: ProductionAdUnits.androidNative,
        test: testAndroidNative,
      );

  static String get defaultIosNative => _pick(
        production: ProductionAdUnits.iosNative,
        test: testIosNative,
      );

  static String get defaultAndroidInterstitial => _pick(
        production: ProductionAdUnits.androidInterstitial,
        test: testAndroidInterstitial,
      );

  static String get defaultIosInterstitial => _pick(
        production: ProductionAdUnits.iosInterstitial,
        test: testIosInterstitial,
      );

  static String get defaultAndroidAppOpen => _pick(
        production: ProductionAdUnits.androidAppOpen,
        test: testAndroidAppOpen,
      );

  static String get defaultIosAppOpen => _pick(
        production: ProductionAdUnits.iosAppOpen,
        test: testIosAppOpen,
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
