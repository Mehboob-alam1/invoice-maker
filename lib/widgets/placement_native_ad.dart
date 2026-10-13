import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ad_config.dart';
import '../ads/ad_placement.dart';
import '../ads/ad_remote_config.dart';
import '../providers/invoice_provider.dart';
import 'native_ad_widget.dart';

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
    if (!AdConfig.isSupported) return const SizedBox.shrink();
    if (!AdRemoteConfig.instance.isPlacementEnabled(placement)) {
      return const SizedBox.shrink();
    }
    if (!context.watch<InvoiceProvider>().subscriptionTier.showNativeAds) {
      return const SizedBox.shrink();
    }
    return NativeAdWidget(
      key: ValueKey(placement.remoteKey),
      inline: inline,
      large: large,
    );
  }
}
