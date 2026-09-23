import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_format.dart';
import '../../core/utils/invoice_layout_scale.dart';
import '../../l10n/app_strings.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';

const Color kGeoNavy = Color(0xFF14224E);
const Color kGeoNavyLight = Color(0xFF1D2E66);
const Color kGeoGold = Color(0xFFE4B84C);
const Color kGeoInk = Color(0xFF1B1B1B);
const Color kGeoMuted = Color(0xFF5B5B5B);

class BlueYellowGeometricInvoiceTemplate extends StatelessWidget {
  const BlueYellowGeometricInvoiceTemplate({
    super.key,
    required this.invoice,
    required this.provider,
    required this.strings,
  });

  final Invoice invoice;
  final InvoiceProvider provider;
  final AppStrings strings;

  (String, String) get _companyLines {
    final name = provider.businessName.trim().isEmpty ? strings.defaultBusinessName : provider.businessName.trim();
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length <= 1) return (parts.first.toUpperCase(), '');
    return (parts.first.toUpperCase(), parts.sublist(1).join(' ').toUpperCase());
  }

  String _money(double v) => CurrencyFormat.format(invoice.currency, v);

  @override
  Widget build(BuildContext context) {
    final layout = InvoiceLayoutScale.of(context);
    final s = layout.scale;
    final locale = provider.languageCode;
    final dateStr = DateFormat.yMMMMd(locale).format(invoice.date);
    final (line1, line2) = _companyLines;
    final pad = 28.0 * s;
    final taxAmount = invoice.taxAmount;
    final total = invoice.total;

    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(2),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 130 * s, child: CustomPaint(painter: _WavePainter(flipped: false), size: Size.infinite)),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 20 * s, pad, 8 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LogoMark(line1: line1, line2: line2, scale: s),
                SizedBox(height: 16 * s),
                Text(
                  strings.invoice.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(fontSize: 24 * s, fontWeight: FontWeight.w700, color: kGeoInk),
                ),
                SizedBox(height: 8 * s),
                Text('${strings.invoiceNumber}: ${invoice.number}',
                    style: GoogleFonts.lato(fontSize: 12 * s, color: kGeoInk)),
                Text('${strings.date}: $dateStr', style: GoogleFonts.lato(fontSize: 12 * s, color: kGeoInk)),
                SizedBox(height: 18 * s),
                layout.stackParties
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _billPaymentColumn(strings, s),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _billTo(strings, s)),
                          Expanded(flex: 6, child: _paymentInfo(strings, s)),
                        ],
                      ),
                SizedBox(height: 18 * s),
                _ItemsTable(invoice: invoice, strings: strings, money: _money, scale: s),
                SizedBox(height: 12 * s),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: (260 * s).clamp(200, 280),
                    padding: EdgeInsets.symmetric(vertical: 9 * s, horizontal: 14 * s),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                    child: Column(
                      children: [
                        _summaryRow('${strings.subtotal}:', _money(invoice.subtotal), s),
                        if (invoice.taxRate > 0) ...[
                          SizedBox(height: 5 * s),
                          _summaryRow('${strings.tax}:', _money(taxAmount), s),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10 * s),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: (260 * s).clamp(200, 280),
                    padding: EdgeInsets.symmetric(vertical: 9 * s, horizontal: 14 * s),
                    color: kGeoNavy,
                    child: Text(
                      '${strings.total.toUpperCase()}: ${_money(total)}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13 * s,
                      ),
                    ),
                  ),
                ),
                if (invoice.paymentTerms?.isNotEmpty == true) ...[
                  SizedBox(height: 18 * s),
                  Text(
                    strings.termsAndConditionsLabel.toUpperCase(),
                    style: GoogleFonts.playfairDisplay(fontSize: 12 * s, fontWeight: FontWeight.w700, color: kGeoInk),
                  ),
                  SizedBox(height: 4 * s),
                  Text(invoice.paymentTerms!, style: GoogleFonts.lato(fontSize: 11 * s, color: kGeoMuted)),
                ],
                SizedBox(height: 20 * s),
              ],
            ),
          ),
          SizedBox(height: 80 * s, child: CustomPaint(painter: _WavePainter(flipped: true), size: Size.infinite)),
        ],
      ),
    );
  }

  Widget _billPaymentColumn(AppStrings strings, double s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _billTo(strings, s),
          SizedBox(height: 12 * s),
          _paymentInfo(strings, s),
        ],
      );

  Widget _billTo(AppStrings strings, double s) {
    final labelStyle = GoogleFonts.playfairDisplay(fontSize: 12 * s, fontWeight: FontWeight.w700, color: kGeoInk);
    final bodyStyle = GoogleFonts.lato(fontSize: 12 * s, color: kGeoInk);
    final c = invoice.client;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${strings.billTo}:'.toUpperCase(), style: labelStyle),
        SizedBox(height: 4 * s),
        Text(c.name, style: bodyStyle),
        if (c.address?.isNotEmpty == true) Text(c.address!, style: bodyStyle),
        if (c.phone?.isNotEmpty == true) Text(c.phone!, style: bodyStyle),
        if (c.email?.isNotEmpty == true) Text(c.email!, style: bodyStyle),
      ],
    );
  }

  Widget _paymentInfo(AppStrings strings, double s) {
    final labelStyle = GoogleFonts.playfairDisplay(fontSize: 12 * s, fontWeight: FontWeight.w700, color: kGeoInk);
    final bodyStyle = GoogleFonts.lato(fontSize: 12 * s, color: kGeoInk);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.paymentInformation.toUpperCase(), style: labelStyle),
        SizedBox(height: 4 * s),
        if (provider.businessName.isNotEmpty) _kv('${strings.name}:', provider.businessName, bodyStyle),
        if (provider.businessPhone.isNotEmpty) _kv('${strings.phoneNumber}:', provider.businessPhone, bodyStyle),
        if (provider.businessEmail.isNotEmpty) _kv('${strings.email}:', provider.businessEmail, bodyStyle),
        if (provider.businessTaxId.isNotEmpty) _kv('${strings.taxId}:', provider.businessTaxId, bodyStyle),
      ],
    );
  }

  Widget _kv(String k, String v, TextStyle style) => Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: RichText(
          text: TextSpan(
            style: style,
            children: [
              TextSpan(text: '$k  ', style: style.copyWith(fontWeight: FontWeight.w700)),
              TextSpan(text: v),
            ],
          ),
        ),
      );

  Widget _summaryRow(String label, String value, double s) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.lato(fontSize: 12 * s, color: kGeoInk)),
          Text(value, style: GoogleFonts.lato(fontSize: 12 * s, color: kGeoInk)),
        ],
      );
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.flipped});
  final bool flipped;

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = Paint()
      ..shader = const LinearGradient(
        colors: [kGeoNavy, kGeoNavyLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    if (!flipped) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height * 0.45)
        ..cubicTo(size.width * 0.72, size.height * 0.95, size.width * 0.38, size.height * 0.35, 0, size.height * 0.75)
        ..close();
    } else {
      path
        ..moveTo(0, size.height * 0.35)
        ..cubicTo(size.width * 0.30, size.height * 0.85, size.width * 0.65, size.height * 0.05, size.width, size.height * 0.55)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
    }
    canvas.drawPath(path, gradient);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.line1, required this.line2, required this.scale});
  final String line1;
  final String line2;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(line1,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18 * scale, fontWeight: FontWeight.w700, color: kGeoInk, letterSpacing: 1)),
            if (line2.isNotEmpty)
              Text(line2,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18 * scale, fontWeight: FontWeight.w700, color: kGeoInk, letterSpacing: 1)),
          ],
        ),
        SizedBox(width: 10 * scale),
        CustomPaint(size: Size(36 * scale, 40 * scale), painter: _DiamondMarkPainter()),
      ],
    );
  }
}

