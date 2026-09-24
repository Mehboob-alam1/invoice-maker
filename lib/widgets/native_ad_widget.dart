import 'dart:async';

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

  /// Matches AdMob small template min height so assets stay inside the platform view.
  static const double barHeight = 91;

  static double totalHeight(BuildContext context) =>
      barHeight + MediaQuery.paddingOf(context).bottom;

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
    if (!AdConfig.isSupported) return;
    if (_loadAttempts >= _maxLoadAttempts) return;
    _loadAttempts++;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.extension<AppSemanticColors>()?.textMuted ?? AppColors.lightTextSecondary;

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
          size: 10.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          style: NativeTemplateFontStyle.bold,
          size: 11.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: muted,
          style: NativeTemplateFontStyle.normal,
          size: 9.0,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showRealAd = _isAdLoaded && _nativeAd != null;
    final borderColor = theme.dividerColor.withValues(alpha: 0.85);

    return Material(
      color: theme.cardColor,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, thickness: 1, color: borderColor),
          ClipRect(
            child: SizedBox(
              width: double.infinity,
              height: NativeAdWidget.barHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(child: NativeAdPlaceholder()),
                  if (showRealAd)
                    Positioned.fill(
                      child: ClipRect(
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: MediaQuery.sizeOf(context).width,
                          height: NativeAdWidget.barHeight,
                          child: AdWidget(ad: _nativeAd!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (bottomInset > 0) SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}

class NativeAdPlaceholder extends StatefulWidget {
  const NativeAdPlaceholder({super.key});

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

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Opacity(opacity: 0.55 + pulse.value * 0.35, child: child);
      },
      child: ColoredBox(
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: muted?.withValues(alpha: 0.25) ?? scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 8,
                      width: 140,
                      decoration: BoxDecoration(
                        color: muted?.withValues(alpha: 0.18) ?? scheme.outlineVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 64,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  strings.adLabel,
                  style: TextStyle(color: scheme.primary, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
