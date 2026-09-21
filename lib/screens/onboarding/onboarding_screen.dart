import 'package:flutter/material.dart';

import '../../core/constants/app_texts.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/onboarding_page.dart';
import 'language_screen.dart';

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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LanguageScreen(fromOnboarding: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.l10n;
    final pages = strings.onboardingSlides;
    final gradient = theme.extension<AppSemanticColors>()?.heroGradient ?? [];
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final p = pages[i];
                    return OnboardingPage(title: p.title, subtitle: p.subtitle, image: p.image);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(pages.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _next,
                      child: Text(isLast ? strings.getStarted : strings.next),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
