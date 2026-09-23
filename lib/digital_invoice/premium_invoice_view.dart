import 'package:flutter/material.dart';

import '../models/invoice.dart';
import '../models/invoice_template.dart';
import '../providers/invoice_provider.dart';
import 'digital_invoice_mapper.dart';
import 'digital_invoice_widget.dart';
import 'invoice_gradient_theme.dart';
import 'invoice_typography.dart';

/// Renders a Pro gradient template using the international digital invoice layout.
class PremiumInvoiceView extends StatelessWidget {
  const PremiumInvoiceView({
    super.key,
    required this.invoice,
    required this.provider,
    this.templateId,
  });

  final Invoice invoice;
  final InvoiceProvider provider;

  /// When previewing a template before it is applied to [invoice].
  final InvoiceTemplateId? templateId;

  @override
  Widget build(BuildContext context) {
    final id = templateId ?? invoice.template;
    final gradient = InvoiceThemes.forTemplate(id);
    final digital = DigitalInvoiceMapper.fromAppInvoice(invoice, provider);

    return LayoutBuilder(
      builder: (context, _) {
        return Theme(
          data: InvoiceTypography.appTheme(gradient, context, templateId: id),
          child: DigitalInvoiceWidget(invoice: digital, theme: gradient),
        );
      },
    );
  }
}
