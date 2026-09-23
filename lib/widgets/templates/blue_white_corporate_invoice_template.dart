import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_format.dart';
import '../../core/utils/invoice_layout_scale.dart';
import '../../l10n/app_strings.dart';
import '../../models/client.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';

const Color kCorpNavy = Color(0xFF14304F);
const Color kCorpTeal = Color(0xFF9FD8D6);
const Color kCorpInk = Color(0xFF16283F);
const Color kCorpMuted = Color(0xFF4A5A6E);

class BlueWhiteCorporateInvoiceTemplate extends StatelessWidget {
  const BlueWhiteCorporateInvoiceTemplate({
    super.key,
    required this.invoice,
    required this.provider,
    required this.strings,
  });

  final Invoice invoice;
  final InvoiceProvider provider;
  final AppStrings strings;

  String _money(double v) => CurrencyFormat.format(invoice.currency, v);

  String _itemUnit(String? notes) {
    if (notes != null && notes.trim().isNotEmpty && notes.length <= 12) return notes.trim();
    return 'ea';
  }

  List<String> get _termsLines {
    final lines = <String>[];
    if (invoice.paymentTerms?.trim().isNotEmpty == true) lines.add(invoice.paymentTerms!.trim());
    if (invoice.notes?.trim().isNotEmpty == true) lines.add(invoice.notes!.trim());
    if (lines.isEmpty) {
      lines.add(strings.defaultPaymentTermsHint);
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final layout = InvoiceLayoutScale.of(context);
    final s = layout.scale;
    final locale = provider.languageCode;
    final issueStr = DateFormat.yMMMMd(locale).format(invoice.date);
    final dueStr = invoice.dueDate != null ? DateFormat.yMMMMd(locale).format(invoice.dueDate!) : '—';
    final pad = 28.0 * s;
    final c = invoice.client;

    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(2),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 260 * s,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _DiagonalSweepPainter())),
                Positioned(
                  top: 22 * s,
                  right: 22 * s,
                  child: CustomPaint(size: Size(56 * s, 56 * s), painter: _PinwheelPainter()),
                ),
                Positioned(
                  left: pad,
                  bottom: 48 * s,
                  child: Text(
                    strings.invoice.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 44 * s,
                      fontWeight: FontWeight.w800,
                      color: kCorpNavy,
                    ),
                  ),
                ),
                Positioned(
                  left: pad,
                  right: pad,
                  bottom: 20 * s,
                  child: Container(height: 1.2, color: kCorpNavy.withValues(alpha: 0.35)),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 16 * s, pad, 24 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                layout.stackParties
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _invoiceMeta(strings, issueStr, dueStr, s),
                          SizedBox(height: 14 * s),
                          _clientDetail(strings, c, s),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _invoiceMeta(strings, issueStr, dueStr, s)),
                          Expanded(flex: 6, child: _clientDetail(strings, c, s)),
                        ],
                      ),
                SizedBox(height: 18 * s),
                _ItemsTable(invoice: invoice, strings: strings, money: _money, unitFor: _itemUnit, scale: s),
                SizedBox(height: 16 * s),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _kv('${strings.subtotal}:', _money(invoice.subtotal), s),
                          if (invoice.taxRate > 0)
                            _kv('${strings.tax} (${invoice.taxRate.toStringAsFixed(0)}%):', _money(invoice.taxAmount), s),
                          _kv('${strings.grandTotal}:', _money(invoice.total), s, boldValue: true),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (provider.businessEmail.isNotEmpty)
                            _kv('${strings.email}:', provider.businessEmail, s),
                          if (provider.businessPhone.isNotEmpty)
                            _kv('${strings.phoneNumber}:', provider.businessPhone, s),
                          if (provider.businessTaxId.isNotEmpty)
                            _kv('${strings.taxId}:', provider.businessTaxId, s),
                          _kv('${strings.paymentTerms}:', invoice.paymentTerms ?? strings.defaultPaymentTermsHint, s),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18 * s),
                Container(height: 1, color: Colors.grey.shade300),
                SizedBox(height: 12 * s),
                Text(
                  strings.termsAndConditionsLabel,
                  style: GoogleFonts.poppins(fontSize: 14 * s, fontWeight: FontWeight.w700, color: kCorpNavy),
                ),
                SizedBox(height: 6 * s),
                ..._termsLines.map(
                  (t) => Padding(
                    padding: EdgeInsets.only(bottom: 3 * s),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: GoogleFonts.lato(fontSize: 11 * s, color: kCorpMuted)),
                        Expanded(child: Text(t, style: GoogleFonts.lato(fontSize: 11 * s, color: kCorpMuted))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceMeta(AppStrings strings, String issue, String due, double s) {
    final bold = GoogleFonts.lato(fontSize: 11 * s, color: kCorpInk, fontWeight: FontWeight.w700);
    final body = GoogleFonts.lato(fontSize: 11 * s, color: kCorpInk);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('${strings.invoiceNumber}:', invoice.number, s),
        _kv('${strings.issueDate}:', issue, s),
        _kv('${strings.dueDate}:', due, s),
        RichText(
          text: TextSpan(children: [
            TextSpan(text: '${strings.currency}:  ', style: bold),
            TextSpan(text: invoice.currency, style: body),
          ]),
        ),
      ],
    );
  }

  Widget _clientDetail(AppStrings strings, Client c, double s) {
    final bold = GoogleFonts.lato(fontSize: 11 * s, color: kCorpInk, fontWeight: FontWeight.w700);
    final body = GoogleFonts.lato(fontSize: 11 * s, color: kCorpInk);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.clientDetailLabel.toUpperCase(),
          style: GoogleFonts.poppins(fontSize: 12 * s, fontWeight: FontWeight.w700, color: kCorpNavy),
        ),
        SizedBox(height: 4 * s),
        Text(c.name, style: bold),
        if (c.address?.isNotEmpty == true) Text(c.address!, style: body),
        if (c.email?.isNotEmpty == true) Text('E: ${c.email}', style: body),
        if (c.phone?.isNotEmpty == true) Text('P: ${c.phone}', style: body),
      ],
    );
  }

  Widget _kv(String k, String v, double s, {bool boldValue = false}) {
    final bold = GoogleFonts.lato(fontSize: 11 * s, color: kCorpNavy, fontWeight: FontWeight.w700);
    final body = GoogleFonts.lato(
      fontSize: 11 * s,
      color: kCorpInk,
      fontWeight: boldValue ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 2 * s),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: '$k  ', style: bold),
          TextSpan(text: v, style: body),
        ]),
      ),
    );
  }
}

