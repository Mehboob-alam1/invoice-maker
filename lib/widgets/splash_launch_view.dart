import 'package:flutter/material.dart';

/// Brand splash shown only while saved invoices and theme are read.
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
      child: Center(
        child: Image.asset(
          assetPath,
          gaplessPlayback: true,
          width: iconWidth,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => const Icon(
            Icons.check_rounded,
            size: 96,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
