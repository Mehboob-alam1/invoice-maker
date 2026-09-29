import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Shared blue palette (Material 3 seed + accents).
class BlueColors {
  BlueColors._();

  static const seed = Color(0xFF2563EB);
  static const deep = Color(0xFF1E3A8A);
  static const navy = deep;
  static const bright = Color(0xFF1D4ED8);
  static const light = Color(0xFF3B82F6);
  static const sky = Color(0xFF38BDF8);
}

/// Optional grouped surface — flat, no shadow (prefer open layouts over nested cards).
BoxDecoration blueCardDecoration(ThemeData theme, {double radius = 16}) {
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
        : scheme.surface,
    borderRadius: BorderRadius.circular(radius),
  );
}

/// Applies blue [ColorScheme], typography, app bar, inputs, and buttons on [base].
/// Preserves [AppSemanticColors] and other extensions from [base].
ThemeData buildBlueTheme(ThemeData base) {
  final scheme = ColorScheme.fromSeed(
    seedColor: BlueColors.seed,
    brightness: base.brightness,
  );
  final isLight = scheme.brightness == Brightness.light;
  final text = spaceGroteskTextTheme(base.textTheme).apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  final merged = base.copyWith(
    colorScheme: scheme,
    textTheme: text,
    primaryTextTheme: spaceGroteskTextTheme(base.primaryTextTheme),
    scaffoldBackgroundColor: base.scaffoldBackgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: isLight ? BlueColors.navy : scheme.onSurface),
      foregroundColor: isLight ? BlueColors.navy : scheme.onSurface,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: isLight ? BlueColors.navy : scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.primary.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(Colors.transparent),
      enabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.5)),
      focusedBorder: border(scheme.primary, 1.5),
      labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      floatingLabelStyle: text.bodyLarge?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
      ),
      prefixIconColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.focused) ? scheme.primary : scheme.onSurfaceVariant,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
    ),
  );
  return merged.copyWith(extensions: base.extensions.values);
}

/// Primary CTA — flat blue, minimal chrome.
class BlueGradientButton extends StatelessWidget {
  const BlueGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        );
    final enabled = onPressed != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled || loading ? 1 : 0.5,
      child: Material(
        color: enabled ? scheme.primary : scheme.primary.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: style,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (loading) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                  ),
                ] else if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: scheme.onPrimary, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
