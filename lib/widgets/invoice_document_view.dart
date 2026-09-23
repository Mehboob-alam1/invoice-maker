import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/utils/currency_format.dart';
import '../core/utils/invoice_layout_scale.dart';
import '../l10n/app_strings.dart';
import '../models/invoice.dart';
import '../digital_invoice/premium_invoice_view.dart';
import '../models/invoice_template.dart';
import '../providers/invoice_provider.dart';
import 'templates/blue_white_corporate_invoice_template.dart';
import 'templates/blue_yellow_geometric_invoice_template.dart';
import 'templates/orange_black_receipt_template.dart';
import 'templates/red_modern_invoice_template.dart';

class InvoiceDocumentView extends StatelessWidget {
  const InvoiceDocumentView({
    super.key,
    required this.invoice,
    required this.provider,
    required this.strings,
  });

  final Invoice invoice;
  final InvoiceProvider provider;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    switch (invoice.template) {
      case InvoiceTemplateId.redModern:
        return RedModernInvoiceTemplate(invoice: invoice, provider: provider, strings: strings);
      case InvoiceTemplateId.blueYellow:
        return BlueYellowGeometricInvoiceTemplate(invoice: invoice, provider: provider, strings: strings);
      case InvoiceTemplateId.blueCorporate:
        return BlueWhiteCorporateInvoiceTemplate(invoice: invoice, provider: provider, strings: strings);
      case InvoiceTemplateId.orangeReceipt:
        return OrangeBlackReceiptTemplate(invoice: invoice, provider: provider, strings: strings);
      default:
        break;
    }
    if (InvoiceTemplateInfo.requiresPro(invoice.template)) {
      return PremiumInvoiceView(invoice: invoice, provider: provider);
    }
    if (invoice.template == InvoiceTemplateId.modern) {
      return _ModernTemplate(invoice: invoice, provider: provider, strings: strings);
    }
    if (invoice.template == InvoiceTemplateId.minimal) {
      return _MinimalTemplate(invoice: invoice, provider: provider, strings: strings);
    }
    return _ClassicTemplate(invoice: invoice, provider: provider, strings: strings);
  }
}

