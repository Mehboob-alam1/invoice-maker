import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_texts.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/app_page_route.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/onboarding_page.dart';
import 'google_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    final pageCount = AppTexts.onboarding.length;
    if (_page < pageCount - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      context.read<InvoiceProvider>().completeOnboardingCarouselStep();
      Navigator.of(context).pushReplacement(appPageRoute(const GoogleLoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // buildBlueTheme is expected to use base.copyWith(...) so extensions such
    // as AppSemanticColors survive.
    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(builder: (innerContext) => _buildBody(innerContext)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final strings = context.l10n;
    final pages = strings.onboardingSlides;
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [BlueColors.navy, BlueColors.bright, BlueColors.light],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Decorative soft circles for depth (no interaction, no semantics).
            Positioned(
              top: -90,
              right: -70,
              child: IgnorePointer(
                child: ExcludeSemantics(child: _GlowCircle(size: 280, alpha: 0.08)),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -80,
              child: IgnorePointer(
                child: ExcludeSemantics(child: _GlowCircle(size: 240, alpha: 0.06)),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final hPad = w < 360 ? 16.0 : 28.0;
                  final maxW = w >= 900 ? 1000.0 : (w >= 700 ? 680.0 : 560.0);

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: Column(
                        children: [
                          Expanded(
                            child: PageView.builder(
                              controller: _controller,
                              itemCount: pages.length,
                              onPageChanged: (i) => setState(() => _page = i),
                              itemBuilder: (context, i) {
                                final p = pages[i];
                                // Each page scrolls when the viewport is short
                                // (landscape, big text) but still gets a bounded
                                // height so Expanded/Spacer inside it keep working.
                                return LayoutBuilder(
                                  builder: (context, page) => SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: SizedBox(
                                      height: math.max(page.maxHeight, 460.0),
                                      child: OnboardingPage(
                                        title: p.title,
                                        subtitle: p.subtitle,
                                        image: p.image,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 28),
                            child: Row(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(pages.length, (i) {
                                    final active = i == _page;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOutCubic,
                                      margin: const EdgeInsetsDirectional.only(end: 6),
                                      width: active ? 26 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: active
                                            ? [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.35),
                                            blurRadius: 10,
                                          ),
                                        ]
                                            : null,
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: _NextButton(
                                      label: isLast ? strings.getStarted : strings.next,
                                      onPressed: _next,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withValues(alpha: alpha), Colors.transparent],
        ),
      ),
    );
  }
}

/// White pill on the blue background (a blue gradient button would vanish
/// here), with a blue-to-light-blue arrow chip. Height is a minimum so it
/// grows with the system text scale.
class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56, minWidth: 132),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(22, 8, 12, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BlueColors.bright,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [BlueColors.bright, BlueColors.light],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}