import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/blue_theme.dart';
import '../l10n/app_strings.dart';
import '../providers/theme_provider.dart';

/// A small icon button that flips between light and dark mode.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);
    final strings = context.l10n;

    return Tooltip(
      message: isDark ? strings.switchToLight : strings.switchToDark,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.read<ThemeProvider>().toggle(context),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 22,
                color: isDark ? BlueColors.sky : BlueColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
