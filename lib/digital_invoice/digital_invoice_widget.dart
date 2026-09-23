import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/utils/invoice_layout_scale.dart';
import 'digital_invoice_model.dart';
import 'invoice_gradient_theme.dart';

/// Full international-style invoice document (gradient header, Poppins/Inter).
class DigitalInvoiceWidget extends StatelessWidget {
  const DigitalInvoiceWidget({
    super.key,
    required this.invoice,
    required this.theme,
  });

  final DigitalInvoice invoice;
  final InvoiceGradientTheme theme;

  NumberFormat get _money => NumberFormat.currency(
        locale: invoice.locale,
        symbol: invoice.currencySymbol,
        decimalDigits: 2,
      );

  @override
  Widget build(BuildContext context) {
    final layout = InvoiceLayoutScale.of(context);
    final padH = layout.horizontalPadding;
    final padV = layout.verticalPadding;

    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GradientHeader(invoice: invoice, theme: theme, layout: layout),
          Padding(
            padding: EdgeInsets.fromLTRB(padH, padV, padH, padV + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PartiesRow(invoice: invoice, theme: theme, layout: layout),
                SizedBox(height: layout.sp(20)),
                _ItemsTable(invoice: invoice, theme: theme, money: _money, layout: layout),
                SizedBox(height: layout.sp(16)),
                _TotalsSection(invoice: invoice, theme: theme, money: _money, layout: layout),
                if (invoice.bankDetails != null && !invoice.bankDetails!.isEmpty) ...[
                  SizedBox(height: layout.sp(16)),
                  _BankDetailsCard(details: invoice.bankDetails!, theme: theme),
                ],
                if (invoice.notes.isNotEmpty) ...[
                  SizedBox(height: layout.sp(16)),
                  _NoteBlock(title: 'Notes', body: invoice.notes),
                ],
                if (invoice.termsAndConditions.isNotEmpty) ...[
                  SizedBox(height: layout.sp(10)),
                  _NoteBlock(title: 'Terms & Conditions', body: invoice.termsAndConditions),
                ],
                SizedBox(height: layout.sp(18)),
                _FooterSignature(layout: layout),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.invoice, required this.theme, required this.layout});
  final DigitalInvoice invoice;
  final InvoiceGradientTheme theme;
  final InvoiceLayoutScale layout;

  @override
  Widget build(BuildContext context) {
    final onGrad = theme.onGradient;
    final dateFmt = DateFormat('dd MMM yyyy', invoice.locale);
    final pad = layout.horizontalPadding;
    final titleStyle = Theme.of(context).textTheme.displaySmall?.copyWith(color: onGrad);
    final metaStyle = TextStyle(color: onGrad.withValues(alpha: 0.85), fontSize: layout.sp(11));

    final invoiceTitle = Text(
      'INVOICE',
      style: TextStyle(
        color: onGrad,
        fontWeight: FontWeight.w800,
        fontSize: layout.sp(18),
        letterSpacing: 1.2,
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(pad, pad + 4, pad, pad),
      decoration: BoxDecoration(gradient: theme.headerGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (layout.stackHeader) ...[
            InvoiceText(
              invoice.seller.name,
              style: titleStyle,
              maxLines: 3,
            ),
            SizedBox(height: layout.sp(8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                invoiceTitle,
                Flexible(child: Align(alignment: Alignment.centerRight, child: _StatusBadge(status: invoice.status))),
              ],
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InvoiceText(invoice.seller.name, style: titleStyle, maxLines: 2),
                      SizedBox(height: layout.sp(4)),
                      if (invoice.seller.fullAddress.isNotEmpty)
                        InvoiceText(invoice.seller.fullAddress, style: metaStyle, maxLines: 4, overflow: TextOverflow.visible),
                      if (invoice.seller.taxId.isNotEmpty)
                        InvoiceText('${invoice.seller.taxIdLabel}: ${invoice.seller.taxId}', style: metaStyle, maxLines: 2),
                    ],
                  ),
                ),
                SizedBox(width: layout.sp(8)),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      invoiceTitle,
                      SizedBox(height: layout.sp(6)),
                      _StatusBadge(status: invoice.status),
                    ],
                  ),
                ),
              ],
            ),
          SizedBox(height: layout.sp(16)),
          Wrap(
            spacing: layout.sp(16),
            runSpacing: layout.sp(8),
            children: [
              _HeaderStat(label: 'Invoice No.', value: invoice.invoiceNumber, color: onGrad, layout: layout),
              _HeaderStat(label: 'Issue Date', value: dateFmt.format(invoice.issueDate), color: onGrad, layout: layout),
              _HeaderStat(label: 'Due Date', value: dateFmt.format(invoice.dueDate), color: onGrad, layout: layout),
              if (invoice.purchaseOrderNumber.isNotEmpty)
                _HeaderStat(label: 'PO No.', value: invoice.purchaseOrderNumber, color: onGrad, layout: layout),
              _HeaderStat(label: 'Currency', value: invoice.currencyCode, color: onGrad, layout: layout),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value, required this.color, required this.layout});
  final String label;
  final String value;
  final Color color;
  final InvoiceLayoutScale layout;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: layout.compact ? layout.width * 0.44 : 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InvoiceText(
            label.toUpperCase(),
            style: TextStyle(
              color: color.withValues(alpha: 0.65),
              fontSize: layout.sp(9),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
            maxLines: 1,
          ),
          SizedBox(height: 2),
          InvoiceText(
            value,
            style: TextStyle(color: color, fontSize: layout.sp(12), fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final DigitalPaymentStatus status;

  Color get _bg {
    switch (status) {
      case DigitalPaymentStatus.paid:
        return const Color(0xFF16A34A);
      case DigitalPaymentStatus.overdue:
        return const Color(0xFFDC2626);
      case DigitalPaymentStatus.cancelled:
        return const Color(0xFF6B7280);
      case DigitalPaymentStatus.draft:
        return const Color(0xFF9CA3AF);
      case DigitalPaymentStatus.sent:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = InvoiceLayoutScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: layout.sp(10), vertical: layout.sp(4)),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
      child: InvoiceText(
        status.label.toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: layout.sp(9), fontWeight: FontWeight.w700, letterSpacing: 0.4),
        maxLines: 1,
      ),
    );
  }
}

