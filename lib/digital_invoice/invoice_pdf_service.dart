import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'digital_invoice_model.dart';
import 'invoice_gradient_theme.dart';

class InvoicePdfService {
  InvoicePdfService._();

  static const _maroon = PdfColor.fromInt(0xFF7B1E3A);
  static const _black = PdfColor.fromInt(0xFF1B1B1B);
  static const _cream = PdfColor.fromInt(0xFFF6F2EC);
  static const _muted = PdfColor.fromInt(0xFF6B6B6B);

  static Future<void> printRedModernPdf(DigitalInvoice invoice) async {
    final doc = await _buildRedModern(invoice);
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static Future<void> shareRedModernPdf(DigitalInvoice invoice) async {
    final doc = await _buildRedModern(invoice);
    await Printing.sharePdf(bytes: await doc.save(), filename: _pdfFilename(invoice));
  }

  static const _geoNavy = PdfColor.fromInt(0xFF14224E);
  static const _geoGold = PdfColor.fromInt(0xFFE4B84C);
  static const _corpNavy = PdfColor.fromInt(0xFF14304F);
  static const _corpTeal = PdfColor.fromInt(0xFF9FD8D6);

  static Future<void> printBlueYellowPdf(DigitalInvoice invoice) async {
    final doc = await _buildBlueYellow(invoice);
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static Future<void> shareBlueYellowPdf(DigitalInvoice invoice) async {
    final doc = await _buildBlueYellow(invoice);
    await Printing.sharePdf(bytes: await doc.save(), filename: _pdfFilename(invoice));
  }

  static Future<void> printBlueCorporatePdf(DigitalInvoice invoice) async {
    final doc = await _buildBlueCorporate(invoice);
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static Future<void> shareBlueCorporatePdf(DigitalInvoice invoice) async {
    final doc = await _buildBlueCorporate(invoice);
    await Printing.sharePdf(bytes: await doc.save(), filename: _pdfFilename(invoice));
  }

  static const _receiptNavy = PdfColor.fromInt(0xFF1F2937);
  static const _receiptOrange = PdfColor.fromInt(0xFFE0872A);

  static Future<void> printOrangeReceiptPdf(DigitalInvoice invoice) async {
    final doc = await _buildOrangeReceipt(invoice);
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static Future<void> shareOrangeReceiptPdf(DigitalInvoice invoice) async {
    final doc = await _buildOrangeReceipt(invoice);
    await Printing.sharePdf(bytes: await doc.save(), filename: _pdfFilename(invoice));
  }

  static String _pdfFilename(DigitalInvoice invoice) =>
      'Invoice-${invoice.invoiceNumber.replaceAll('#', '').replaceAll('/', '-')}';

  static Future<void> printDocument(DigitalInvoice invoice, {InvoiceGradientTheme? theme}) async {
    final doc = await _build(invoice, theme: theme ?? InvoiceThemes.midnight);
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static Future<void> sharePdf(DigitalInvoice invoice, {InvoiceGradientTheme? theme}) async {
    final doc = await _build(invoice, theme: theme ?? InvoiceThemes.midnight);
    await Printing.sharePdf(bytes: await doc.save(), filename: _pdfFilename(invoice));
  }

  static Future<pw.Document> _build(DigitalInvoice invoice, {required InvoiceGradientTheme theme}) async {
    final doc = pw.Document();
    final c = theme.accent;
    final accent = PdfColor(c.r, c.g, c.b);
    final money = NumberFormat.currency(
      locale: invoice.locale,
      symbol: invoice.currencySymbol,
      decimalDigits: 2,
    );
    final dateFmt = DateFormat('dd MMM yyyy', invoice.locale);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(invoice.seller.name, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: accent)),
                  pw.SizedBox(height: 4),
                  if (invoice.seller.fullAddress.isNotEmpty)
                    pw.Text(invoice.seller.fullAddress, style: const pw.TextStyle(fontSize: 9)),
                  if (invoice.seller.taxId.isNotEmpty)
                    pw.Text('${invoice.seller.taxIdLabel}: ${invoice.seller.taxId}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: accent)),
                  pw.Text('No. ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Issued: ${dateFmt.format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Due: ${dateFmt.format(invoice.dueDate)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: accent),
          pw.SizedBox(height: 12),
          _pdfParty('Bill To', invoice.buyer, accent),
          pw.SizedBox(height: 18),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: accent),
                children: [
                  _th('Description'),
                  _th('Qty', align: pw.TextAlign.center),
                  _th('Unit Price', align: pw.TextAlign.right),
                  _th('Tax', align: pw.TextAlign.center),
                  _th('Amount', align: pw.TextAlign.right),
                ],
              ),
              for (final item in invoice.items)
                pw.TableRow(
                  children: [
                    _td(item.description),
                    _td(
                      item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : '${item.quantity}',
                      align: pw.TextAlign.center,
                    ),
                    _td(money.format(item.unitPrice), align: pw.TextAlign.right),
                    _td(
                      invoice.invoiceTaxRatePercent > 0 ? '—' : '${item.taxRatePercent.toStringAsFixed(0)}%',
                      align: pw.TextAlign.center,
                    ),
                    _td(money.format(item.netAmount), align: pw.TextAlign.right),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 240,
              child: pw.Column(
                children: [
                  _totalRow('Subtotal', money.format(invoice.subtotal)),
                  for (final tb in invoice.taxBreakdown)
                    if (tb.ratePercent > 0)
                      _totalRow('Tax ${tb.ratePercent.toStringAsFixed(0)}%', money.format(tb.taxAmount)),
                  pw.Divider(),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    color: accent,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Due', style: const pw.TextStyle(color: PdfColors.white)),
                        pw.Text(money.format(invoice.grandTotal),
                            style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 9)),
          ],
          if (invoice.termsAndConditions.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Terms & Conditions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(invoice.termsAndConditions, style: const pw.TextStyle(fontSize: 9)),
          ],
        ],
      ),
    );
    return doc;
  }

  static Future<pw.Document> _buildRedModern(DigitalInvoice invoice) async {
    final doc = pw.Document();
    final money = NumberFormat.currency(
      locale: invoice.locale,
      symbol: invoice.currencySymbol,
      decimalDigits: 2,
    );
    final dateFmt = DateFormat.yMMMMd(invoice.locale);
    final company = invoice.seller.name.toUpperCase();
    final totalDue = invoice.grandTotal;
    final showTax = invoice.totalTax > 0.01;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              height: 120,
              color: _cream,
              child: pw.Stack(
                children: [
                  pw.Positioned(
                    right: 0,
                    top: 0,
                    child: pw.Container(width: 200, height: 120, color: _maroon),
                  ),
                  pw.Positioned(
                    right: 0,
                    top: 14,
                    child: pw.Container(width: 120, height: 88, color: _black),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 0),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(company, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
                        pw.SizedBox(height: 14),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: _maroon)),
                            pw.Text('NO: ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Container(
                color: _cream,
                padding: const pw.EdgeInsets.fromLTRB(36, 16, 36, 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(child: _redParty('Bill To:', invoice.buyer)),
                        pw.SizedBox(width: 16),
                        pw.Expanded(child: _redParty('From:', invoice.seller, alignRight: true)),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text('Date: ${dateFmt.format(invoice.issueDate)}', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
                    pw.SizedBox(height: 14),
                    pw.Container(
                      color: _maroon,
                      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      child: pw.Row(
                        children: [
                          _redTh('Description', flex: 4),
                          _redTh('Qty', flex: 1, center: true),
                          _redTh('Price', flex: 2, center: true),
                          _redTh('Total', flex: 2, right: true),
                        ],
                      ),
                    ),
                    for (final item in invoice.items)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _maroon, width: 0.6))),
                        child: pw.Row(
                          children: [
                            _redTd(item.description, flex: 4),
                            _redTd(item.quantity % 1 == 0 ? '${item.quantity.toInt()}' : '${item.quantity}', flex: 1, center: true),
                            _redTd(money.format(item.unitPrice), flex: 2, center: true),
                            _redTd(money.format(item.lineTotal), flex: 2, right: true),
                          ],
                        ),
                      ),
                    if (showTax)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 6),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            'Subtotal: ${money.format(invoice.subtotal)} · Tax: ${money.format(invoice.totalTax)}',
                            style: const pw.TextStyle(fontSize: 9, color: _muted),
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Spacer(flex: 5),
                        pw.Expanded(
                          flex: 4,
                          child: pw.Container(
                            color: _black,
                            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(showTax ? 'Grand Total' : 'Sub Total', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                                pw.Text(money.format(totalDue), style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.Spacer(),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Payment Information:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                              pw.SizedBox(height: 4),
                              if (invoice.seller.phone.isNotEmpty) pw.Text('Phone: ${invoice.seller.phone}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
                              if (invoice.seller.email.isNotEmpty) pw.Text('Email: ${invoice.seller.email}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
                              if (invoice.termsAndConditions.isNotEmpty)
                                pw.Text('Terms: ${invoice.termsAndConditions}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
                            ],
                          ),
                        ),
                        pw.Text('Thank You!', style: pw.TextStyle(fontSize: 28, fontStyle: pw.FontStyle.italic)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pw.Container(height: 10, color: _black),
          ],
        ),
      ),
    );
    return doc;
  }

  static pw.Widget _redParty(String label, DigitalParty p, {bool alignRight = false}) {
    final align = alignRight ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    return pw.Column(
      crossAxisAlignment: align,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(p.name, style: const pw.TextStyle(fontSize: 9, color: _muted)),
        if (p.phone.isNotEmpty) pw.Text(p.phone, style: const pw.TextStyle(fontSize: 9, color: _muted)),
        if (p.fullAddress.isNotEmpty) pw.Text(p.fullAddress, style: const pw.TextStyle(fontSize: 9, color: _muted)),
      ],
    );
  }

  static pw.Widget _redTh(String text, {required int flex, bool center = false, bool right = false}) {
    final align = center ? pw.TextAlign.center : (right ? pw.TextAlign.right : pw.TextAlign.left);
    return pw.Expanded(
      flex: flex,
      child: pw.Text(text, textAlign: align, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
    );
  }

  static Future<pw.Document> _buildOrangeReceipt(DigitalInvoice invoice) async {
    final doc = pw.Document();
    final money = NumberFormat.currency(locale: invoice.locale, symbol: invoice.currencySymbol, decimalDigits: 2);
    final dateFmt = DateFormat.yMMMMd(invoice.locale);
    final companyParts = invoice.seller.name.trim().split(RegExp(r'\s+'));
    final line1 = companyParts.isNotEmpty ? companyParts.first.toUpperCase() : invoice.seller.name;
    final line2 = companyParts.length > 1 ? companyParts.sublist(1).join(' ').toUpperCase() : '';
    final status = invoice.status.label.toUpperCase();
    final notes = invoice.notes.isNotEmpty ? invoice.notes : 'Thank you for your payment and trust in our company.';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(height: 40, color: _receiptNavy),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(line1, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    if (line2.isNotEmpty)
                      pw.Text(line2, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: _receiptOrange)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Date: ${dateFmt.format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Customer: ${invoice.buyer.name}', style: const pw.TextStyle(fontSize: 9)),
                  if (invoice.buyer.fullAddress.isNotEmpty)
                    pw.Text('Address: ${invoice.buyer.fullAddress}', style: const pw.TextStyle(fontSize: 9)),
                  if (invoice.buyer.phone.isNotEmpty)
                    pw.Text('Phone: ${invoice.buyer.phone}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500)),
              child: pw.Column(
                children: [
                  pw.Container(
                    color: _receiptOrange,
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Row(
                      children: [
                        _redTh('#', flex: 1),
                        _redTh('Description', flex: 4),
                        _redTh('Qty', flex: 1, center: true),
                        _redTh('Price', flex: 2, center: true),
                        _redTh('Total', flex: 2, right: true),
                      ],
                    ),
                  ),
                  for (var i = 0; i < invoice.items.length; i++)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Row(
                        children: [
                          _redTd('${i + 1}', flex: 1),
                          _redTd(invoice.items[i].description, flex: 4),
                          _redTd(
                            invoice.items[i].quantity % 1 == 0
                                ? '${invoice.items[i].quantity.toInt()}'
                                : '${invoice.items[i].quantity}',
                            flex: 1,
                            center: true,
                          ),
                          _redTd(money.format(invoice.items[i].unitPrice), flex: 2, center: true),
                          _redTd(money.format(invoice.items[i].lineTotal), flex: 2, right: true),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(child: pw.Text('Payment Status: $status', style: const pw.TextStyle(fontSize: 9))),
                pw.Expanded(child: pw.Text('Total Payment: ${money.format(invoice.grandTotal)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('NOTES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Text(notes, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Container(height: 24, color: _receiptOrange),
          ],
        ),
      ),
    );
    return doc;
  }

  static pw.Widget _corpTh(String text, {required int flex, bool center = false, bool right = false}) {
    final align = center ? pw.TextAlign.center : (right ? pw.TextAlign.right : pw.TextAlign.left);
    return pw.Expanded(
      flex: flex,
      child: pw.Text(text, textAlign: align, style: pw.TextStyle(color: _corpNavy, fontSize: 9, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _redTd(String text, {required int flex, bool center = false, bool right = false}) {
    final align = center ? pw.TextAlign.center : (right ? pw.TextAlign.right : pw.TextAlign.left);
    return pw.Expanded(
      flex: flex,
      child: pw.Text(text, textAlign: align, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static Future<pw.Document> _buildBlueYellow(DigitalInvoice invoice) async {
    final doc = pw.Document();
    final money = NumberFormat.currency(locale: invoice.locale, symbol: invoice.currencySymbol, decimalDigits: 2);
    final dateFmt = DateFormat.yMMMMd(invoice.locale);
    final companyParts = invoice.seller.name.trim().split(RegExp(r'\s+'));
    final line1 = companyParts.isNotEmpty ? companyParts.first.toUpperCase() : invoice.seller.name;
    final line2 = companyParts.length > 1 ? companyParts.sublist(1).join(' ').toUpperCase() : '';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(height: 48, color: _geoNavy),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(line1, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    if (line2.isNotEmpty) pw.Text(line2, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ],
                ),
                pw.SizedBox(width: 8),
                pw.Container(width: 28, height: 28, color: _geoGold),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text('Invoice Number: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Date: ${dateFmt.format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _redParty('BILL TO:', invoice.buyer)),
                pw.Expanded(child: _redParty('PAYMENT INFORMATION:', invoice.seller, alignRight: true)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _geoNavy)),
              child: pw.Column(
                children: [
                  pw.Container(
                    color: _geoNavy,
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Row(
                      children: [
                        _redTh('#', flex: 1),
                        _redTh('Description', flex: 5),
                        _redTh('Rate', flex: 2, center: true),
                        _redTh('Amount', flex: 2, right: true),
                      ],
                    ),
                  ),
                  for (var i = 0; i < invoice.items.length; i++)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Row(
                        children: [
                          _redTd('${i + 1}.', flex: 1),
                          _redTd(invoice.items[i].description, flex: 5),
                          _redTd(money.format(invoice.items[i].unitPrice), flex: 2, center: true),
                          _redTd(money.format(invoice.items[i].lineTotal), flex: 2, right: true),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 200,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Sub Total:', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text(money.format(invoice.subtotal), style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    if (invoice.totalTax > 0.01)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Tax:', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(money.format(invoice.totalTax), style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 200,
                padding: const pw.EdgeInsets.all(8),
                color: _geoNavy,
                child: pw.Text(
                  'TOTAL: ${money.format(invoice.grandTotal)}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            if (invoice.termsAndConditions.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text('TERMS AND CONDITIONS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(invoice.termsAndConditions, style: const pw.TextStyle(fontSize: 9)),
            ],
            pw.Spacer(),
            pw.Container(height: 36, color: _geoNavy),
          ],
        ),
      ),
    );
    return doc;
  }

  static Future<pw.Document> _buildBlueCorporate(DigitalInvoice invoice) async {
    final doc = pw.Document();
    final money = NumberFormat.currency(locale: invoice.locale, symbol: invoice.currencySymbol, decimalDigits: 2);
    final dateFmt = DateFormat.yMMMMd(invoice.locale);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Stack(
              children: [
                pw.Container(height: 100, color: _corpTeal),
                pw.Container(height: 70, width: 280, color: _corpNavy),
                pw.Positioned(
                  left: 0,
                  bottom: 8,
                  child: pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: _corpNavy)),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Invoice No: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Issue Date: ${dateFmt.format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Due Date: ${dateFmt.format(invoice.dueDate)}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Currency: ${invoice.currencyCode}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.Expanded(child: _redParty('CLIENT DETAIL', invoice.buyer)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _corpNavy, width: 1.2)),
              ),
              child: pw.Row(
                children: [
                  _corpTh('Service', flex: 4),
                  _corpTh('Qty', flex: 1, center: true),
                  _corpTh('Unit', flex: 2, center: true),
                  _corpTh('Price', flex: 2, center: true),
                  _corpTh('Total', flex: 2, right: true),
                ],
              ),
            ),
            for (final item in invoice.items)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Row(
                  children: [
                    _redTd(item.description, flex: 4),
                    _redTd(item.quantity % 1 == 0 ? '${item.quantity.toInt()}' : '${item.quantity}', flex: 1, center: true),
                    _redTd('ea', flex: 2, center: true),
                    _redTd(money.format(item.unitPrice), flex: 2, center: true),
                    _redTd(money.format(item.lineTotal), flex: 2, right: true),
                  ],
                ),
              ),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Subtotal: ${money.format(invoice.subtotal)}', style: const pw.TextStyle(fontSize: 9)),
                      if (invoice.totalTax > 0.01)
                        pw.Text('Tax: ${money.format(invoice.totalTax)}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Grand Total: ${money.format(invoice.grandTotal)}',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (invoice.seller.email.isNotEmpty)
                        pw.Text('Email: ${invoice.seller.email}', style: const pw.TextStyle(fontSize: 9)),
                      if (invoice.seller.phone.isNotEmpty)
                        pw.Text('Phone: ${invoice.seller.phone}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
            if (invoice.termsAndConditions.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('Terms & Conditions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('• ${invoice.termsAndConditions}', style: const pw.TextStyle(fontSize: 9)),
            ],
          ],
        ),
      ),
    );
    return doc;
  }

  static pw.Widget _pdfParty(String title, DigitalParty p, PdfColor accent) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 9, color: accent, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 3),
        pw.Text(p.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        if (p.fullAddress.isNotEmpty) pw.Text(p.fullAddress, style: const pw.TextStyle(fontSize: 9)),
        if (p.email.isNotEmpty) pw.Text(p.email, style: const pw.TextStyle(fontSize: 9)),
        if (p.taxId.isNotEmpty) pw.Text('${p.taxIdLabel}: ${p.taxId}', style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            textAlign: align, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, textAlign: align, style: const pw.TextStyle(fontSize: 9)),
      );

  static pw.Widget _totalRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
            pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      );
}
