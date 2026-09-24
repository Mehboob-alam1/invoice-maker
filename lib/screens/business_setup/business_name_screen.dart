import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_page_route.dart';
import '../../core/constants/app_texts.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../home/invoices_home_screen.dart';

/// Blue palette used by this screen.
class _Blue {
  static const seed = Color(0xFF2563EB); // royal blue
  static const deep = Color(0xFF1E3A8A); // navy
  static const bright = Color(0xFF1D4ED8);
  static const sky = Color(0xFF38BDF8);
}

/// Breakpoints
const double _kWideBreakpoint = 900; // tablets landscape / desktop / web
const double _kFormMaxWidth = 440;

class BusinessNameScreen extends StatefulWidget {
  const BusinessNameScreen({super.key});

  @override
  State<BusinessNameScreen> createState() => _BusinessNameScreenState();
}

class _BusinessNameScreenState extends State<BusinessNameScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final provider = context.read<InvoiceProvider>();
    final name = _controller.text.trim().isEmpty
        ? AppTexts.defaultBusinessName
        : _controller.text.trim();
    provider.setBusinessName(name);
    Navigator.of(context).pushReplacement(
      appPageRoute(const InvoicesHomeScreen(), adScopeKey: 'home'),
    );
  }

  /// Local blue theme + Space Grotesk. Keeps existing theme extensions.
  ThemeData _blueTheme(ThemeData base) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _Blue.seed,
      brightness: base.brightness,
    );
    final text = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );

    return base.copyWith(
      colorScheme: scheme,
      textTheme: text,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.primary.withValues(alpha: 0.06),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.primary.withValues(alpha: 0.18)),
        focusedBorder: border(scheme.primary, 2),
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.bodyLarge?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
              (s) => s.contains(WidgetState.focused)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blue = _blueTheme(Theme.of(context));

    return Theme(
      data: blue,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final strings = AppStrings.of(context);
          final muted = theme.extension<AppSemanticColors>()?.textMuted ??
              theme.colorScheme.onSurfaceVariant;

          return Scaffold(
            body: AppPageShell(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= _kWideBreakpoint;

                  final form = _FormPanel(
                    controller: _controller,
                    onContinue: _continue,
                    strings: strings,
                    muted: muted,
                    showBadge: !isWide,
                  );

                  if (!isWide) {
                    return SafeArea(child: _Scrollable(child: form));
                  }

                  // Wide screens: brand panel on the left, form on the right.
                  return Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _HeroPanel(title: strings.businessNameTitle),
                      ),
                      Expanded(
                        flex: 4,
                        child: SafeArea(child: _Scrollable(child: form)),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Scrolls when the keyboard opens or the screen is short (small phones,
/// landscape), and centers content when there is spare room.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width < 360 ? 20.0 : (width < 600 ? 28.0 : 40.0);

    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight - 56),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kFormMaxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.controller,
    required this.onContinue,
    required this.strings,
    required this.muted,
    required this.showBadge,
  });

  final TextEditingController controller;
  final VoidCallback onContinue;
  final AppStrings strings;
  final Color muted;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBadge) ...[
            const _BadgeIcon(),
            const SizedBox(height: 28),
          ],
          Text(
            strings.businessNameTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
              color: scheme.brightness == Brightness.light
                  ? _Blue.deep
                  : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: strings.businessNameHint,
              prefixIcon: const Icon(Icons.business_rounded),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onContinue(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              strings.businessNameHelp,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: muted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _GradientButton(
            label: strings.continueLabel,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Blue.bright, _Blue.sky],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _Blue.bright.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.storefront_rounded, size: 38, color: Colors.white),
    );
  }
}

/// Primary button with a blue gradient and a soft glow.
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_Blue.bright, Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _Blue.bright.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: textStyle),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Left-hand brand panel shown on tablets / desktop / web.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Blue.deep, _Blue.bright, Color(0xFF0EA5E9)],
        ),
      ),
      child: Stack(
        children: [
          // Soft decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: _Circle(size: 260, alpha: 0.08),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _Circle(size: 320, alpha: 0.07),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(56),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.alpha});
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}