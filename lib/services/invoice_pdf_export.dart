import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../digital_invoice/digital_invoice_mapper.dart';
import '../digital_invoice/digital_invoice_model.dart';
import '../digital_invoice/invoice_gradient_theme.dart';
import '../digital_invoice/invoice_pdf_service.dart';
import '../models/invoice.dart';
import '../models/invoice_template.dart';
import '../providers/invoice_provider.dart';
import '../widgets/invoice_template_preview_sheet.dart';

class InvoicePdfExport {
  InvoicePdfExport._();

  static Future<void> export(
    BuildContext context,
    Invoice invoice, {
    required bool share,
  }) async {
    final provider = context.read<InvoiceProvider>();
    if (!InvoiceTemplateInfo.canUseTemplate(invoice.template, provider.subscriptionTier)) {
      final ok = await confirmProTemplateUse(context, invoice.template);
      if (!ok || !context.mounted) return;
    }
    final digital = DigitalInvoiceMapper.fromAppInvoice(invoice, provider);
    switch (invoice.template) {
      case InvoiceTemplateId.redModern:
        if (share) {
          await InvoicePdfService.shareRedModernPdf(digital);
        } else {
          await InvoicePdfService.printRedModernPdf(digital);
        }
        return;
      case InvoiceTemplateId.blueYellow:
        if (share) {
          await InvoicePdfService.shareBlueYellowPdf(digital);
        } else {
          await InvoicePdfService.printBlueYellowPdf(digital);
        }
        return;
      case InvoiceTemplateId.blueCorporate:
        if (share) {
          await InvoicePdfService.shareBlueCorporatePdf(digital);
        } else {
          await InvoicePdfService.printBlueCorporatePdf(digital);
        }
        return;
      case InvoiceTemplateId.orangeReceipt:
        if (share) {
          await InvoicePdfService.shareOrangeReceiptPdf(digital);
        } else {
          await InvoicePdfService.printOrangeReceiptPdf(digital);
        }
        return;
      case InvoiceTemplateId.classic:
        await _exportLayout(digital, share: share, layout: InvoicePdfLayout.classic, theme: InvoiceThemes.classic);
        return;
      case InvoiceTemplateId.modern:
        await _exportLayout(digital, share: share, layout: InvoicePdfLayout.modern, theme: InvoiceThemes.classic);
        return;
      case InvoiceTemplateId.minimal:
        await _exportLayout(digital, share: share, layout: InvoicePdfLayout.minimal, theme: InvoiceThemes.classic);
        return;
      case InvoiceTemplateId.aurora:
      case InvoiceTemplateId.sunset:
      case InvoiceTemplateId.ocean:
      case InvoiceTemplateId.emerald:
      case InvoiceTemplateId.royal:
      case InvoiceTemplateId.rose:
      case InvoiceTemplateId.midnight:
        final theme = InvoiceThemes.forTemplate(invoice.template);
        await _exportLayout(digital, share: share, layout: InvoicePdfLayout.digital, theme: theme);
        return;
    }
  }

  static Future<void> _exportLayout(
    DigitalInvoice digital, {
    required bool share,
    required InvoicePdfLayout layout,
    required InvoiceGradientTheme theme,
  }) async {
    if (share) {
      await InvoicePdfService.sharePdf(digital, theme: theme, layout: layout);
    } else {
      await InvoicePdfService.printDocument(digital, theme: theme, layout: layout);
    }
  }
}
