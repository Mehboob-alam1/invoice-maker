import 'package:flutter/material.dart';

import '../ads/ad_config.dart';
import '../widgets/bottom_banner_host.dart';
import '../widgets/native_ad_host.dart';

/// Wraps [page] with a bottom native ad that is tied to this route only.
Widget wrapPageWithNativeAd(
  Widget page, {
  required String adScopeKey,
}) {
  if (!AdConfig.isSupported) return page;
  return NativeAdHost(adScopeKey: adScopeKey, child: page);
}

/// Standard push route — each screen gets its own native ad instance.
Route<T> appPageRoute<T>(
  Widget page, {
  RouteSettings? settings,
  String? adScopeKey,
  bool showNativeAd = false,
}) {
  final scope = adScopeKey ?? settings?.name ?? page.runtimeType.toString();
  return MaterialPageRoute<T>(
    settings: settings ?? RouteSettings(name: scope),
    builder: (context) {
      final child = showNativeAd ? wrapPageWithNativeAd(page, adScopeKey: scope) : page;
      if (page is NoBottomBanner) return child;
      return BottomBannerHost(child: child);
    },
  );
}

/// Fade transition (e.g. splash → home) with optional per-screen native ad.
Route<T> appFadeRoute<T>(
  Widget page, {
  String? adScopeKey,
  bool showNativeAd = false,
  Duration duration = const Duration(milliseconds: 450),
}) {
  final scope = adScopeKey ?? page.runtimeType.toString();
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: scope),
    transitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) {
      final child = showNativeAd ? wrapPageWithNativeAd(page, adScopeKey: scope) : page;
      if (page is NoBottomBanner) return child;
      return BottomBannerHost(child: child);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
