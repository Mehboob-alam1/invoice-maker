import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Soft top gradient behind screen content for a consistent premium look.
class AppPageShell extends StatelessWidget {
  const AppPageShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hero = theme.extension<AppSemanticColors>()?.heroGradient ?? const [];
    final base = theme.scaffoldBackgroundColor;

    if (hero.length < 2) {
      return ColoredBox(color: base, child: child);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.28, 1],
          colors: [
            hero.first,
            Color.lerp(hero.last, base, 0.35)!,
            base,
          ],
        ),
      ),
      child: child,
    );
  }
}
