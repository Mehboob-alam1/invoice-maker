import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_format.dart';
import '../../core/utils/invoice_layout_scale.dart';
import '../../l10n/app_strings.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';

const Color kReceiptNavy = Color(0xFF1F2937);
const Color kReceiptOrange = Color(0xFFE0872A);
const Color kReceiptInk = Color(0xFF1B1B1B);
const Color kReceiptMuted = Color(0xFF5B5B5B);

class OrangeBlackReceiptTemplate extends StatelessWidget {
  const OrangeBlackReceiptTemplate({
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

  String _statusLabel() {
    switch (invoice.displayStatus) {
      case InvoiceStatus.paid:
        return strings.paid.toUpperCase();
      case InvoiceStatus.overdue:
        return strings.overdue.toUpperCase();
      case InvoiceStatus.unpaid:
        return strings.unpaid.toUpperCase();
    }
  }

  String get _notesText {
    if (invoice.notes?.trim().isNotEmpty == true) return invoice.notes!.trim();
    return strings.receiptDefaultNotes;
  }

  @override
  Widget build(BuildContext context) {
    final layout = InvoiceLayoutScale.of(context);
    final s = layout.scale;
    final pad = 28.0 * s;
    final locale = provider.languageCode;
    final dateStr = DateFormat.yMMMMd(locale).format(invoice.date);
    final (line1, line2) = _companyLines;
    final c = invoice.client;
    final address = c.address ?? '';
    final phone = c.phone ?? '';

    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(2),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopWaveHeader(companyLine1: line1, companyLine2: line2, scale: s),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 14 * s, pad, 8 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                layout.compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _iconLine(Icons.location_on_outlined, provider.businessAddress.replaceAll('\n', ', '), s),
                          SizedBox(height: 6 * s),
                          _iconLine(Icons.call_outlined, provider.businessPhone, s),
                          SizedBox(height: 6 * s),
                          _iconLine(Icons.email_outlined, provider.businessEmail, s),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _iconLine(Icons.location_on_outlined, provider.businessAddress, s)),
                          Expanded(child: _iconLine(Icons.call_outlined, provider.businessPhone, s)),
                          Expanded(child: _iconLine(Icons.email_outlined, provider.businessEmail, s)),
                        ],
                      ),
                SizedBox(height: 8 * s),
                Container(height: 1, color: Colors.grey.shade300),
                SizedBox(height: 14 * s),
                Center(
                  child: Text(
                    strings.paymentReceiptTitle,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20 * s,
                      fontWeight: FontWeight.w700,
                      color: kReceiptInk,
                    ),
                  ),
                ),
                SizedBox(height: 14 * s),
                _DetailsBox(
                  scale: s,
                  date: dateStr,
                  customerName: c.name,
                  address: address,
                  phone: phone,
                  strings: strings,
                ),
                SizedBox(height: 16 * s),
                _ReceiptTable(invoice: invoice, strings: strings, scale: s),
                SizedBox(height: 14 * s),
                _PaymentStatusRow(
                  status: _statusLabel(),
                  total: CurrencyFormat.format(invoice.currency, invoice.total),
                  strings: strings,
                  scale: s,
                ),
                SizedBox(height: 12 * s),
                _NotesBox(notes: _notesText, strings: strings, scale: s),
                SizedBox(height: 18 * s),
              ],
            ),
          ),
          SizedBox(height: 42 * s, child: CustomPaint(painter: _BottomWavePainter(), size: Size.infinite)),
        ],
      ),
    );
  }

  Widget _iconLine(IconData icon, String text, double s) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15 * s, color: kReceiptNavy),
        SizedBox(width: 5 * s),
        Expanded(
          child: Text(text, style: GoogleFonts.lato(fontSize: 11 * s, color: kReceiptInk)),
        ),
      ],
    );
  }
}

