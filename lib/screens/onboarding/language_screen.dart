import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_languages.dart';
import '../../l10n/app_strings.dart';
import '../../navigation/app_page_route.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/ui/app_page_shell.dart';
import 'onboarding_screen.dart';

class LanguageScreen extends StatefulWidget {
  final bool fromOnboarding;

  const LanguageScreen({super.key, this.fromOnboarding = false});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = context.read<InvoiceProvider>().languageCode;
  }

  List<AppLanguage> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return AppLanguages.all;
    return AppLanguages.all.where((l) {
      return l.englishName.toLowerCase().contains(q) ||
          l.nativeName.toLowerCase().contains(q) ||
          l.code.toLowerCase().contains(q);
    }).toList();
  }

  void _select(AppLanguage language) {
    setState(() => _selected = language.code);
    context.read<InvoiceProvider>().setLanguage(language.code);
  }

  void _continue() {
    final provider = context.read<InvoiceProvider>();
    provider.setLanguage(_selected);
    if (widget.fromOnboarding) {
      provider.completeOnboardingLanguageStep();
      Navigator.of(context).pushReplacement(appPageRoute(const OnboardingScreen()));
    } else {
      Navigator.of(context).pop();
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.extension<AppSemanticColors>()?.textMuted ?? cs.onSurfaceVariant;
    final titleColor = isDark ? cs.onSurface : BlueColors.navy;
    final strings = AppStrings.of(context);
    final languages = _filtered;
    final gradient = <Color>[BlueColors.bright, BlueColors.light];
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      appBar: widget.fromOnboarding
          ? null
          : AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: titleColor),
        title: Text(
          strings.selectLanguage,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: titleColor,
          ),
        ),
      ),
      body: AppPageShell(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final hPad = w < 360 ? 14.0 : (w < 700 ? 20.0 : 28.0);
              final maxW = w >= 900 ? 1100.0 : (w >= 700 ? 760.0 : 560.0);
              final columns = w >= 900 ? 3 : (w >= 700 ? 2 : 1);
              // Tile height follows the system text scale so nothing clips.
              final tileExtent = math.max(84.0, textScaler.scale(84));

              final search = TextField(
                onChanged: (v) => setState(() => _query = v),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: strings.searchLanguage,
                  hintStyle: TextStyle(color: muted),
                  prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                  filled: true,
                  fillColor: cs.primary.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              );

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.fromOnboarding) ...[
                                      const SizedBox(height: 12),
                                      _GradientTile(
                                        icon: Icons.translate_rounded,
                                        gradient: gradient,
                                        size: 56,
                                        radius: 18,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        strings.selectLanguage,
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                          letterSpacing: -0.6,
                                          color: titleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        strings.selectLanguageSubtitle,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: muted,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    search,
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: tileExtent,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                      (context, i) {
                                    final language = languages[i];
                                    return _LanguageTile(
                                      language: language,
                                      selected: language.code == _selected,
                                      muted: muted,
                                      gradient: gradient,
                                      onTap: () => _select(language),
                                    );
                                  },
                                  childCount: languages.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w >= 700 ? 420 : double.infinity),
                            child: BlueGradientButton(
                              label: strings.continueLabel,
                              onPressed: _continue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Rounded gradient tile with a white icon.
class _GradientTile extends StatelessWidget {
  const _GradientTile({
    required this.icon,
    required this.gradient,
    required this.size,
    required this.radius,
  });

  final IconData icon;
  final List<Color> gradient;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.muted,
    required this.gradient,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final Color muted;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fill = selected
        ? Color.alphaBlend(cs.primary.withValues(alpha: 0.08), cs.surface)
        : cs.surface;

    return Semantics(
      button: true,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: BlueColors.bright.withValues(alpha: selected ? 0.10 : 0.07),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: fill,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? cs.primary : cs.primary.withValues(alpha: 0.12),
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(language.flag, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.nativeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          language.englishName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      language.code.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  selected
                      ? Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  )
                      : Icon(Icons.circle_outlined, color: muted, size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}