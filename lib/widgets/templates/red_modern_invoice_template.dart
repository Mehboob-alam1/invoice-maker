import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_format.dart';
import '../../core/utils/invoice_layout_scale.dart';
import '../../l10n/app_strings.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';

const Color kRedModernMaroon = Color(0xFF7B1E3A);
const Color kRedModernBlack = Color(0xFF1B1B1B);
const Color kRedModernCream = Color(0xFFF6F2EC);
const Color kRedModernMuted = Color(0xFF6B6B6B);

/// Canva-style "Red Modern Company Invoice" — cream paper, maroon corner fold, bold INVOICE title.
class RedModernInvoiceTemplate extends StatelessWidget {
  const RedModernInvoiceTemplate({
    super.key,
    required this.invoice,
    required this.provider,
    required this.strings,
  });

  final Invoice invoice;
  final InvoiceProvider provider;
  final AppStrings strings;

  String get _companyName {
    final name = provider.businessName.trim();
    return name.isEmpty ? strings.defaultBusinessName : name.toUpperCase();
  }

  String get _fromName {
    final name = provider.businessName.trim();
    return name.isEmpty ? strings.defaultBusinessName : name;
  }

  @override
  Widget build(BuildContext context) {
    final layout = InvoiceLayoutScale.of(context);
    final locale = provider.languageCode;
    final dateStr = DateFormat.yMMMMd(locale).format(invoice.date);
    final pad = layout.horizontalPadding * 1.4;

    return Material(
      color: kRedModernCream,
      elevation: 4,
      borderRadius: BorderRadius.circular(2),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderWithCornerFold(
            companyName: _companyName,
            invoiceNo: invoice.number,
            headerHeight: layout.sp(200).clamp(160, 230),
            scale: layout.scale,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, layout.sp(16), pad, layout.sp(22)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                layout.stackParties
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PartyBlock(
                            label: '${strings.billTo}:',
                            name: invoice.client.name,
                            phone: invoice.client.phone ?? '',
                            address: invoice.client.address ?? '',
                            align: CrossAxisAlignment.start,
                            textAlign: TextAlign.left,
                            scale: layout.scale,
                          ),
                          SizedBox(height: layout.sp(14)),
                          _PartyBlock(
                            label: '${strings.billFrom}:',
                            name: _fromName,
                            phone: provider.businessPhone,
                            address: provider.businessAddress.replaceAll('\n', ', '),
                            align: CrossAxisAlignment.start,
                            textAlign: TextAlign.left,
                            scale: layout.scale,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PartyBlock(
                              label: '${strings.billTo}:',
                              name: invoice.client.name,
                              phone: invoice.client.phone ?? '',
                              address: invoice.client.address ?? '',
                              align: CrossAxisAlignment.start,
                              textAlign: TextAlign.left,
                              scale: layout.scale,
                            ),
                          ),
                          Expanded(
                            child: _PartyBlock(
                              label: '${strings.billFrom}:',
                              name: _fromName,
                              phone: provider.businessPhone,
                              address: provider.businessAddress.replaceAll('\n', ', '),
                              align: CrossAxisAlignment.end,
                              textAlign: TextAlign.right,
                              scale: layout.scale,
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: layout.sp(14)),
                Text(
                  '${strings.date}: $dateStr',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: layout.sp(14),
                    color: kRedModernBlack,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: layout.sp(16)),
                _ItemsTable(invoice: invoice, strings: strings, scale: layout.scale),
                SizedBox(height: layout.sp(22)),
                _PaymentAndThanks(
                  strings: strings,
                  email: provider.businessEmail,
                  phone: provider.businessPhone,
                  taxId: provider.businessTaxId,
                  paymentTerms: invoice.paymentTerms,
                  scale: layout.scale,
                ),
                if (invoice.notes?.isNotEmpty == true) ...[
                  SizedBox(height: layout.sp(12)),
                  Text(
                    invoice.notes!,
                    style: GoogleFonts.poppins(fontSize: layout.sp(11), color: kRedModernMuted),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 12, color: kRedModernBlack),
        ],
      ),
    );
  }
}

class _HeaderWithCornerFold extends StatelessWidget {
  const _HeaderWithCornerFold({
    required this.companyName,
    required this.invoiceNo,
    required this.headerHeight,
    required this.scale,
  });