class _PartiesRow extends StatelessWidget {
  const _PartiesRow({required this.invoice, required this.theme, required this.layout});
  final DigitalInvoice invoice;
  final InvoiceGradientTheme theme;
  final InvoiceLayoutScale layout;

  @override
  Widget build(BuildContext context) {
    return _PartyCard(title: 'Bill To', party: invoice.buyer, theme: theme, layout: layout);
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.title, required this.party, required this.theme, required this.layout});
  final String title;
  final DigitalParty party;
  final InvoiceGradientTheme theme;
  final InvoiceLayoutScale layout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InvoiceText(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: theme.accent),
          maxLines: 1,
        ),
        SizedBox(height: layout.sp(4)),
        InvoiceText(party.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 2),
        if (party.fullAddress.isNotEmpty)
          InvoiceText(party.fullAddress, style: Theme.of(context).textTheme.bodyMedium, maxLines: 5, overflow: TextOverflow.visible, softWrap: true),
        if (party.email.isNotEmpty)
          InvoiceText(party.email, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2),
        if (party.phone.isNotEmpty)
          InvoiceText(party.phone, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2),
        if (party.taxId.isNotEmpty)
          InvoiceText('${party.taxIdLabel}: ${party.taxId}', style: Theme.of(context).textTheme.bodyMedium, maxLines: 2),
      ],
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({
    required this.invoice,
    required this.theme,
    required this.money,
    required this.layout,
  });
  final DigitalInvoice invoice;
  final InvoiceGradientTheme theme;
  final NumberFormat money;
  final InvoiceLayoutScale layout;

  @override
  Widget build(BuildContext context) {
    if (layout.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: invoice.items.map((item) => _CompactItemCard(item: item, money: money, theme: theme, layout: layout)).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: layout.sp(10), vertical: layout.sp(8)),
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _cell('Description', flex: 5, header: true, context: context),
                      _cell('Qty', flex: 1, header: true, context: context, align: TextAlign.center),
                      _cell('Unit', flex: 2, header: true, context: context, align: TextAlign.right),
                      _cell('Tax', flex: 1, header: true, context: context, align: TextAlign.center),
                      _cell('Amount', flex: 2, header: true, context: context, align: TextAlign.right),
                    ],
                  ),
                ),
                ...invoice.items.map(
                  (item) => Container(
                    padding: EdgeInsets.symmetric(horizontal: layout.sp(10), vertical: layout.sp(10)),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF0F5)))),
                    child: Row(
                      children: [
                        _cell(item.description, flex: 5, context: context, maxLines: 3),
                        _cell(
                          item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : item.quantity.toString(),
                          flex: 1,
                          context: context,
                          align: TextAlign.center,
                        ),
                        _cell(money.format(item.unitPrice), flex: 2, context: context, align: TextAlign.right),
                        _cell(
                          invoice.invoiceTaxRatePercent > 0 ? '—' : '${item.taxRatePercent.toStringAsFixed(0)}%',
                          flex: 1,
                          context: context,
                          align: TextAlign.center,
                        ),
                        _cell(money.format(item.netAmount), flex: 2, context: context, align: TextAlign.right),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cell(
    String text, {
    required int flex,
    bool header = false,
    TextAlign align = TextAlign.left,
    required BuildContext context,
    int maxLines = 2,
  }) {
    final style = header ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.bodyLarge;
    return Expanded(
      flex: flex,
      child: InvoiceText(text, textAlign: align, style: style, maxLines: maxLines, overflow: TextOverflow.visible, softWrap: true),
    );
  }
}

class _CompactItemCard extends StatelessWidget {
  const _CompactItemCard({required this.item, required this.money, required this.theme, required this.layout});
  final DigitalLineItem item;
  final NumberFormat money;
  final InvoiceGradientTheme theme;
  final InvoiceLayoutScale layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: layout.sp(8)),
      padding: EdgeInsets.all(layout.sp(10)),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEF0F5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InvoiceText(item.description, style: Theme.of(context).textTheme.titleMedium, maxLines: 4, overflow: TextOverflow.visible, softWrap: true),
          SizedBox(height: layout.sp(6)),
          Row(
            children: [
              Expanded(child: InvoiceText('Qty ${item.quantity}', style: Theme.of(context).textTheme.bodyMedium)),
              InvoiceText(money.format(item.netAmount), style: Theme.of(context).textTheme.titleMedium, maxLines: 1),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.invoice, required this.theme, required this.money, required this.layout});
  final DigitalInvoice invoice;
  final InvoiceGradientTheme theme;
  final NumberFormat money;
  final InvoiceLayoutScale layout;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.totalsMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(context, 'Subtotal', money.format(invoice.subtotal), layout),
            if (invoice.globalDiscountPercent > 0)
              _row(context, 'Discount (${invoice.globalDiscountPercent.toStringAsFixed(0)}%)', '- ${money.format(invoice.globalDiscountAmount)}', layout),
            for (final tb in invoice.taxBreakdown)
              if (tb.ratePercent > 0) _row(context, 'Tax ${tb.ratePercent.toStringAsFixed(0)}%', money.format(tb.taxAmount), layout),
            if (invoice.shippingCost > 0) _row(context, 'Shipping', money.format(invoice.shippingCost), layout),
            Divider(height: layout.sp(16)),
            Container(
              padding: EdgeInsets.symmetric(vertical: layout.sp(8), horizontal: layout.sp(12)),
              decoration: BoxDecoration(gradient: theme.headerGradient, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(
                    child: InvoiceText(
                      'Total Due',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: layout.sp(12)),
                      maxLines: 1,
                    ),
                  ),
                  Flexible(
                    child: InvoiceText(
                      money.format(invoice.grandTotal),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: layout.sp(14)),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, InvoiceLayoutScale layout) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: layout.sp(3)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: InvoiceText(label, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.visible, softWrap: true)),
          SizedBox(width: layout.sp(8)),
          Flexible(
            child: InvoiceText(value, textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodyLarge, maxLines: 2),
          ),
        ],
      ),
    );
  }
}

