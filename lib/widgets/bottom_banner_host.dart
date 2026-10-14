import 'package:flutter/material.dart';

import '../ads/ad_placement.dart';
import 'placement_banner_ad.dart';

/// Screens that should not get the floating bottom banner.
mixin NoBottomBanner on Widget {}

/// Collapsible banner drawn over the bottom of the page.
///
/// Once the ad has a height, that much space is added to the page's bottom
/// padding so a bottom button scrolls up and sits just above the bar.
class BottomBannerHost extends StatefulWidget {
  const BottomBannerHost({super.key, required this.child});

  final Widget child;

  @override
  State<BottomBannerHost> createState() => _BottomBannerHostState();
}

class _BottomBannerHostState extends State<BottomBannerHost> {
  double _bannerHeight = 0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;
    final lift = keyboardOpen ? 0.0 : _bannerHeight;
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaQuery(
          data: media.copyWith(
            padding: media.padding.copyWith(bottom: media.padding.bottom + lift),
            viewPadding: media.viewPadding.copyWith(bottom: media.viewPadding.bottom + lift),
          ),
          child: widget.child,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: media.viewPadding.bottom,
          child: Offstage(
            offstage: keyboardOpen,
            child: PlacementBannerAd(
              placement: AdPlacement.bannerScreen,
              collapsible: true,
              onHeight: (height) {
                if (!mounted || _bannerHeight == height) return;
                setState(() => _bannerHeight = height);
              },
            ),
          ),
        ),
      ],
    );
  }
}