class _TopWaveHeader extends StatelessWidget {
  const _TopWaveHeader({required this.companyLine1, required this.companyLine2, required this.scale});
  final String companyLine1;
  final String companyLine2;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 78 * scale, child: CustomPaint(painter: _TopWavePainter(), size: Size.infinite)),
        Padding(
          padding: EdgeInsets.fromLTRB(28 * scale, 10 * scale, 28 * scale, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    companyLine1,
                    style: GoogleFonts.poppins(
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.w800,
                      color: kReceiptNavy,
                      letterSpacing: 1,
                    ),
                  ),
                  if (companyLine2.isNotEmpty)
                    Text(
                      companyLine2,
                      style: GoogleFonts.poppins(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w700,
                        color: kReceiptOrange,
                        letterSpacing: 1.5,
                      ),
                    ),
                ],
              ),
              SizedBox(width: 8 * scale),
              CustomPaint(size: Size(32 * scale, 36 * scale), painter: _WingMarkPainter()),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final navy = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.28)
      ..cubicTo(w * 0.72, h * 0.85, w * 0.35, h * 0.10, 0, h * 0.55)
      ..close();
    canvas.drawPath(navy, Paint()..color = kReceiptNavy);

    final creamLine = Path()
      ..moveTo(0, h * 0.62)
      ..cubicTo(w * 0.35, h * 0.17, w * 0.72, h * 0.92, w, h * 0.35);
    canvas.drawPath(
      creamLine,
      Paint()
        ..color = const Color(0xFFF3E9DD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final orangeLine = Path()
      ..moveTo(0, h * 0.74)
      ..cubicTo(w * 0.35, h * 0.30, w * 0.72, h * 1.02, w, h * 0.48);
    canvas.drawPath(
      orangeLine,
      Paint()
        ..color = kReceiptOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WingMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final orange = Paint()..color = kReceiptOrange;
    final navy = Paint()..color = kReceiptNavy;

    final leftWing = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..quadraticBezierTo(0, h * 0.45, w * 0.15, h)
      ..quadraticBezierTo(w * 0.35, h * 0.55, w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(leftWing, navy);

    final rightWing = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..quadraticBezierTo(w, h * 0.45, w * 0.85, h)
      ..quadraticBezierTo(w * 0.65, h * 0.55, w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(rightWing, orange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DetailsBox extends StatelessWidget {
  const _DetailsBox({
    required this.scale,
    required this.date,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.strings,
  });

  final double scale;
  final String date;
  final String customerName;
  final String address;
  final String phone;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLine(label: strings.date, value: date, scale: scale),
          SizedBox(height: 8 * scale),
          _FieldLine(label: strings.customerNameLabel, value: customerName, scale: scale),
          SizedBox(height: 8 * scale),
          _FieldLine(label: strings.address, value: address, scale: scale),
          SizedBox(height: 8 * scale),
          _FieldLine(label: strings.phoneNumber, value: phone, scale: scale),
        ],
      ),
    );
  }
}

class _FieldLine extends StatelessWidget {
  const _FieldLine({required this.label, required this.value, required this.scale});
  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 120 * scale,
          child: Text(label, style: GoogleFonts.lato(fontSize: 12 * scale, color: kReceiptInk)),
        ),
        Text('=', style: GoogleFonts.lato(fontSize: 12 * scale, color: kReceiptInk)),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                value.isEmpty ? ' ' : value,
                style: GoogleFonts.lato(fontSize: 12 * scale, color: kReceiptInk),
              ),
              Container(margin: EdgeInsets.only(top: 2 * scale), height: 1, color: kReceiptInk),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptTable extends StatelessWidget {
  const _ReceiptTable({required this.invoice, required this.strings, required this.scale});
  final Invoice invoice;
  final AppStrings strings;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(color: Colors.grey.shade500, width: 0.8);
    final headerStyle = GoogleFonts.lato(fontSize: 11 * scale, fontWeight: FontWeight.w700, color: kReceiptInk);
    final cellStyle = GoogleFonts.lato(fontSize: 11 * scale, color: kReceiptInk);
    final rowCount = invoice.items.length.clamp(1, 12);
    final padRows = rowCount < 6 ? 6 - rowCount : 0;

    Widget headerCell(String text, {TextAlign align = TextAlign.left, bool last = false}) => Container(
          padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 6 * scale),
          decoration: BoxDecoration(
            color: kReceiptOrange,
            border: Border(right: last ? BorderSide.none : borderSide, bottom: borderSide),
          ),
          child: Text(text, textAlign: align, style: headerStyle),
        );

    Widget dataCell(String text, {TextAlign align = TextAlign.left, bool last = false}) => Container(
          padding: EdgeInsets.symmetric(vertical: 6 * scale, horizontal: 6 * scale),
          decoration: BoxDecoration(border: Border(right: last ? BorderSide.none : borderSide, bottom: borderSide)),
          child: Text(text, textAlign: align, style: cellStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        );

    Widget blankCell({bool last = false}) => Container(
          height: 28 * scale,
          decoration: BoxDecoration(border: Border(right: last ? BorderSide.none : borderSide, bottom: borderSide)),
        );

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade500, width: 0.8)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 1, child: headerCell('#')),
              Expanded(flex: 4, child: headerCell(strings.description, align: TextAlign.center)),
              Expanded(flex: 2, child: headerCell(strings.quantity, align: TextAlign.center)),
              Expanded(flex: 2, child: headerCell(strings.unitPrice, align: TextAlign.center)),
              Expanded(flex: 2, child: headerCell(strings.lineTotal, align: TextAlign.center, last: true)),
            ],
          ),
          ...List.generate(rowCount, (i) {
            if (i < invoice.items.length) {
              final item = invoice.items[i];
              return Row(
                children: [
                  Expanded(flex: 1, child: dataCell('${i + 1}')),
                  Expanded(flex: 4, child: dataCell(item.description)),
                  Expanded(flex: 2, child: dataCell('${item.quantity}', align: TextAlign.center)),
                  Expanded(
                    flex: 2,
                    child: dataCell(CurrencyFormat.format(invoice.currency, item.unitCost), align: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: dataCell(CurrencyFormat.format(invoice.currency, item.total), align: TextAlign.center, last: true),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 1, child: blankCell()),
                Expanded(flex: 4, child: blankCell()),
                Expanded(flex: 2, child: blankCell()),
                Expanded(flex: 2, child: blankCell()),
                Expanded(flex: 2, child: blankCell(last: true)),
              ],
            );
          }),
          for (int i = 0; i < padRows; i++)
            Row(
              children: [
                Expanded(flex: 1, child: blankCell()),
                Expanded(flex: 4, child: blankCell()),
                Expanded(flex: 2, child: blankCell()),
                Expanded(flex: 2, child: blankCell()),
                Expanded(flex: 2, child: blankCell(last: true)),
              ],
            ),
        ],
      ),
    );
  }
}

