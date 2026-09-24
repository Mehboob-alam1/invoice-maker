import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_page_route.dart';
import '../../navigation/invoice_flow.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/invoice_provider.dart';
import '../../services/invoice_create_gate.dart';
import '../ocr/ocr_flow.dart';
import 'create_with_ai_screen.dart';
import 'new_invoice_screen.dart';
import '../../ads/ad_action.dart';
import '../../widgets/ui/app_page_shell.dart';

class CreateInvoiceOptionsScreen extends StatelessWidget {
  const CreateInvoiceOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final invoiceProvider = context.watch<InvoiceProvider>();
    final aiUnlocked = invoiceProvider.subscriptionTier.canUseAiInvoice;
    return Scaffold(
      appBar: AppBar(title: Text(strings.createInvoice)),
      body: AppPageShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              strings.howCreateInvoice,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 28),
            _OptionTile(
              icon: Icons.receipt_long_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              title: strings.customInvoice,
              subtitle: strings.customInvoiceSubtitle,
              onTap: () => runWithInterstitial(context, () {
                Navigator.of(context).push(appInvoiceFlowRoute(const NewInvoiceScreen(), adScopeKey: 'new_invoice'));
              }),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.document_scanner_rounded,
              iconColor: Theme.of(context).colorScheme.tertiary,
              title: strings.scanWithOcr,
              subtitle: strings.scanOcrOptionSubtitle,
              onTap: () => runWithInterstitial(context, () => startOcrScan(context)),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.smart_toy_rounded,
              iconColor: Theme.of(context).colorScheme.secondary,
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
                  Navigator.of(context).push(appInvoiceFlowRoute(const CreateWithAiScreen(), adScopeKey: 'create_ai'));
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool proLocked;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.proLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.22),
                      iconColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        if (proLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'PREMIUM',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                  ],
                ),
              ),
              Icon(proLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