class _ClassicTemplate extends StatelessWidget {
  const _ClassicTemplate({required this.invoice, required this.provider, required this.strings});
  final Invoice invoice;
  final InvoiceProvider provider;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = provider.languageCode;
    final layout = InvoiceLayoutScale.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: EdgeInsets.all(layout.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(invoice: invoice, provider: provider, strings: strings, accent: theme.colorScheme.primary),
          const Divider(height: 28),
          _PartyColumns(invoice: invoice, provider: provider, strings: strings),
          const SizedBox(height: 20),
          _ItemsTable(invoice: invoice, strings: strings, headerColor: theme.colorScheme.primary.withValues(alpha: 0.08)),
          const SizedBox(height: 16),
          _TotalsBlock(invoice: invoice, strings: strings, alignEnd: true),
          if (invoice.paymentTerms?.isNotEmpty == true || invoice.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _FooterNotes(invoice: invoice, strings: strings),
          ],
          const SizedBox(height: 8),
          Text(
            DateFormat.yMMMd(locale).format(invoice.date),
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ModernTemplate extends StatelessWidget {
  const _ModernTemplate({required this.invoice, required this.provider, required this.strings});
  final Invoice invoice;
  final InvoiceProvider provider;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: primary,
            padding: EdgeInsets.fromLTRB(
              InvoiceLayoutScale.of(context).horizontalPadding,
              InvoiceLayoutScale.of(context).verticalPadding,
              InvoiceLayoutScale.of(context).horizontalPadding,
              InvoiceLayoutScale.of(context).verticalPadding,
            ),
            child: _HeaderRow(
              invoice: invoice,
              provider: provider,
              strings: strings,
              accent: Colors.white,
              onDark: true,
            ),
          ),
          Container(
            color: theme.cardColor,
            padding: EdgeInsets.all(InvoiceLayoutScale.of(context).horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PartyColumns(invoice: invoice, provider: provider, strings: strings),
                SizedBox(height: InvoiceLayoutScale.of(context).sp(16)),
                _ItemsTable(invoice: invoice, strings: strings, headerColor: primary.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                _TotalsBlock(invoice: invoice, strings: strings, alignEnd: true),
                if (invoice.paymentTerms?.isNotEmpty == true || invoice.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _FooterNotes(invoice: invoice, strings: strings),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalTemplate extends StatelessWidget {
  const _MinimalTemplate({required this.invoice, required this.provider, required this.strings});
  final Invoice invoice;
  final InvoiceProvider provider;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = InvoiceLayoutScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding * 0.5, vertical: layout.verticalPadding * 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InvoiceText(
            strings.invoice.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w400, fontSize: layout.sp(11)),
            maxLines: 1,
          ),
          SizedBox(height: layout.sp(4)),
          InvoiceText(
            invoice.number,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500, fontSize: layout.sp(18)),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          _PartyColumns(invoice: invoice, provider: provider, strings: strings, minimal: true),
          const SizedBox(height: 28),
          ...invoice.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InvoiceText(item.description, style: TextStyle(fontWeight: FontWeight.w600, fontSize: layout.sp(13)), maxLines: 3, overflow: TextOverflow.visible, softWrap: true),
                        InvoiceText('${item.quantity} × ${CurrencyFormat.format(invoice.currency, item.unitCost)}', style: TextStyle(fontSize: layout.sp(11)), maxLines: 2),
                      ],
                    ),
                  ),
                  InvoiceText(CurrencyFormat.format(invoice.currency, item.total), style: TextStyle(fontWeight: FontWeight.w700, fontSize: layout.sp(12)), maxLines: 1),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          _TotalsBlock(invoice: invoice, strings: strings, alignEnd: true, minimal: true),
          if (invoice.paymentTerms?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            InvoiceText('${strings.paymentTerms}: ${invoice.paymentTerms}', style: TextStyle(fontSize: layout.sp(11)), maxLines: 4, overflow: TextOverflow.visible, softWrap: true),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.invoice,
    required this.provider,
    required this.strings,
    required this.accent,
    this.onDark = false,
  });

  final Invoice invoice;
  final InvoiceProvider provider;
  final AppStrings strings;
  final Color accent;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = InvoiceLayoutScale.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: onDark ? Colors.white : theme.textTheme.titleMedium?.color,
      fontWeight: FontWeight.w800,
      fontSize: layout.sp(15),
    );
    final subStyle = theme.textTheme.bodySmall?.copyWith(
      color: onDark ? Colors.white70 : null,
      fontSize: layout.sp(11),
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InvoiceText(strings.invoice, style: titleStyle?.copyWith(color: accent), maxLines: 1),
        InvoiceText(invoice.number, style: TextStyle(fontWeight: FontWeight.w700, fontSize: layout.sp(12)), maxLines: 2, textAlign: TextAlign.end),
        if (invoice.poNumber?.isNotEmpty == true)
          InvoiceText('${strings.poNumber}: ${invoice.poNumber}', style: subStyle, maxLines: 2, textAlign: TextAlign.end),
      ],
    );

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InvoiceText(
          provider.businessName.isEmpty ? strings.defaultBusinessName : provider.businessName,
          style: titleStyle,
          maxLines: 2,
        ),
        if (provider.businessTaxId.isNotEmpty) InvoiceText('${strings.taxId}: ${provider.businessTaxId}', style: subStyle, maxLines: 2),
        if (provider.businessEmail.isNotEmpty) InvoiceText(provider.businessEmail, style: subStyle, maxLines: 2),
        if (provider.businessPhone.isNotEmpty) InvoiceText(provider.businessPhone, style: subStyle, maxLines: 2),
      ],
    );

    if (layout.stackHeader) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [left, SizedBox(height: layout.sp(10)), Align(alignment: Alignment.centerLeft, child: right)],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: layout.sp(8)),
        Flexible(child: right),
      ],
    );
  }
}

class _PartyColumns extends StatelessWidget {
  const _PartyColumns({
    required this.invoice,
    required this.provider,
    required this.strings,
    this.minimal = false,
  });

