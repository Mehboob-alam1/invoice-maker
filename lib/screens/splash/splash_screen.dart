import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
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
    final theme = Theme.of(context);
    final gradient = theme.extension<AppSemanticColors>()?.heroGradient ??
        [AppColors.primary, AppColors.primary.withValues(alpha: 0.82)];

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(Icons.receipt_long_rounded, size: 56, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Invoice Maker',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Receipts · OCR · PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