class _BankDetailsCard extends StatelessWidget {
  const _BankDetailsCard({required this.details, required this.theme});
  final DigitalBankDetails details;
  final InvoiceGradientTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InvoiceText('Payment Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: theme.accent), maxLines: 1),
          const SizedBox(height: 8),
          if (details.bankName.isNotEmpty) InvoiceText('Bank: ${details.bankName}', maxLines: 2, overflow: TextOverflow.visible, softWrap: true),
          if (details.accountNumber.isNotEmpty) InvoiceText('Account: ${details.accountNumber}', maxLines: 2),
          if (details.iban.isNotEmpty) InvoiceText('IBAN: ${details.iban}', maxLines: 2, overflow: TextOverflow.visible, softWrap: true),
          if (details.swiftBic.isNotEmpty) InvoiceText('SWIFT: ${details.swiftBic}', maxLines: 1),
        ],
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InvoiceText(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1),
        const SizedBox(height: 4),
        InvoiceText(body, style: Theme.of(context).textTheme.bodyMedium, maxLines: 20, overflow: TextOverflow.visible, softWrap: true),
      ],
    );
  }
}

class _FooterSignature extends StatelessWidget {
  const _FooterSignature({required this.layout});
  final InvoiceLayoutScale layout;

  @override
  Widget build(BuildContext context) {
    if (layout.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InvoiceText(
            'Thank you for your business.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            maxLines: 2,
          ),
          SizedBox(height: layout.sp(12)),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(width: 120, height: 1, color: const Color(0xFFCBD2E0)),
                const SizedBox(height: 4),
                InvoiceText('Authorized Signature', style: Theme.of(context).textTheme.labelSmall, maxLines: 1),
              ],
            ),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: InvoiceText(
            'Thank you for your business.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            maxLines: 2,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(width: 120, height: 1, color: const Color(0xFFCBD2E0)),
            const SizedBox(height: 4),
            InvoiceText('Authorized Signature', style: Theme.of(context).textTheme.labelSmall, maxLines: 1),
          ],
        ),
      ],
    );
  }
}
