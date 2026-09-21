import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/theme_provider.dart';

/// A small icon button that flips between light and dark mode.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);
    final strings = context.l10n;

    return IconButton(
      tooltip: isDark ? strings.switchToLight : strings.switchToDark,
      onPressed: () => context.read<ThemeProvider>().toggle(context),
      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
    );
  }
}
