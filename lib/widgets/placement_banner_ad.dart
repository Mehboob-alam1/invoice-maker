import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../ads/ad_config.dart';
import '../ads/ad_consent.dart';
import '../ads/ad_placement.dart';
import '../ads/ad_remote_config.dart';
import '../ads/ad_service.dart';
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
    this.anchorTop = false,
    this.onHeight,
  });

  final AdPlacement placement;
  final bool collapsible;

  /// Draws the banner in its own card, separate from the page.
  final bool framed;

  /// Sits above the page, with margin on every side.
  final bool anchorTop;

  /// Reports the loaded creative height, or 0 when the bar is empty.
  final ValueChanged<double>? onHeight;

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
  VoidCallback? _whenSdkReady;

  void _schedule(int width) {
    if (width < 1 || _loaded || _loading || _attempts >= _maxAttempts) return;
    if (_scheduledWidth == width) return;
    _scheduledWidth = width;
    _load(width);
  }

  Future<void> _load(int width) async {
    if (_loading || _loaded || !mounted || !AdConfig.isSupported) return;
    if (!AdService.instance.isSdkReady) {
      if (_whenSdkReady != null) return;
      var waiting = true;
      void onReady() {
        if (!AdService.instance.isSdkReady) return;
        AdService.instance.sdkReady.removeListener(onReady);
        _whenSdkReady = null;
        waiting = false;
        if (mounted) _load(width);
      }

      _whenSdkReady = onReady;
      AdService.instance.sdkReady.addListener(onReady);
      // Start the SDK only when a banner is on screen.
      AdService.instance.ensureMobileAdsReady().then((ok) {
        if (!mounted || !waiting) return;
        if (!ok) {
          AdService.instance.sdkReady.removeListener(onReady);
          _whenSdkReady = null;
          _scheduledWidth = null;
          debugPrint('Banner ${widget.placement.remoteKey}: ads SDK not ready');
        }
      });
      return;
    }
    if (_attempts >= _maxAttempts || width < 1) return;
    if (!AdRemoteConfig.instance.isPlacementWanted(widget.placement)) return;
    if (!AdConsent.instance.canRequestAds) {
      debugPrint('Banner ${widget.placement.remoteKey} waiting for consent');
      _scheduledWidth = null;
      return;
    }
    final tier = context.read<InvoiceProvider>().featureTier;
    if (!tier.showNativeAds || context.read<InvoiceProvider>().adsHeld) {
      debugPrint('Banner ${widget.placement.remoteKey} skipped: tier/adsHeld');
      return;
    }

    final unitId = widget.collapsible
        ? AdRemoteConfig.instance.collapsibleBannerAdUnitId
        : AdRemoteConfig.instance.bannerAdUnitId;
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
        extras: widget.collapsible
            ? {'collapsible': widget.anchorTop ? 'top' : 'bottom'}
            : null,
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
          widget.onHeight?.call((ad as BannerAd).size.height.toDouble());
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
    final wait = _whenSdkReady;
    if (wait != null) AdService.instance.sdkReady.removeListener(wait);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AdRemoteConfig.instance.revision,
      builder: (context, _, _) {
        // Do not require consent here — that blocked SDK startup forever.
        if (!AdRemoteConfig.instance.isPlacementWanted(widget.placement)) {
          if (_ad != null || _loaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _releaseAd();
            });
          }
          return const SizedBox.shrink();
        }
        return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context).width;
        final safe = MediaQuery.paddingOf(context);
        final available = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : screen;
        final edgeToEdge = widget.collapsible && !widget.framed;
        final horizontalPad = edgeToEdge || !widget.framed ? 0.0 : 10.0;
        final sideInset = horizontalPad * 2 + (widget.framed ? safe.horizontal : 0);
        final requestWidth = edgeToEdge
            ? math.max(1, screen.truncate())
            : math.max(1, (available - sideInset).truncate());
        if (_ad == null) _schedule(requestWidth);

        final ad = _ad;
        if (!_loaded || ad == null) {
          return widget.framed
              ? const SizedBox(width: double.infinity, height: 0)
              : const SizedBox.shrink();
        }

        final creative = SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        );
        final align = widget.anchorTop ? Alignment.topCenter : Alignment.bottomCenter;
        final margin = edgeToEdge
            ? EdgeInsets.zero
            : widget.anchorTop
            ? EdgeInsets.fromLTRB(10 + safe.left, 8 + safe.top, 10 + safe.right, 8)
            : EdgeInsets.fromLTRB(10 + safe.left, 8, 10 + safe.right, 8 + safe.bottom);
        if (!widget.framed) {
          return Align(
            alignment: align,
            child: Padding(
              padding: margin,
              child: creative,
            ),
          );
        }

        final theme = Theme.of(context);
        return AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: align,
          child: Padding(
          padding: margin,
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
      },
    );
  }

  void _releaseAd() {
    final ad = _ad;
    _ad = null;
    _loaded = false;
    _loading = false;
    ad?.dispose();
    widget.onHeight?.call(0);
  }
}
