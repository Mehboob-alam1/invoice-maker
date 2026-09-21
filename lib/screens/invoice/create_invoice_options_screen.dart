import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../ocr/ocr_flow.dart';
import 'create_with_ai_screen.dart';
import 'new_invoice_screen.dart';

class CreateInvoiceOptionsScreen extends StatelessWidget {
  const CreateInvoiceOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(strings.createInvoice)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            Text(
              strings.howCreateInvoice,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 28),
            _OptionTile(
              icon: Icons.receipt_long_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              title: strings.customInvoice,
              subtitle: strings.customInvoiceSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NewInvoiceScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.document_scanner_rounded,
              iconColor: Theme.of(context).colorScheme.tertiary,
              title: strings.scanWithOcr,
              subtitle: strings.scanOcrOptionSubtitle,
              onTap: () => startOcrScan(context),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.smart_toy_rounded,
              iconColor: Theme.of(context).colorScheme.secondary,
              title: strings.createWithAi,
              subtitle: strings.createWithAiSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateWithAiScreen()),
              ),
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

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
