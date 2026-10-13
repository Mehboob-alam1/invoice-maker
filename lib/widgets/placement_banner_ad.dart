import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../ads/ad_config.dart';
import '../ads/ad_placement.dart';
import '../ads/ad_remote_config.dart';
import '../core/constants/production_ad_units.dart';
import '../providers/invoice_provider.dart';

/// Banner requested when this slot is on screen.
///
/// A failed request is retried a few times. The ad view is inserted once, only
/// after a fill, so an empty bar is never shown and the creative is not dropped.
class PlacementBannerAd extends StatefulWidget {
  const PlacementBannerAd({
    super.key,
    required this.placement,
    this.collapsible = false,
    this.framed = false,
  });

  final AdPlacement placement;
  final bool collapsible;

  /// Draws the banner in its own card, separate from the page.
  final bool framed;

  @override
  State<PlacementBannerAd> createState() => _PlacementBannerAdState();
}

class _PlacementBannerAdState extends State<PlacementBannerAd> {
  static const _maxAttempts = 3;

  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;
  int _attempts = 0;
  int? _scheduledWidth;

  void _schedule(int width) {
    if (width < 1 || _loaded || _loading || _attempts >= _maxAttempts) return;
    if (_scheduledWidth == width) return;
    _scheduledWidth = width;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(width);
    });
  }

  Future<void> _load(int width) async {
    if (_loading || _loaded || !mounted || !AdConfig.isSupported) return;
    if (_attempts >= _maxAttempts || width < 1) return;
    if (!AdRemoteConfig.instance.isPlacementEnabled(widget.placement)) return;
    final tier = context.read<InvoiceProvider>().subscriptionTier;
    if (!tier.showNativeAds) return;

    final unitId = AdRemoteConfig.instance.bannerAdUnitId;
    if (!ProductionAdUnits.isValidUnit(unitId)) return;

    _loading = true;
    _attempts++;

    final adaptive = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || _ad != null) {
      _loading = false;
      return;
    }

    final ad = BannerAd(
      adUnitId: unitId,
      size: adaptive ?? AdSize.banner,
      request: AdRequest(
        extras: widget.collapsible ? const {'collapsible': 'bottom'} : null,
      ),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _loaded = true;
            _loading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ${widget.placement.remoteKey} failed: $error');
          if (identical(_ad, ad)) _ad = null;
          ad.dispose();
          _loading = false;
          _loaded = false;
          if (!mounted) return;
          if (_attempts < _maxAttempts) {
            Future<void>.delayed(Duration(milliseconds: 400 * _attempts), () {
              if (mounted) _load(width);
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context).width;
        final available = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : screen;
        final sideInset = widget.framed ? 24 + MediaQuery.paddingOf(context).horizontal : 0.0;
        final requestWidth = math.max(1, (available - sideInset).truncate());
        _schedule(requestWidth);

        final ad = _ad;
        if (!_loaded || ad == null) return const SizedBox.shrink();

        final creative = SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        );
        if (!widget.framed) {
          return SafeArea(top: false, child: Center(child: creative));
        }

        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ColoredBox(
                  color: theme.cardColor,
                  child: Center(child: creative),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
