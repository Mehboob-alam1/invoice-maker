import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  Future<void> _share(BuildContext context, Invoice invoice) async {
    final provider = context.read<InvoiceProvider>();
    final strings = AppStrings.read(context);
    final buffer = StringBuffer()
      ..writeln(provider.businessName)
      ..writeln(strings.invoiceShare(invoice.number))
      ..writeln('${strings.date}: ${DateFormat.yMMMd(provider.languageCode).format(invoice.date)}')
      ..writeln(strings.clientShare(invoice.client.name))
      ..writeln();
    for (final item in invoice.items) {
      buffer.writeln('${item.description}  ${item.quantity} × ${item.unitCost.toStringAsFixed(2)} = ${item.total.toStringAsFixed(2)}');
      if (item.notes?.isNotEmpty == true) buffer.writeln('  ${item.notes}');
    }
    buffer
      ..writeln()
      ..writeln(strings.totalShare('${invoice.currency} ${invoice.total.toStringAsFixed(2)}'))
      ..writeln(strings.statusShare(_statusLabel(strings, invoice.displayStatus)));
    await SharePlus.instance.share(ShareParams(text: buffer.toString(), subject: invoice.number));
  }

  static String _statusLabel(AppStrings strings, InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return strings.paid;
      case InvoiceStatus.overdue:
        return strings.overdue;
      case InvoiceStatus.unpaid:
        return strings.unpaid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final strings = context.l10n;
    final invoice = provider.invoiceById(invoiceId);
    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.invoice)),
        body: Center(child: Text(strings.invoiceDeleted)),
      );
    }

    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final status = invoice.displayStatus;
    final paid = invoice.status == InvoiceStatus.paid;

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.number),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _share(context, invoice),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  final l10n = ctx.l10n;
                  return AlertDialog(
                    title: Text(l10n.deleteInvoice),
                    content: Text(l10n.cannotBeUndone),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
                    ],
                  );
                },
              );
              if (ok == true && context.mounted) {
                provider.deleteInvoice(invoice.id);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
              title: Text(invoice.client.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                [
                  invoice.client.email,
                  invoice.client.phone,
                ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                style: TextStyle(color: muted),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusChip(status: status, label: _statusLabel(strings, status)),
              const Spacer(),
              Text(DateFormat.yMMMd(provider.languageCode).format(invoice.date), style: TextStyle(color: muted)),
            ],
          ),
          const SizedBox(height: 16),
          Text(strings.items, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...invoice.items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  [
                    '${item.quantity} × ${item.unitCost.toStringAsFixed(2)}',
                    if (item.notes?.isNotEmpty == true) item.notes!,
                  ].join('\n'),
                ),
                isThreeLine: item.notes?.isNotEmpty == true,
                trailing: Text('${invoice.currency} ${item.total.toStringAsFixed(2)}'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Text(strings.total, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const Spacer(),
                  Text(
                    '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.setInvoiceStatus(
              invoice.id,
              paid ? InvoiceStatus.unpaid : InvoiceStatus.paid,
            ),
            icon: Icon(paid ? Icons.undo_rounded : Icons.check_circle_rounded),
            label: Text(paid ? strings.markAsUnpaid : strings.markAsPaid),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final InvoiceStatus status;
  final String label;
  const _StatusChip({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    switch (status) {
      case InvoiceStatus.paid:
        color = AppColors.success;
        break;
      case InvoiceStatus.overdue:
        color = AppColors.danger;
        break;
      case InvoiceStatus.unpaid:
        color = AppColors.info;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
