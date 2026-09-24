import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_page_route.dart';
import '../../navigation/invoice_flow.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/invoice_provider.dart';
import '../../services/invoice_create_gate.dart';
import '../../widgets/blue_screen.dart';
import '../ocr/ocr_flow.dart';
import 'create_with_ai_screen.dart';
import 'new_invoice_screen.dart';
import '../../ads/ad_action.dart';
import '../../widgets/ui/app_page_shell.dart';

const double _kCardsRowBreakpoint = 800; // three cards side by side
const double _kColumnMaxWidth = 560;
const double _kRowMaxWidth = 1000;

// Extra blues used for the option icons.
const Color _kIndigo = Color(0xFF6366F1);
const Color _kSkyDeep = Color(0xFF0EA5E9);

class CreateInvoiceOptionsScreen extends StatelessWidget {
  const CreateInvoiceOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final invoiceProvider = context.watch<InvoiceProvider>();
    final aiUnlocked = invoiceProvider.subscriptionTier.canUseAiInvoice;

    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isLight = theme.brightness == Brightness.light;

          List<Widget> tiles(bool vertical) => [
            _OptionTile(
              vertical: vertical,
              icon: Icons.receipt_long_rounded,
              colors: const [BlueColors.bright, BlueColors.light],
              title: strings.customInvoice,
              subtitle: strings.customInvoiceSubtitle,
              onTap: () => runWithInterstitial(context, () {
                Navigator.of(context).push(
                  appInvoiceFlowRoute(const NewInvoiceScreen(), adScopeKey: 'new_invoice'),
                );
              }),
            ),
            _OptionTile(
              vertical: vertical,
              icon: Icons.document_scanner_rounded,
              colors: const [_kSkyDeep, BlueColors.sky],
              title: strings.scanWithOcr,
              subtitle: strings.scanOcrOptionSubtitle,
              onTap: () => runWithInterstitial(context, () => startOcrScan(context)),
            ),
            _OptionTile(
              vertical: vertical,
              icon: Icons.smart_toy_rounded,
              colors: const [_kIndigo, BlueColors.light],
              title: strings.createWithAi,
              subtitle: aiUnlocked
                  ? strings.aiTokensRemainingHint(
                invoiceProvider.aiTokensRemainingThisMonth,
                invoiceProvider.monthlyAiTokenLimit,
              )
                  : strings.aiPremiumPlanBadge,
              proLocked: !aiUnlocked,
              onTap: () async {
                if (!await ensurePaidAiAccessOrPrompt(context)) return;
                if (!context.mounted) return;
                runWithInterstitial(context, () {
                  Navigator.of(context).push(
                    appInvoiceFlowRoute(const CreateWithAiScreen(), adScopeKey: 'create_ai'),
                  );
                });
              },
            ),
          ];

          return Scaffold(
            appBar: AppBar(title: Text(strings.createInvoice)),
            body: AppPageShell(
              child: LayoutBuilder(
                builder: (context, c) {
                  final row = c.maxWidth >= _kCardsRowBreakpoint;
                  final hPad = c.maxWidth < 360 ? 14.0 : 20.0;
                  final items = tiles(row);

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: row ? _kRowMaxWidth : _kColumnMaxWidth,
                      ),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          12,
                          hPad,
                          24 + MediaQuery.viewPaddingOf(context).bottom,
                        ),
                        children: [
                          Text(
                            strings.howCreateInvoice,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: -0.4,
                              color: isLight ? BlueColors.deep : theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: row ? 36 : 28),
                          if (row)
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var i = 0; i < items.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 16),
                                    Expanded(child: items[i]),
                                  ],
                                ],
                              ),
                            )
                          else
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0) const SizedBox(height: 14),
                              items[i],
                            ],
                        ],
                      ),
                    ),
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool proLocked;
  final bool vertical;

  const _OptionTile({
    required this.icon,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.proLocked = false,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppSemanticColors>()?.textMuted ?? scheme.onSurfaceVariant;

    final iconTile = Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );

    final premiumBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'PREMIUM',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.primary,
          letterSpacing: 0.6,
        ),
      ),
    );

    final arrow = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        proLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_rounded,
        size: 18,
        color: scheme.primary,
      ),
    );

    final titleText = Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
    final subtitleText = Text(
      subtitle,
      style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.45),
    );

    final content = vertical
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            iconTile,
            const Spacer(),
            if (proLocked) premiumBadge,
          ],
        ),
        const SizedBox(height: 20),
        titleText,
        const SizedBox(height: 6),
        subtitleText,
        const Spacer(),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerRight, child: arrow),
      ],
    )
        : Row(
      children: [
        iconTile,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: titleText),
                  if (proLocked) ...[
                    const SizedBox(width: 8),
                    premiumBadge,
                  ],
                ],
              ),
              const SizedBox(height: 4),
              subtitleText,
            ],
          ),
        ),
        const SizedBox(width: 10),
        arrow,
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: BlueColors.bright.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(vertical ? 22 : 18),
            child: content,
          ),
        ),
      ),
    );
  }
}