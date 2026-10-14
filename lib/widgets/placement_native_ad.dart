import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ad_config.dart';
import '../ads/ad_placement.dart';
import '../ads/ad_remote_config.dart';
import '../providers/invoice_provider.dart';
import 'lazy_ad_slot.dart';
import 'native_ad_widget.dart';

/// Fixed native ad under a page, with a small margin on every side.
/// The page above it scrolls on its own.
class ScreenBottomAdSlot extends StatelessWidget {
  const ScreenBottomAdSlot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Padding only. A SafeArea here inserts a MediaQuery above the ad view,
    // and removing that view later trips a framework assertion.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 8, 10, bottomInset + 8),
      child: child,
    );
  }
}

/// Native ad for one screen. It loads when the screen opens.
class PlacementNativeAd extends StatelessWidget {
  const PlacementNativeAd({
    super.key,
    required this.placement,
    this.inline = false,
    this.large = false,
  });

  final AdPlacement placement;
  final bool inline;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AdRemoteConfig.instance.revision,
      builder: (context, _, _) {
        if (!AdConfig.isSupported) return const SizedBox.shrink();
        if (!AdRemoteConfig.instance.isPlacementEnabled(placement)) {
          return const SizedBox.shrink();
        }
        final invoices = context.watch<InvoiceProvider>();
        if (invoices.adsHeld || !invoices.featureTier.showNativeAds) {
          return const SizedBox.shrink();
        }
        return LazyAdSlot(
          builder: (_) => NativeAdWidget(
            key: ValueKey(placement.remoteKey),
            inline: inline,
            large: large,
          ),
        );
      },
    );
  }
}
