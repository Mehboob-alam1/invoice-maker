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
import '../../ads/ad_placement.dart';
import '../../ads/ad_remote_config.dart';
import '../../ads/ad_service.dart';
import '../../core/remote_config/remote_config_repository.dart';
import '../../services/ai_helpers.dart';
import '../../services/engagement_service.dart';
import '../../services/invoice_create_gate.dart';
import '../../services/invoice_pdf_export.dart';
import '../../services/invoice_send.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../../widgets/invoice_document_view.dart';
import '../../screens/invoice/new_invoice_screen.dart';
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

  Future<void> _recordPayment(BuildContext context, Invoice invoice) async {
    final saved = await showDialog<_RecordedPayment>(
      context: context,
      builder: (ctx) => _RecordPaymentDialog(
        initialAmount: invoice.balanceDue.toStringAsFixed(2),
        initialMethod: invoice.paymentMethod ?? '',
        initialPaidOn: invoice.paidAt ?? DateTime.now(),
      ),
    );
    if (saved == null || !context.mounted || saved.amount <= 0) return;
    final amount = saved.amount;
    final method = saved.method;
    final paidOn = saved.paidOn;
    final provider = context.read<InvoiceProvider>();
    if (amount + 0.009 >= invoice.balanceDue) {
      provider.markPaid(invoice, method: method.isEmpty ? null : method, paidOn: paidOn);
      if (context.mounted) {
        await EngagementService.instance.considerReview(context, reason: 'paid');
      }
    } else {
      provider.recordPayment(
        invoice.id,
        amount: amount,
        method: method.isEmpty ? null : method,
        paidOn: paidOn,
      );
    }
  }

  Future<void> _duplicate(BuildContext context, Invoice invoice) async {
    if (!await ensureInvoiceQuotaOrPrompt(context)) return;
    if (!context.mounted) return;
    final created = await context.read<InvoiceProvider>().duplicateInvoice(invoice);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      appPageRoute(InvoiceDetailScreen(invoiceId: created.id), adScopeKey: 'invoice_${created.id}'),
    );
  }

  void _createAgain(BuildContext context, Invoice invoice) {
    final dueDays = invoice.dueDate == null
        ? 7
        : DateTime(invoice.dueDate!.year, invoice.dueDate!.month, invoice.dueDate!.day)
            .difference(DateTime(invoice.date.year, invoice.date.month, invoice.date.day))
            .inDays
            .clamp(0, 365);
    Navigator.of(context).push(
      appPageRoute(
        NewInvoiceScreen(
          initialClient: invoice.client,
          initialItems: [
            for (final item in invoice.items)
              item.copyWith(id: '${item.id}_copy'),
          ],
          currency: invoice.currency,
          initialTaxRate: invoice.taxRate,
          initialNotes: invoice.notes,
          initialDueDays: dueDays,
          initialTaxInclusive: invoice.taxInclusive,
          initialTemplateId: invoice.templateId,
          documentKind: invoice.kind,
        ),
      ),
    );
  }

  Future<void> _writeReminder(BuildContext context, Invoice invoice) async {
    final text = await AiHelpers.politeReminder(context, invoice);
    if (text == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.writeReminder),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.close)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              SharePlus.instance.share(ShareParams(text: text));
            },
            child: Text(ctx.l10n.send),
          ),
        ],
      ),
    );
  }

  Future<void> _removeWatermark(BuildContext context, Invoice invoice) async {
    final earned = await AdService.instance.showRewarded(
      adUnitId: AdRemoteConfig.instance.rewardedAdUnitId,
      placement: AdPlacement.rewardedWatermark,
    );
    if (!earned || !context.mounted) return;
    context.read<InvoiceProvider>().removeWatermark(invoice.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.read(context).watermarkRemoved)),
    );
  }

  Future<void> _convert(BuildContext context, Invoice invoice) async {
    if (!await ensureInvoiceQuotaOrPrompt(context)) return;
    if (!context.mounted) return;
    final created = await context.read<InvoiceProvider>().convertEstimate(invoice.id);
    if (created == null || !context.mounted) return;
    Navigator.of(context).pushReplacement(
      appPageRoute(InvoiceDetailScreen(invoiceId: created.id), adScopeKey: 'invoice_${created.id}'),
    );
  }

  static String _estimateLabel(AppStrings strings, EstimateStatus status) {
    switch (status) {
      case EstimateStatus.draft:
        return strings.estimateDraft;
      case EstimateStatus.sent:
        return strings.estimateSent;
      case EstimateStatus.accepted:
        return strings.estimateAccepted;
      case EstimateStatus.declined:
        return strings.estimateDeclined;
    }
  }

  static String _statusLabel(AppStrings strings, InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return strings.paid;
      case InvoiceStatus.overdue:
        return strings.overdue;
      case InvoiceStatus.partiallyPaid:
        return strings.partiallyPaid;
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
    final fullyPaid = status == InvoiceStatus.paid;
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
                  onPressed: () => _exportPdf(context, invoice, share: false),
                ),
                action(
                  tooltip: strings.sharePdf,
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () => _exportPdf(context, invoice, share: true),
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
                                          label: invoice.isEstimate
                                              ? _estimateLabel(strings, invoice.estimateStatus)
                                              : _statusLabel(strings, status),
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
                                    if (invoice.isEstimate) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          for (final value in EstimateStatus.values)
                                            ChoiceChip(
                                              label: Text(_estimateLabel(strings, value)),
                                              selected: invoice.estimateStatus == value,
                                              onSelected: (_) => provider.updateInvoice(
                                                invoice.copyWith(estimateStatus: value),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ActionChip(
                                          avatar: const Icon(Icons.chat_outlined, size: 18),
                                          label: Text(strings.sendWhatsApp),
                                          onPressed: () => InvoiceSend.sharePdfWithMessage(context, invoice),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.email_outlined, size: 18),
                                          label: Text(strings.sendEmail),
                                          onPressed: () => InvoiceSend.sharePdfWithMessage(context, invoice),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.sms_outlined, size: 18),
                                          label: Text(strings.sendSms),
                                          onPressed: () => InvoiceSend.sms(context, invoice),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.image_outlined, size: 18),
                                          label: Text(strings.shareImage),
                                          onPressed: () => InvoiceSend.shareImage(context, invoice),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.copy_rounded, size: 18),
                                          label: Text(strings.duplicateInvoice),
                                          onPressed: () => _duplicate(context, invoice),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.replay_rounded, size: 18),
                                          label: Text(strings.createAgain),
                                          onPressed: () => _createAgain(context, invoice),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
                                          label: Text(strings.writeReminder),
                                          onPressed: () => _writeReminder(context, invoice),
                                        ),
                                        if (!provider.isPro &&
                                            RemoteConfigRepository.instance.watermarkFooterFree &&
                                            !provider.watermarkRemovedIds.contains(invoice.id))
                                          ActionChip(
                                            avatar: const Icon(Icons.visibility_off_outlined, size: 18),
                                            label: Text(strings.removeWatermark),
                                            onPressed: () => _removeWatermark(context, invoice),
                                          ),
                                      ],
                                    ),
                                    if (invoice.amountPaid > 0.009) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        '${strings.amountPaid}: ${CurrencyFormat.format(invoice.currency, invoice.amountPaid)}',
                                      ),
                                      Text(
                                        '${strings.balanceDue}: ${CurrencyFormat.format(invoice.currency, invoice.balanceDue)}',
                                      ),
                                    ],
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
                            child: invoice.isEstimate
                                ? BlueGradientButton(
                              label: strings.convertToInvoice,
                              icon: Icons.receipt_long_rounded,
                              onPressed: () => _convert(context, invoice),
                            )
                                : fullyPaid
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
                              label: strings.recordPayment,
                              icon: Icons.check_circle_rounded,
                              onPressed: () => _recordPayment(context, invoice),
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
      case InvoiceStatus.partiallyPaid:
        color = AppColors.info;
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

class _RecordedPayment {
  const _RecordedPayment({required this.amount, required this.method, required this.paidOn});

  final double amount;
  final String method;
  final DateTime paidOn;
}

/// Owns the payment fields for the whole dialog lifetime, including the
/// close animation. Disposing the controllers as soon as [showDialog] returns
/// lets the exiting text fields attach to a dead controller.
class _RecordPaymentDialog extends StatefulWidget {
  const _RecordPaymentDialog({
    required this.initialAmount,
    required this.initialMethod,
    required this.initialPaidOn,
  });

  final String initialAmount;
  final String initialMethod;
  final DateTime initialPaidOn;

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  late final TextEditingController _amount = TextEditingController(text: widget.initialAmount);
  late final TextEditingController _method = TextEditingController(text: widget.initialMethod);
  late DateTime _paidOn = widget.initialPaidOn;

  @override
  void dispose() {
    _amount.dispose();
    _method.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    Navigator.pop(
      context,
      _RecordedPayment(amount: amount, method: _method.text.trim(), paidOn: _paidOn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.recordPayment),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.paymentAmount),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _method,
              decoration: InputDecoration(labelText: l10n.paymentMethod),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paidOn,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _paidOn = picked);
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(DateFormat.yMMMd().format(_paidOn)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}