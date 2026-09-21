import 'package:flutter/foundation.dart';

class AdConfig {
  AdConfig._();

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Google's official native advanced test units.
  static const _androidNativeUnit = 'ca-app-pub-3940256099942544/2247696110';
  static const _iosNativeUnit = 'ca-app-pub-3940256099942544/3986624511';

  static String get nativeAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) return _iosNativeUnit;
    return _androidNativeUnit;
  }
}