  final Invoice invoice;
  final InvoiceProvider provider;
  final AppStrings strings;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = InvoiceLayoutScale.of(context);
    final label = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: minimal ? 1.5 : 0.4,
      fontSize: layout.sp(10),
    );

    Widget partyColumn(String title, List<Widget> lines) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InvoiceText(title, style: label, maxLines: 1),
          SizedBox(height: layout.sp(4)),
          ...lines,
        ],
      );
    }

    final from = partyColumn(strings.billFrom, [
      InvoiceText(provider.businessName.isEmpty ? strings.defaultBusinessName : provider.businessName, maxLines: 2, style: TextStyle(fontSize: layout.sp(12))),
      if (provider.businessAddress.isNotEmpty)
        InvoiceText(provider.businessAddress, maxLines: 4, overflow: TextOverflow.visible, softWrap: true, style: TextStyle(fontSize: layout.sp(11))),
    ]);

    final to = partyColumn(strings.billTo, [
      InvoiceText(invoice.client.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: layout.sp(12)), maxLines: 2),
      if (invoice.client.taxId?.isNotEmpty == true) InvoiceText('${strings.taxId}: ${invoice.client.taxId}', maxLines: 2, style: TextStyle(fontSize: layout.sp(11))),
      if (invoice.client.address?.isNotEmpty == true)
        InvoiceText(invoice.client.address!, maxLines: 4, overflow: TextOverflow.visible, softWrap: true, style: TextStyle(fontSize: layout.sp(11))),
      if (invoice.client.email?.isNotEmpty == true) InvoiceText(invoice.client.email!, maxLines: 2, style: TextStyle(fontSize: layout.sp(11))),
      if (invoice.client.phone?.isNotEmpty == true) InvoiceText(invoice.client.phone!, maxLines: 2, style: TextStyle(fontSize: layout.sp(11))),
    ]);

    if (layout.stackParties) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [from, SizedBox(height: layout.sp(14)), to]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: from),
        SizedBox(width: layout.sp(12)),
        Expanded(child: to),
      ],
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.invoice, required this.strings, required this.headerColor});
  final Invoice invoice;
  final AppStrings strings;
  final Color headerColor;

  @override
  Widget build(BuildContext context) {
    final layout = InvoiceLayoutScale.of(context);
    final border = Theme.of(context).dividerColor.withValues(alpha: 0.5);

    if (layout.compact) {
      return Column(
        children: invoice.items.map((item) {
          return Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: layout.sp(8)),
            padding: EdgeInsets.all(layout.sp(10)),
            decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InvoiceText(item.description, style: TextStyle(fontWeight: FontWeight.w600, fontSize: layout.sp(12)), maxLines: 4, overflow: TextOverflow.visible, softWrap: true),
                SizedBox(height: layout.sp(4)),
                Row(
                  children: [
                    Expanded(child: InvoiceText('${item.quantity} × ${CurrencyFormat.format(invoice.currency, item.unitCost)}', style: TextStyle(fontSize: layout.sp(11)), maxLines: 2)),
                    InvoiceText(CurrencyFormat.format(invoice.currency, item.total), style: TextStyle(fontWeight: FontWeight.w700, fontSize: layout.sp(12)), maxLines: 1),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    final table = Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.2),
      },
      border: TableBorder.all(color: border),
      children: [
        TableRow(
          decoration: BoxDecoration(color: headerColor),
          children: [
            _cell(strings.description, header: true, layout: layout),
            _cell(strings.quantity, header: true, layout: layout),
            _cell(strings.unitPrice, header: true, layout: layout),
            _cell(strings.lineTotal, header: true, layout: layout),
          ],
        ),
        ...invoice.items.map(
          (item) => TableRow(
            children: [
              _cell(item.description, layout: layout, maxLines: 3),
              _cell('${item.quantity}', layout: layout),
              _cell(CurrencyFormat.format(invoice.currency, item.unitCost), layout: layout),
              _cell(CurrencyFormat.format(invoice.currency, item.total), layout: layout),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: table,
          ),
        );
      },
    );
  }

  Widget _cell(String text, {bool header = false, required InvoiceLayoutScale layout, int maxLines = 2}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.sp(6), vertical: layout.sp(8)),
      child: InvoiceText(
        text,
        style: TextStyle(
          fontWeight: header ? FontWeight.w700 : FontWeight.w500,
          fontSize: layout.sp(header ? 10 : 11),
        ),
        maxLines: maxLines,
        overflow: TextOverflow.visible,
        softWrap: true,
      ),
    );
  }
}

class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({
    required this.invoice,
    required this.strings,
    required this.alignEnd,
    this.minimal = false,
  });

  final Invoice invoice;
  final AppStrings strings;
  final bool alignEnd;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final layout = InvoiceLayoutScale.of(context);
    final rows = <MapEntry<String, String>>[
      MapEntry(strings.subtotal, CurrencyFormat.format(invoice.currency, invoice.subtotal)),
      if (invoice.taxRate > 0)
        MapEntry('${strings.tax} (${invoice.taxRate.toStringAsFixed(invoice.taxRate % 1 == 0 ? 0 : 1)}%)',
            CurrencyFormat.format(invoice.currency, invoice.taxAmount)),
      MapEntry(strings.grandTotal, CurrencyFormat.format(invoice.currency, invoice.total)),
    ];
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: InvoiceText(
                      e.key,
                      style: TextStyle(
                        fontWeight: e.key == strings.grandTotal ? FontWeight.w800 : FontWeight.w500,
                        fontSize: layout.sp(11),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  InvoiceText(
                    e.value,
                    style: TextStyle(
                      fontWeight: e.key == strings.grandTotal ? FontWeight.w800 : FontWeight.w600,
                      fontSize: layout.sp(11),
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
    if (!alignEnd) return child;
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(width: minimal ? double.infinity : layout.totalsMaxWidth, child: child),
    );
  }
}

class _FooterNotes extends StatelessWidget {
  const _FooterNotes({required this.invoice, required this.strings});
  final Invoice invoice;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final layout = InvoiceLayoutScale.of(context);
    final bodyStyle = TextStyle(fontSize: layout.sp(11));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invoice.paymentTerms?.isNotEmpty == true)
          InvoiceText('${strings.paymentTerms}: ${invoice.paymentTerms}', style: bodyStyle, maxLines: 4, overflow: TextOverflow.visible, softWrap: true),
        if (invoice.dueDate != null)
          InvoiceText('${strings.dueDate}: ${DateFormat.yMMMd().format(invoice.dueDate!)}', style: bodyStyle, maxLines: 1),
        if (invoice.notes?.isNotEmpty == true)
          InvoiceText('${strings.notesOptional}: ${invoice.notes}', style: bodyStyle, maxLines: 6, overflow: TextOverflow.visible, softWrap: true),
      ],
    );
  }
}