class _PaymentStatusRow extends StatelessWidget {
  const _PaymentStatusRow({
    required this.status,
    required this.total,
    required this.strings,
    required this.scale,
  });

  final String status;
  final String total;
  final AppStrings strings;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.lato(fontSize: 12 * scale, fontWeight: FontWeight.w700, color: kReceiptInk);
    final bodyStyle = GoogleFonts.lato(fontSize: 12 * scale, color: kReceiptInk);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${strings.paymentStatusLabel}:', style: labelStyle),
              Text(status, style: bodyStyle),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Text('${strings.totalPaymentLabel}:  ', style: labelStyle),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(total, style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                    Container(
                      margin: EdgeInsets.only(top: 2 * scale),
                      height: 1,
                      color: kReceiptInk,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotesBox extends StatelessWidget {
  const _NotesBox({required this.notes, required this.strings, required this.scale});
  final String notes;
  final AppStrings strings;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 280 * scale),
        padding: EdgeInsets.all(10 * scale),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.notesBoxTitle,
              style: GoogleFonts.lato(fontSize: 11 * scale, fontWeight: FontWeight.w700, color: kReceiptInk),
            ),
            SizedBox(height: 4 * scale),
            Text(notes, style: GoogleFonts.lato(fontSize: 11 * scale, color: kReceiptMuted)),
          ],
        ),
      ),
    );
  }
}

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.35)
      ..cubicTo(w * 0.32, h * 1.1, w * 0.68, -h * 0.2, w, h * 0.55)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = kReceiptOrange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
