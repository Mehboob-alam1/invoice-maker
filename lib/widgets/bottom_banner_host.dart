import 'package:flutter/material.dart';

import '../ads/ad_placement.dart';
import 'placement_banner_ad.dart';

/// Screens that should not get the floating bottom banner.
mixin NoBottomBanner on Widget {}

/// Floating banner under the page. Hidden until the ad fills, and lifted off
/// the page so it reads as its own card.
class BottomBannerHost extends StatelessWidget {
  const BottomBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        Expanded(child: child),
        Offstage(
          offstage: keyboardOpen,
          child: const PlacementBannerAd(
            placement: AdPlacement.bannerScreen,
            framed: true,
          ),
        ),
      ],
    );
  }
}