class _DiamondMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()..color = kGeoGold;
    final navy = Paint()..color = kGeoNavy;
    final w = size.width, h = size.height;
    for (int i = 0; i < 3; i++) {
      final top = i * h * 0.30;
      final path = Path()
        ..moveTo(w * 0.5, top)
        ..lineTo(w, top + h * 0.16)
        ..lineTo(w * 0.5, top + h * 0.32)
        ..lineTo(0, top + h * 0.16)
        ..close();
      canvas.drawPath(path, i == 2 ? navy : gold);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({
    required this.invoice,
    required this.strings,
    required this.money,
    required this.scale,
  });

  final Invoice invoice;
  final AppStrings strings;
  final String Function(double) money;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: kGeoNavy)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: kGeoNavy,
            padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 12 * scale),
            child: Row(
              children: [
                _headerCell('#', flex: 1),
                _headerCell(strings.description.toUpperCase(), flex: 5),
                _headerCell(strings.unitPrice.toUpperCase(), flex: 2, align: TextAlign.center),
                _headerCell(strings.lineTotal.toUpperCase(), flex: 2, align: TextAlign.right),
              ],
            ),
          ),
          ...invoice.items.asMap().entries.map(
                (e) => Container(
                  padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 12 * scale),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.7)),
                  ),
                  child: Row(
                    children: [
                      _cell('${e.key + 1}.', flex: 1),
                      _cell(e.value.description, flex: 5),
                      _cell(money(e.value.unitCost), flex: 2, align: TextAlign.center),
                      _cell(money(e.value.total), flex: 2, align: TextAlign.right),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex, TextAlign align = TextAlign.left}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: align,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11 * scale,
          ),
        ),
      );

  Widget _cell(String text, {required int flex, TextAlign align = TextAlign.left}) => Expanded(
        flex: flex,
        child: Text(text, textAlign: align, style: GoogleFonts.lato(color: kGeoInk, fontSize: 11 * scale)),
      );
}
