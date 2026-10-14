import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../digital_invoice/digital_invoice_mapper.dart';
import '../digital_invoice/invoice_gradient_theme.dart';
import '../digital_invoice/invoice_pdf_service.dart';
import '../l10n/app_strings.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import 'engagement_service.dart';

class InvoicePdfExport {
  InvoicePdfExport._();

  static Future<Uint8List> bytes(BuildContext context, Invoice invoice) async {
    final provider = context.read<InvoiceProvider>();
    final digital = DigitalInvoiceMapper.fromAppInvoice(invoice, provider);
    return InvoicePdfService.templateBytes(
      digital,
      templateId: invoice.template.name,
      theme: InvoiceThemes.forTemplate(invoice.template),
    );
  }

  static String filename(Invoice invoice) {
    final raw = invoice.number.replaceAll('#', '').replaceAll('/', '-').trim();
    final name = raw.isEmpty ? 'invoice' : 'Invoice-$raw';
    return name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';
  }

  static Future<void> export(
    BuildContext context,
    Invoice invoice, {
    required bool share,
  }) async {
    try {
      final data = await bytes(context, invoice);
      if (share) {
        await Printing.sharePdf(bytes: data, filename: filename(invoice));
        if (context.mounted) await EngagementService.instance.afterShare(context);
      } else {
        await Printing.layoutPdf(onLayout: (_) async => data);
      }
    } catch (error, stack) {
      debugPrint('PDF export failed: $error\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.read(context).pdfExportFailed)),
        );
      }
    }
  }
}
