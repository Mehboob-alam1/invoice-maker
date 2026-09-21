import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Builds the app's light and dark [ThemeData].
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primaryDark,
            secondary: AppColors.secondary,
            tertiary: AppColors.tertiary,
            surface: AppColors.darkSurface,
            error: AppColors.danger,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            tertiary: AppColors.tertiary,
            surface: AppColors.lightSurface,
            error: AppColors.danger,
          );

    final textBase = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: textBase,
      displayColor: textBase,
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textBase),
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          minimumSize: const Size(96, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(colorScheme.primary),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: textMuted,
        indicatorColor: colorScheme.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      iconTheme: IconThemeData(color: textBase),
      extensions: [
        AppSemanticColors(
          textMuted: textMuted,
          border: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          heroGradient: isDark ? AppColors.heroGradientDark : AppColors.heroGradientLight,
        ),
      ],
    );
  }
}

/// Extra semantic tokens not covered by [ColorScheme], accessible via
/// `Theme.of(context).extension<AppSemanticColors>()`.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color textMuted;
  final Color border;
  final List<Color> heroGradient;

  const AppSemanticColors({
    required this.textMuted,
    required this.border,
    required this.heroGradient,
  });

  @override
  AppSemanticColors copyWith({Color? textMuted, Color? border, List<Color>? heroGradient}) {
    return AppSemanticColors(
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      heroGradient: heroGradient,
    );
  }
}
