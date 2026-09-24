import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/blue_screen.dart';
import '../onboarding/language_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/invoices_home_screen.dart';
import '../onboarding/google_login_screen.dart';
import '../business_setup/business_name_screen.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_page_route.dart';
import '../../providers/invoice_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween<double>(begin: 0.88, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 2200), _goNext);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    final provider = context.read<InvoiceProvider>();
    Widget next;
    if (provider.hasCompletedOnboarding) {
      next = const InvoicesHomeScreen();
    } else if (!provider.onboardingLanguageDone) {
      next = const LanguageScreen(fromOnboarding: true);
    } else if (!provider.onboardingCarouselDone) {
      next = const OnboardingScreen();
    } else if (!provider.onboardingGoogleStepDone) {
      next = const GoogleLoginScreen();
    } else {
      next = const BusinessNameScreen();
    }
    Navigator.of(context).pushReplacement(appFadeRoute<void>(next));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);

    final bgColors = isDark
        ? const [Color(0xFF0B1220), Color(0xFF0F1B33), Color(0xFF0B1220)]
        : const [Color(0xFFEFF6FF), Color(0xFFFFFFFF), Color(0xFFE0F2FE)];
    final titleColor = isDark ? Colors.white : BlueColors.navy;
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.78) : BlueColors.navy.withValues(alpha: 0.75);

    return Scaffold(
      backgroundColor: bgColors.first,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Soft decorative glows
          Positioned(
            top: -size.shortestSide * 0.25,
            right: -size.shortestSide * 0.25,
            child: IgnorePointer(child: _GlowBlob(diameter: size.shortestSide * 0.85, color: BlueColors.sky, isDark: isDark)),
          ),
          Positioned(
            bottom: -size.shortestSide * 0.3,
            left: -size.shortestSide * 0.3,
            child: IgnorePointer(child: _GlowBlob(diameter: size.shortestSide * 0.9, color: BlueColors.light, isDark: isDark)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final isWide = w >= 900;
                final hPad = w < 360 ? 16.0 : 24.0;
                final tileSize = (isWide ? 128.0 : 112.0) * textScale.clamp(1.0, 1.25);

                final tile = ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: tileSize,
                    height: tileSize,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [BlueColors.bright, BlueColors.sky],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(Icons.receipt_long_rounded, size: tileSize * 0.5, color: Colors.white),
                  ),
                );

                final titleBlock = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppConfig.appDisplayName,
                      textAlign: isWide ? TextAlign.start : TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: isWide ? 44 : 30,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 16, color: scheme.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Receipts · OCR · PDF',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final brand = isWide
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    tile,
                    const SizedBox(width: 36),
                    Flexible(child: titleBlock),
                  ],
                )
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    tile,
                    const SizedBox(height: 28),
                    titleBlock,
                  ],
                );

                final loader = Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: scheme.primary),
                );

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 48),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: FadeTransition(
                          opacity: _fade,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              brand,
                              const SizedBox(height: 56),
                              loader,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.diameter, required this.color, required this.isDark});

  final double diameter;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.18 : 0.28),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}