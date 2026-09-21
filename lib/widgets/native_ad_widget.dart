import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_config.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// Compact native ad shown on every screen.
/// Loads an AdMob native template on Android/iOS, and a matching fallback
/// card when ads are unavailable (desktop, load failure, etc.).
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _didRequest = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRequest) return;
    _didRequest = true;
    _loadAd();
  }

  void _loadAd() {
    if (!AdConfig.isSupported) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.extension<AppSemanticColors>()?.textMuted ?? AppColors.lightTextSecondary;

    final ad = NativeAd(
      adUnitId: AdConfig.nativeAdUnitId,
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
          if (mounted) setState(() => _isAdLoaded = false);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: theme.colorScheme.primary,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: muted,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: _isAdLoaded && _nativeAd != null
            ? SizedBox(height: 108, child: AdWidget(ad: _nativeAd!))
            : NativeAdPlaceholder(),
      ),
    );
  }
}

/// Visual native-ad card used while the real ad loads, or on platforms
/// where AdMob is not available.
class NativeAdPlaceholder extends StatelessWidget {
  const NativeAdPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final scheme = theme.colorScheme;
    final strings = context.l10n;

    return Container(
      height: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.extension<AppSemanticColors>()?.border ?? scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.campaign_rounded, color: scheme.primary, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    strings.adLabel,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.growBusiness,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.sponsored,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              minimumSize: const Size(72, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(strings.open),
          ),
        ],
      ),
    );
  }
}
