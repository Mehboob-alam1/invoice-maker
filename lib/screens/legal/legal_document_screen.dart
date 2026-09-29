// New packages needed:
//   google_fonts: ^6.2.1   (add to pubspec.yaml)
// New imports needed:
//   import 'package:google_fonts/google_fonts.dart';
//   import '../../core/theme/blue_theme.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/legal_content.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/ui/app_page_shell.dart';

enum LegalDocumentKind { privacy, community }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocumentKind kind;

  List<LegalSection> get _sections => switch (kind) {
    LegalDocumentKind.privacy => LegalContent.privacy,
    LegalDocumentKind.community => LegalContent.community,
  };

  String _title(AppStrings strings) => switch (kind) {
    LegalDocumentKind.privacy => strings.privacyPolicy,
    LegalDocumentKind.community => strings.communityGuidelines,
  };

  String _updated(AppStrings strings) => switch (kind) {
    LegalDocumentKind.privacy => strings.lastUpdated(AppConfig.privacyLastUpdated),
    LegalDocumentKind.community => strings.lastUpdated(AppConfig.guidelinesLastUpdated),
  };

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final strings = context.l10n;
          final muted = theme.extension<AppSemanticColors>()?.textMuted;
          final isDark = theme.brightness == Brightness.dark;
          final icon = kind == LegalDocumentKind.privacy
              ? Icons.privacy_tip_rounded
              : Icons.groups_2_rounded;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                _title(strings),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.4,
                  color: isDark ? Colors.white : BlueColors.navy,
                ),
              ),
            ),
            body: AppPageShell(
              child: _ResponsiveLegalBody(
                icon: icon,
                title: _title(strings),
                updated: _updated(strings),
                sections: _sections,
                muted: muted,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive body: single column on phones, 2 columns for sections on
// tablets, centered content with max width on desktop/web.
// ---------------------------------------------------------------------------

class _ResponsiveLegalBody extends StatelessWidget {
  const _ResponsiveLegalBody({
    required this.icon,
    required this.title,
    required this.updated,
    required this.sections,
    required this.muted,
  });

  final IconData icon;
  final String title;
  final String updated;
  final List<LegalSection> sections;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 360 ? 12.0 : 20.0;

        double maxContentWidth;
        int crossAxisCount;
        if (width >= 900) {
          maxContentWidth = 1100;
          crossAxisCount = 2;
        } else if (width >= 700) {
          maxContentWidth = 900;
          crossAxisCount = 2;
        } else {
          maxContentWidth = width;
          crossAxisCount = 1;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                28 + bottomSafe,
              ),
              children: [
                _HeaderCard(icon: icon, title: title, updated: updated, muted: muted),
                const SizedBox(height: 20),
                if (crossAxisCount == 1)
                  ...sections.map(
                        (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SectionCard(section: s, muted: muted),
                    ),
                  )
                else
                  _SectionGrid(sections: sections, muted: muted, crossAxisCount: crossAxisCount),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Header card: gradient icon tile + title + last-updated text.
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.updated,
    required this.muted,
  });

  final IconData icon;
  final String title;
  final String updated;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BlueColors.bright.withValues(alpha: isDark ? 0.0 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BlueColors.bright, BlueColors.sky],
              ),
              boxShadow: [
                BoxShadow(
                  color: BlueColors.bright.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : BlueColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    updated,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: muted ?? scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section grid for tablet/desktop widths (2 columns).
// ---------------------------------------------------------------------------

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({
    required this.sections,
    required this.muted,
    required this.crossAxisCount,
  });

  final List<LegalSection> sections;
  final Color? muted;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 190,
      ),
      itemBuilder: (context, i) => _SectionCard(section: sections[i], muted: muted),
    );
  }
}

// ---------------------------------------------------------------------------
// Styled section card.
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.muted});

  final LegalSection section;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BlueColors.bright.withValues(alpha: isDark ? 0.0 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            section.title,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: -0.2,
              color: isDark ? Colors.white : BlueColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}