import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Flutter splash — logo asset includes its own text on a dark panel; use a light screen.
class SplashLaunchView extends StatelessWidget {
  const SplashLaunchView({
    super.key,
    this.statusText,
  });

  final String? statusText;

  static const _splashAsset = 'assets/images/splash_ai.png';

  /// Matches native window color for a seamless handoff (no second “splash”).
  static const backgroundColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoWidth = (size.width * 0.82).clamp(260.0, 400.0);

    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  _splashAsset,
                  width: logoWidth,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.receipt_long_rounded,
                    size: 72,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.blue.shade700,
                  ),
                ),
                if (statusText != null && statusText!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    statusText!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
