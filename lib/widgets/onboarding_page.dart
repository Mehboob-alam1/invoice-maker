import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 320,
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
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
