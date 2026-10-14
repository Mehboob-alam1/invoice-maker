import 'package:flutter/material.dart';

import '../ads/ad_placement.dart';
import 'placement_native_ad.dart';

/// Splash native. The request starts when this slot is on screen.
class SplashNativeSlot extends StatelessWidget {
  const SplashNativeSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlacementNativeAd(
      placement: AdPlacement.nativeSplash,
      large: true,
    );
  }
}
