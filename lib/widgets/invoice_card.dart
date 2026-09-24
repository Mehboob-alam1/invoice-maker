import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_format.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../models/invoice.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onTap;

  const InvoiceCard({super.key, required this.invoice, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final strings = context.l10n;
    final dateStr = DateFormat('M/d/yyyy').format(invoice.date);

    late final Color badgeBg;
    late final Color badgeFg;
    late final String label;
    switch (invoice.displayStatus) {
      case InvoiceStatus.paid:
        badgeBg = AppColors.success.withValues(alpha: 0.14);
        badgeFg = AppColors.success;
        label = strings.paid;
        break;
      case InvoiceStatus.overdue:
        badgeBg = AppColors.danger.withValues(alpha: 0.14);
        badgeFg = AppColors.danger;
        label = strings.overdue;
        break;
      case InvoiceStatus.unpaid:
        badgeBg = AppColors.info.withValues(alpha: 0.14);
        badgeFg = AppColors.info;
        label = strings.unpaid;
        break;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: badgeFg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.client.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${invoice.number} · $dateStr',
                              style: theme.textTheme.bodySmall?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormat.format(invoice.currency, invoice.total),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: badgeFg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