  final String companyName;
  final String invoiceNo;
  final double headerHeight;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CornerFoldPainter())),
          Padding(
            padding: EdgeInsets.fromLTRB(24 * scale, 22 * scale, 24 * scale, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: kRedModernBlack,
                  ),
                ),
                SizedBox(height: 18 * scale),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        stringsInvoiceTitle(context),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 36 * scale,
                          fontWeight: FontWeight.w800,
                          color: kRedModernMaroon,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 6 * scale, left: 8),
                      child: Text(
                        'NO: $invoiceNo',
                        style: GoogleFonts.poppins(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w700,
                          color: kRedModernBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String stringsInvoiceTitle(BuildContext context) {
    return AppStrings.read(context).invoice.toUpperCase();
  }
}

class _CornerFoldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final maroon = Path()
      ..moveTo(w * 0.42, 0)
      ..lineTo(w, 0)
      ..lineTo(w, size.height * 0.62)
      ..close();
    canvas.drawPath(maroon, Paint()..color = kRedModernMaroon);

    final black = Path()
      ..moveTo(w * 0.62, size.height * 0.10)
      ..lineTo(w, size.height * 0.10)
      ..lineTo(w, size.height * 0.62)
      ..close();
    canvas.drawPath(black, Paint()..color = kRedModernBlack);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PartyBlock extends StatelessWidget {
  const _PartyBlock({
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    required this.align,
    required this.textAlign,
    required this.scale,
  });

  final String label;
  final String name;
  final String phone;
  final String address;
  final CrossAxisAlignment align;
  final TextAlign textAlign;
  final double scale;

  @override
  Widget build(BuildContext context) {
    TextStyle muted(double size) => GoogleFonts.poppins(fontSize: size, color: kRedModernMuted);
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: GoogleFonts.poppins(fontSize: 14 * scale, fontWeight: FontWeight.w700, color: kRedModernBlack),
        ),
        SizedBox(height: 5 * scale),
        Text(name, textAlign: textAlign, style: muted(12 * scale)),
        if (phone.isNotEmpty) Text(phone, textAlign: textAlign, style: muted(12 * scale)),
        if (address.isNotEmpty)
          Text(address, textAlign: textAlign, maxLines: 3, overflow: TextOverflow.ellipsis, style: muted(12 * scale)),
      ],
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.invoice, required this.strings, required this.scale});

  final Invoice invoice;
  final AppStrings strings;
  final double scale;

  String _money(double v) => CurrencyFormat.format(invoice.currency, v);

  @override
  Widget build(BuildContext context) {
    final totalLabel = invoice.taxRate > 0 ? strings.grandTotal : strings.subtotal;
    final totalValue = invoice.taxRate > 0 ? invoice.total : invoice.subtotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: kRedModernMaroon,
          padding: EdgeInsets.symmetric(vertical: 9 * scale, horizontal: 12 * scale),
          child: Row(
            children: [
              _headerCell(strings.description, flex: 4, align: TextAlign.left),
              _headerCell(strings.quantity, flex: 1, align: TextAlign.center),
              _headerCell(strings.unitPrice, flex: 2, align: TextAlign.center),
              _headerCell(strings.lineTotal, flex: 2, align: TextAlign.right),
            ],
          ),
        ),
        ...invoice.items.map(
          (item) => Container(
            padding: EdgeInsets.symmetric(vertical: 9 * scale, horizontal: 12 * scale),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kRedModernMaroon, width: 0.8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cell(item.description, flex: 4, align: TextAlign.left),
                _cell('${item.quantity}', flex: 1, align: TextAlign.center),
                _cell(_money(item.unitCost), flex: 2, align: TextAlign.center),
                _cell(_money(item.total), flex: 2, align: TextAlign.right),
              ],
            ),
          ),
        ),
        if (invoice.taxRate > 0)
          Padding(
            padding: EdgeInsets.only(top: 6 * scale, right: 12 * scale),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${strings.subtotal}: ${_money(invoice.subtotal)} · ${strings.tax} (${invoice.taxRate}%): ${_money(invoice.taxAmount)}',
                style: GoogleFonts.poppins(fontSize: 11 * scale, color: kRedModernMuted),
              ),
            ),
          ),
        SizedBox(height: 4 * scale),
        Row(
          children: [
            const Spacer(flex: 5),
            Expanded(
              flex: 4,
              child: Container(
                color: kRedModernBlack,
                padding: EdgeInsets.symmetric(vertical: 9 * scale, horizontal: 12 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      totalLabel,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12 * scale,
                      ),
                    ),
                    Text(
                      _money(totalValue),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12 * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerCell(String text, {required int flex, required TextAlign align}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: align,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12 * scale),
        ),
      );

  Widget _cell(String text, {required int flex, required TextAlign align}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: align,
          style: GoogleFonts.poppins(color: kRedModernBlack, fontSize: 12 * scale),
        ),
      );
}

class _PaymentAndThanks extends StatelessWidget {
  const _PaymentAndThanks({
    required this.strings,
    required this.email,
    required this.phone,
    required this.taxId,
    required this.paymentTerms,
    required this.scale,
  });

  final AppStrings strings;
  final String email;
  final String phone;
  final String taxId;
  final String? paymentTerms;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.paymentInformation,
                style: GoogleFonts.poppins(fontSize: 13 * scale, fontWeight: FontWeight.w700, color: kRedModernBlack),
              ),
              SizedBox(height: 6 * scale),
              if (phone.isNotEmpty) _kv('${strings.phoneNumber}:', phone, scale),
              if (email.isNotEmpty) _kv('${strings.email}:', email, scale),
              if (taxId.isNotEmpty) _kv('${strings.taxId}:', taxId, scale),
              if (paymentTerms?.isNotEmpty == true) _kv('${strings.paymentTerms}:', paymentTerms!, scale),
            ],
          ),
        ),
        Text(
          strings.thankYou,
          style: GoogleFonts.greatVibes(fontSize: 40 * scale, color: kRedModernBlack),
        ),
      ],
    );
  }

  Widget _kv(String k, String v, double scale) => Padding(
        padding: EdgeInsets.only(bottom: 2 * scale),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 11 * scale, color: kRedModernMuted),
            children: [
              TextSpan(text: '$k  ', style: TextStyle(fontWeight: FontWeight.w700, color: kRedModernBlack, fontSize: 11 * scale)),
              TextSpan(text: v),
            ],
          ),
        ),
      );
}
