import 'package:flutter/material.dart';

/// Single app splash — tick icon on the brand blue background.
class SplashLaunchView extends StatelessWidget {
  const SplashLaunchView({super.key});

  static const assetPath = 'assets/images/splash_tick.png';

  /// Matches native window color until this view paints.
  static const backgroundColor = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final iconWidth = (MediaQuery.sizeOf(context).width * 0.42).clamp(140.0, 220.0);

    return ColoredBox(
      color: backgroundColor,
      child: Stack(
        children: [
          Center(
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
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Center(
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                      color: Colors.white,
                      backgroundColor: Color(0x38FFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
