import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/blue_theme.dart';

/// One page of the onboarding [PageView] — headline, hero image
/// and a supporting subtitle.
class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? theme.colorScheme.onSurface : BlueColors.navy;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = constraints.maxWidth < 360 ? 20.0 : 28.0;
        final imageH = (constraints.maxHeight * 0.42).clamp(220.0, 340.0);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  height: 1.2,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: imageH,
                child: Center(
                  child: Image.asset(
                    image,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
