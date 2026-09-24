import 'package:flutter/material.dart';

import '../../navigation/app_page_route.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_format.dart';
import '../../l10n/app_strings.dart';
import '../../models/invoice.dart';
import '../../models/invoice_template.dart';
import '../../providers/invoice_provider.dart';
import '../../ads/ad_action.dart';
import '../../services/invoice_pdf_export.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../../widgets/invoice_document_view.dart';
import 'invoice_preview_edit_screen.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  Future<void> _exportPdf(BuildContext context, Invoice invoice, {required bool share}) async {
    await InvoicePdfExport.export(context, invoice, share: share);
  }

  Future<void> _share(BuildContext context, Invoice invoice) async {
    final provider = context.read<InvoiceProvider>();
    final strings = AppStrings.read(context);
    final buffer = StringBuffer()
      ..writeln(provider.businessName)
      ..writeln(strings.invoiceShare(invoice.number))
      ..writeln('${strings.issueDate}: ${DateFormat.yMMMd(provider.languageCode).format(invoice.date)}');
    if (invoice.dueDate != null) {
      buffer.writeln('${strings.dueDate}: ${DateFormat.yMMMd(provider.languageCode).format(invoice.dueDate!)}');
    }
    if (invoice.poNumber?.isNotEmpty == true) buffer.writeln('${strings.poNumber}: ${invoice.poNumber}');
    buffer.writeln(strings.clientShare(invoice.client.name));
    if (invoice.client.taxId?.isNotEmpty == true) buffer.writeln('${strings.taxId}: ${invoice.client.taxId}');
    buffer.writeln();
    for (final item in invoice.items) {
      buffer.writeln(
        '${item.description}  ${item.quantity} × ${CurrencyFormat.format(invoice.currency, item.unitCost)} = ${CurrencyFormat.format(invoice.currency, item.total)}',
      );
      if (item.notes?.isNotEmpty == true) buffer.writeln('  ${item.notes}');
    }
    buffer
      ..writeln()
      ..writeln('${strings.subtotal}: ${CurrencyFormat.format(invoice.currency, invoice.subtotal)}');
    if (invoice.taxRate > 0) {
      buffer.writeln('${strings.tax} (${invoice.taxRate}%): ${CurrencyFormat.format(invoice.currency, invoice.taxAmount)}');
    }
    buffer
      ..writeln(strings.totalShare(CurrencyFormat.format(invoice.currency, invoice.total)))
      ..writeln(strings.statusShare(_statusLabel(strings, invoice.displayStatus)));
    if (invoice.paymentTerms?.isNotEmpty == true) {
      buffer.writeln('${strings.paymentTerms}: ${invoice.paymentTerms}');
    }
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
    final templateName = InvoiceTemplateInfo.infoFor(invoice.template);

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.number),
        actions: [
          IconButton(
            tooltip: strings.editInvoiceForPdf,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => runWithInterstitial(context, () {
              Navigator.of(context).push(
                appPageRoute<void>(
                  InvoicePreviewEditScreen(invoiceId: invoiceId),
                  adScopeKey: 'invoice_preview_$invoiceId',
                ),
              );
            }),
          ),
          IconButton(
            tooltip: strings.printPdf,
            icon: const Icon(Icons.print_outlined),
            onPressed: () => runMajorActionAsync(context, () => _exportPdf(context, invoice, share: false)),
          ),
          IconButton(
            tooltip: strings.sharePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => runMajorActionAsync(context, () => _exportPdf(context, invoice, share: true)),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => runMajorActionAsync(context, () => _share(context, invoice)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => runMajorActionAsync(context, () async {
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
            }),
          ),
        ],
      ),
      body: AppPageShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
          Row(
            children: [
              _StatusChip(status: status, label: _statusLabel(strings, status)),
              const Spacer(),
              Text(strings.t(templateName.labelKey), style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: InvoiceDocumentView(invoice: invoice, provider: provider, strings: strings),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => runWithInterstitial(context, () {
              provider.setInvoiceStatus(
                invoice.id,
                paid ? InvoiceStatus.unpaid : InvoiceStatus.paid,
              );
            }),
            icon: Icon(paid ? Icons.undo_rounded : Icons.check_circle_rounded),
            label: Text(paid ? strings.markAsUnpaid : strings.markAsPaid),
          ),
        ],
        ),
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
