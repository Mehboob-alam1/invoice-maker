import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/currency_format.dart';
import '../l10n/app_strings.dart';
import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import 'engagement_service.dart';
import 'invoice_pdf_export.dart';

/// Builds a reminder and shares the invoice PDF. The app never sends the message itself.
class InvoiceSend {
  InvoiceSend._();

  static String message(BuildContext context, Invoice invoice) {
    final provider = context.read<InvoiceProvider>();
    final strings = AppStrings.read(context);
    final amount = CurrencyFormat.format(invoice.currency, invoice.balanceDue > 0.009 ? invoice.balanceDue : invoice.total);
    final due = invoice.dueDate == null
        ? ''
        : DateFormat.yMMMd(provider.languageCode).format(invoice.dueDate!);
    final pay = _howToPay(provider);
    return strings.invoiceReminderBody(
      client: invoice.client.name,
      number: invoice.number,
      amount: amount,
      due: due.isEmpty ? strings.dueDate : due,
      pay: pay,
    );
  }

  static String _howToPay(InvoiceProvider provider) {
    final lines = <String>[
      if (provider.bankName.trim().isNotEmpty) provider.bankName.trim(),
      if (provider.iban.trim().isNotEmpty) provider.iban.trim(),
      if (provider.wallet.trim().isNotEmpty) provider.wallet.trim(),
      if (provider.paymentLink.trim().isNotEmpty) provider.paymentLink.trim(),
      if (provider.paymentNote.trim().isNotEmpty) provider.paymentNote.trim(),
    ];
    return lines.join(' · ');
  }

  static Future<void> sharePdfWithMessage(BuildContext context, Invoice invoice) async {
    try {
      final bytes = await InvoicePdfExport.bytes(context, invoice);
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: InvoicePdfExport.filename(invoice),
            ),
          ],
          text: message(context, invoice),
          subject: invoice.number,
        ),
      );
      if (context.mounted) await EngagementService.instance.afterShare(context);
    } catch (error, stack) {
      debugPrint('Invoice send failed: $error\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.read(context).pdfExportFailed)),
        );
      }
    }
  }

  static Future<void> shareImage(BuildContext context, Invoice invoice) async {
    try {
      final bytes = await InvoicePdfExport.bytes(context, invoice);
      if (!context.mounted) return;
      final page = await Printing.raster(bytes, pages: const [0], dpi: 120).first;
      final png = await page.toPng();
      final name = InvoicePdfExport.filename(invoice).replaceAll(RegExp(r'\.pdf$'), '.png');
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(png, mimeType: 'image/png', name: name),
          ],
        ),
      );
      if (context.mounted) await EngagementService.instance.afterShare(context);
    } catch (error, stack) {
      debugPrint('Invoice image share failed: $error\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.read(context).pdfExportFailed)),
        );
      }
    }
  }

  static Future<void> sms(BuildContext context, Invoice invoice) async {
    final phone = (invoice.client.phone ?? '').replaceAll(RegExp(r'[^\d+]'), '');
    final body = message(context, invoice);
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': body},
    );
    final opened = await launchUrl(uri);
    if (opened && context.mounted) {
      await EngagementService.instance.afterShare(context);
      return;
    }
    if (!opened && context.mounted) {
      await sharePdfWithMessage(context, invoice);
    }
  }
}