class _DiagonalSweepPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tealPath = Path()
      ..moveTo(w * 0.30, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.72)
      ..close();
    final tealPaint = Paint()
      ..shader = LinearGradient(
        colors: [kCorpTeal.withValues(alpha: 0.9), kCorpTeal.withValues(alpha: 0.35)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(tealPath, tealPaint);

    final navyPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.62, 0)
      ..lineTo(w * 0.30, h * 0.62)
      ..lineTo(0, h * 0.30)
      ..close();
    canvas.drawPath(navyPath, Paint()..color = kCorpNavy);

    final accentPath = Path()
      ..moveTo(w * 0.62, 0)
      ..lineTo(w * 0.70, 0)
      ..lineTo(w * 0.38, h * 0.62)
      ..lineTo(w * 0.30, h * 0.62)
      ..close();
    canvas.drawPath(accentPath, Paint()..color = kCorpNavy.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinwheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kCorpNavy.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (int i = 0; i < 8; i++) {
      final petal = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(r * 0.55, -r * 0.15, r * 0.9, 0)
        ..quadraticBezierTo(r * 0.55, r * 0.15, 0, 0);
      canvas.drawPath(petal, paint);
      canvas.rotate(math.pi / 4);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({
    required this.invoice,
    required this.strings,
    required this.money,
    required this.unitFor,
    required this.scale,
  });

  final Invoice invoice;
  final AppStrings strings;
  final String Function(double) money;
  final String Function(String?) unitFor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final headerStyle = GoogleFonts.poppins(
      fontSize: 10 * scale,
      fontWeight: FontWeight.w700,
      color: kCorpNavy,
    );
    final cellStyle = GoogleFonts.lato(fontSize: 11 * scale, color: kCorpInk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 7 * scale),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kCorpNavy, width: 1.4)),
          ),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text(strings.description.toUpperCase(), style: headerStyle)),
              Expanded(flex: 1, child: Text(strings.quantity.toUpperCase(), textAlign: TextAlign.center, style: headerStyle)),
              Expanded(flex: 2, child: Text(strings.itemUnitLabel.toUpperCase(), textAlign: TextAlign.center, style: headerStyle)),
              Expanded(flex: 2, child: Text(strings.unitPrice.toUpperCase(), textAlign: TextAlign.center, style: headerStyle)),
              Expanded(flex: 2, child: Text(strings.lineTotal.toUpperCase(), textAlign: TextAlign.right, style: headerStyle)),
            ],
          ),
        ),
        ...invoice.items.map(
          (item) => Container(
            padding: EdgeInsets.symmetric(vertical: 8 * scale),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.7)),
            ),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text(item.description, style: cellStyle)),
                Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center, style: cellStyle)),
                Expanded(flex: 2, child: Text(unitFor(item.notes), textAlign: TextAlign.center, style: cellStyle)),
                Expanded(flex: 2, child: Text(money(item.unitCost), textAlign: TextAlign.center, style: cellStyle)),
                Expanded(flex: 2, child: Text(money(item.total), textAlign: TextAlign.right, style: cellStyle)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
