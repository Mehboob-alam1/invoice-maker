import 'package:flutter/foundation.dart';

class AdConfig {
  AdConfig._();

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Optional HTTP override (CDN). Primary source is Firebase Remote Config.
  /// Same keys as [firebase/remote_config_values.json].
  static const String? remoteAdConfigUrl = null;

  /// Google test unit IDs (defaults until remote config loads).
  static const defaultAndroidNative = 'ca-app-pub-3940256099942544/2247696110';
  static const defaultIosNative = 'ca-app-pub-3940256099942544/3986624511';
  static const defaultAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const defaultIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const defaultAndroidAppOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const defaultIosAppOpen = 'ca-app-pub-3940256099942544/5575463023';

}
