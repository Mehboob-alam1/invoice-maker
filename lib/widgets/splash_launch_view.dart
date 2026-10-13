import 'package:flutter/material.dart';

import '../ads/ad_placement.dart';
import 'placement_native_ad.dart';

/// Single app splash — tick icon on the brand blue background.
class SplashLaunchView extends StatelessWidget {
  const SplashLaunchView({super.key, this.showAd = false});

  static const assetPath = 'assets/images/splash_tick.png';

  /// Matches native window color until this view paints.
  static const backgroundColor = Color(0xFF2563EB);

  /// Large native ad is only requested after the ads SDK is ready.
  final bool showAd;

  @override
  Widget build(BuildContext context) {
    final iconWidth = (MediaQuery.sizeOf(context).width * 0.42).clamp(140.0, 220.0);

    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(
                    assetPath,
                    gaplessPlayback: true,
                    width: iconWidth,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.check_rounded,
                      size: 96,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (showAd)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: PlacementNativeAd(
                    placement: AdPlacement.nativeSplash,
                    large: true,
                  ),
                ),
              const Text(
                'This action may contain ads',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  color: Colors.white,
                  backgroundColor: Color(0x38FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
