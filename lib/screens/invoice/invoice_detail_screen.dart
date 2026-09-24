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
import '../../widgets/blue_screen.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../../widgets/invoice_document_view.dart';
import 'invoice_preview_edit_screen.dart';

const double _kDocumentMaxWidth = 820;

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
    final blueTheme = buildBlueTheme(Theme.of(context));

    if (invoice == null) {
      return Theme(
        data: blueTheme,
        child: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            return Scaffold(
              appBar: AppBar(title: Text(strings.invoice)),
              body: AppPageShell(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(Icons.description_outlined, size: 34, color: scheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings.invoiceDeleted,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    final status = invoice.displayStatus;
    final paid = invoice.status == InvoiceStatus.paid;
    final templateName = InvoiceTemplateInfo.infoFor(invoice.template);

    return Theme(
      data: blueTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          final muted = theme.extension<AppSemanticColors>()?.textMuted ?? scheme.onSurfaceVariant;

          Widget action({
            String? tooltip,
            required IconData icon,
            required VoidCallback onPressed,
            Color? color,
          }) {
            return IconButton(
              tooltip: tooltip,
              icon: Icon(icon),
              color: color,
              visualDensity: VisualDensity.compact, // keeps 5 actions on small phones
              onPressed: onPressed,
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(invoice.number, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                action(
                  tooltip: strings.editInvoiceForPdf,
                  icon: Icons.edit_outlined,
                  onPressed: () => runWithInterstitial(context, () {
                    Navigator.of(context).push(
                      appPageRoute<void>(
                        InvoicePreviewEditScreen(invoiceId: invoiceId),
                        adScopeKey: 'invoice_preview_$invoiceId',
                      ),
                    );
                  }),
                ),
                action(
                  tooltip: strings.printPdf,
                  icon: Icons.print_outlined,
                  onPressed: () =>
                      runMajorActionAsync(context, () => _exportPdf(context, invoice, share: false)),
                ),
                action(
                  tooltip: strings.sharePdf,
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () =>
                      runMajorActionAsync(context, () => _exportPdf(context, invoice, share: true)),
                ),
                action(
                  icon: Icons.ios_share_rounded,
                  onPressed: () => runMajorActionAsync(context, () => _share(context, invoice)),
                ),
                action(
                  icon: Icons.delete_outline_rounded,
                  color: scheme.error,
                  onPressed: () => runMajorActionAsync(context, () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        final l10n = ctx.l10n;
                        final dialogScheme = Theme.of(ctx).colorScheme;
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          title: Text(
                            l10n.deleteInvoice,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          content: Text(l10n.cannotBeUndone),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: dialogScheme.error,
                                foregroundColor: dialogScheme.onError,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l10n.delete),
                            ),
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
                const SizedBox(width: 4),
              ],
            ),
            body: AppPageShell(
              child: LayoutBuilder(
                builder: (context, c) {
                  final hPad = c.maxWidth < 360 ? 14.0 : 20.0;

                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 20),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: _kDocumentMaxWidth),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        _StatusChip(
                                          status: status,
                                          label: _statusLabel(strings, status),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: scheme.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                strings.t(templateName.labelKey),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.labelMedium?.copyWith(
                                                  color: muted,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    // Paper-style frame around the document.
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: BlueColors.bright.withValues(alpha: 0.12),
                                            blurRadius: 28,
                                            offset: const Offset(0, 12),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: InvoiceDocumentView(
                                          invoice: invoice,
                                          provider: provider,
                                          strings: strings,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status action stays visible while scrolling long invoices.
                      SafeArea(
                        top: false,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: _kDocumentMaxWidth),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 14),
                            child: paid
                                ? SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: () => runWithInterstitial(context, () {
                                  provider.setInvoiceStatus(invoice.id, InvoiceStatus.unpaid);
                                }),
                                icon: const Icon(Icons.undo_rounded),
                                label: Text(strings.markAsUnpaid),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: scheme.primary,
                                  side: BorderSide(
                                    color: scheme.primary.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                                : BlueGradientButton(
                              label: strings.markAsPaid,
                              icon: Icons.check_circle_rounded,
                              onPressed: () => runWithInterstitial(context, () {
                                provider.setInvoiceStatus(invoice.id, InvoiceStatus.paid);
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}