import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_config.dart';
import '../ads/ad_remote_config.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// Edge-to-edge bottom native ad (AdMob small template).
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _loadAd();
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
        templateType: TemplateType.small,
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
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showRealAd = _isAdLoaded && _nativeAd != null;
    final borderColor = theme.colorScheme.primary.withValues(alpha: 0.12);

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final contentH = NativeAdWidget.contentHeight(context, layoutWidth: layoutWidth);

        return SizedBox(
          width: layoutWidth,
          child: Material(
          color: theme.cardColor,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(height: 1, thickness: 1, color: borderColor),
              RepaintBoundary(
                child: ClipRect(
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: layoutWidth,
                    height: contentH,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      fit: StackFit.expand,
                      children: [
                        NativeAdPlaceholder(contentHeight: contentH),
                        if (showRealAd)
                          _clippedAdView(
                            layoutWidth: layoutWidth,
                            contentHeight: contentH,
                            ad: _nativeAd!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (bottomInset > 0) SizedBox(height: bottomInset),
            ],
          ),
        ),
        );
      },
    );
  }
}

class NativeAdPlaceholder extends StatefulWidget {
  const NativeAdPlaceholder({super.key, this.contentHeight = NativeAdWidget.minContentHeight});

  final double contentHeight;

  @override
  State<NativeAdPlaceholder> createState() => _NativeAdPlaceholderState();
}

class _NativeAdPlaceholderState extends State<NativeAdPlaceholder> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final scheme = theme.colorScheme;
    final strings = context.l10n;
    final pulse = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _shimmer, curve: Curves.easeInOut),
    );
    final h = widget.contentHeight;
    final iconSize = math.min(48.0, h - 16).clamp(36.0, 48.0);
    final vPad = math.max(6.0, (h - iconSize) / 2 - 2).toDouble();

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Opacity(opacity: 0.55 + pulse.value * 0.35, child: child);
      },
      child: ColoredBox(
        color: theme.cardColor,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, vPad, 12, vPad),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.18),
                      AppColors.primaryDark.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: math.min(10.0, h * 0.12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: muted?.withValues(alpha: 0.25) ?? scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(height: math.max(4.0, h * 0.05)),
                    Container(
                      height: math.min(8.0, h * 0.09),
                      width: 120,
                      decoration: BoxDecoration(
                        color: muted?.withValues(alpha: 0.18) ?? scheme.outlineVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: math.min(64.0, MediaQuery.sizeOf(context).width * 0.18),
                height: math.min(34.0, h - 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  strings.adLabel,
                  style: TextStyle(color: scheme.primary, fontSize: 9, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
