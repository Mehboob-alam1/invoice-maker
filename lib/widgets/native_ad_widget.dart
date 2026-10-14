import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_config.dart';
import '../ads/ad_remote_config.dart';
import '../ads/ad_service.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'ad_creative_frame.dart';

/// Edge-to-edge bottom native ad (AdMob small template).
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key, this.inline = false, this.large = false});

  /// In-list ad. Uses the full small-template height so every asset stays inside the view.
  final bool inline;

  /// AdMob medium template, the larger built-in native layout.
  final bool large;

  /// AdMob small template baseline width (logical px).
  static const double templateDesignWidth = 360;

  /// Minimum content height per AdMob small template (dp).
  static const double minContentHeight = 91;

  /// Max before the bar steals too much vertical space on small phones.
  static const double maxContentHeight = 118;

  /// Content height for the ad platform view (excludes home-indicator padding).
  static double contentHeight(BuildContext context, {double? layoutWidth}) {
    final width = layoutWidth ?? MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    double h = minContentHeight;
    if (width < 330) {
      h = 102.0;
    } else if (width < 360) {
      h = 96.0;
    } else if (width > 420) {
      h = 94.0;
    }

    if (textScale > 1.2) {
      h += 14.0;
    } else if (textScale > 1.08) {
      h += 8.0;
    } else if (textScale > 1.0) {
      h += 4.0;
    }

    return h.clamp(minContentHeight, maxContentHeight).toDouble();
  }

  /// Scale factor when the screen is narrower than the template design width.
  static double widthScale(double layoutWidth) {
    if (layoutWidth >= templateDesignWidth) return 1;
    return (layoutWidth / templateDesignWidth).clamp(0.78, 1.0);
  }

  static double totalHeight(BuildContext context, {double? layoutWidth}) {
    final w = layoutWidth ?? MediaQuery.sizeOf(context).width;
    return contentHeight(context, layoutWidth: w) + MediaQuery.paddingOf(context).bottom;
  }

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _loadStarted = false;
  int _loadAttempts = 0;
  static const _maxLoadAttempts = 3;
  VoidCallback? _sdkListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _loadWhenSdkReady();
  }

  void _loadWhenSdkReady() {
    if (AdService.instance.isSdkReady) {
      _loadAd();
      return;
    }
    void onReady() {
      if (!AdService.instance.isSdkReady) return;
      AdService.instance.sdkReady.removeListener(onReady);
      _sdkListener = null;
      if (mounted) _loadAd();
    }

    _sdkListener = onReady;
    AdService.instance.sdkReady.addListener(onReady);
  }

  Future<void> _loadAd() async {
    if (!AdConfig.isSupported || !AdRemoteConfig.instance.adsEnabled) return;
    if (_loadAttempts >= _maxLoadAttempts) return;
    _loadAttempts++;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.extension<AppSemanticColors>()?.textMuted ?? AppColors.lightTextSecondary;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;

    unawaited(AdRemoteConfig.instance.load());

    final ad = NativeAd(
      adUnitId: AdRemoteConfig.instance.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _nativeAd = ad as NativeAd;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad failed: $error');
          ad.dispose();
          if (!mounted) return;
          setState(() => _isAdLoaded = false);
          if (_loadAttempts < _maxLoadAttempts) {
            Future<void>.delayed(const Duration(seconds: 6), () {
              if (mounted && !_isAdLoaded) _loadAd();
            });
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.large ? TemplateType.medium : TemplateType.small,
        mainBackgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        cornerRadius: 0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: theme.colorScheme.primary,
          style: NativeTemplateFontStyle.bold,
          size: compact ? 9.0 : 10.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          style: NativeTemplateFontStyle.bold,
          size: compact ? 10.0 : 11.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: muted,
          style: NativeTemplateFontStyle.normal,
          size: compact ? 8.0 : 9.0,
        ),
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    final listener = _sdkListener;
    if (listener != null) AdService.instance.sdkReady.removeListener(listener);
    _nativeAd?.dispose();
    super.dispose();
  }

  Widget _clippedAdView({
    required double layoutWidth,
    required double contentHeight,
    required NativeAd ad,
  }) {
    // Fit template to the exact bar width (edge-to-edge); clip vertical overflow.
    return RepaintBoundary(
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: layoutWidth,
          height: contentHeight,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: layoutWidth,
              height: contentHeight,
              child: AdWidget(ad: ad),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showRealAd = _isAdLoaded && _nativeAd != null;
    if (!showRealAd) return const SizedBox.shrink();
    final borderColor = theme.colorScheme.primary.withValues(alpha: 0.12);
    final framed = widget.inline || widget.large;
    final bottomInset = 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final contentH = widget.large
            ? 250.0
            : widget.inline
                ? 140.0
                : NativeAdWidget.contentHeight(context, layoutWidth: layoutWidth);
        final adView = widget.inline
            ? SizedBox(
                width: layoutWidth,
                height: contentH,
                child: AdWidget(ad: _nativeAd!),
              )
            : _clippedAdView(
                layoutWidth: layoutWidth,
                contentHeight: contentH,
                ad: _nativeAd!,
              );

        return AdCreativeFrame(
          child: SizedBox(
          width: layoutWidth,
          child: Material(
          color: theme.cardColor,
          elevation: 0,
          borderRadius: BorderRadius.zero,
          clipBehavior: widget.inline ? Clip.none : Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!framed) Divider(height: 1, thickness: 1, color: borderColor),
              RepaintBoundary(
                child: SizedBox(
                  width: layoutWidth,
                  height: contentH,
                  child: adView,
                ),
              ),
              if (bottomInset > 0) SizedBox(height: bottomInset),
            ],
          ),
        ),
        ),
        );
      },
    );
  }
}
