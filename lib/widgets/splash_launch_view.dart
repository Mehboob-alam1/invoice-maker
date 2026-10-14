import 'package:flutter/material.dart';

import 'placement_native_ad.dart';
import 'splash_native_slot.dart';

/// Single app splash — tick icon on the brand blue background.
class SplashLaunchView extends StatelessWidget {
  const SplashLaunchView({super.key});

  static const assetPath = 'assets/images/splash_tick.png';

  /// Matches native window color until this view paints.
  static const backgroundColor = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final iconWidth = (MediaQuery.sizeOf(context).width * 0.42).clamp(140.0, 220.0);
    final safe = MediaQuery.paddingOf(context);

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.only(top: 12 + safe.top),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 + safe.left),
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
            const SizedBox(height: 16),
            const ScreenBottomAdSlot(
              child: SplashNativeSlot(),
            ),
          ],
        ),
      ),
    );
  }
}
