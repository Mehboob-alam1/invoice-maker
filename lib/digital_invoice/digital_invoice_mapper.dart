import '../core/constants/app_texts.dart';
import '../core/utils/currency_format.dart';
import '../models/invoice.dart' as app;
import '../providers/invoice_provider.dart';
import 'digital_invoice_model.dart';

class DigitalInvoiceMapper {
  DigitalInvoiceMapper._();

  static String _localeFromCode(String code) {
    switch (code) {
      case 'es':
        return 'es_ES';
      case 'fr':
        return 'fr_FR';
      case 'de':
        return 'de_DE';
      case 'ar':
        return 'ar_AE';
      case 'ur':
        return 'ur_PK';
      case 'hi':
        return 'hi_IN';
      case 'zh':
        return 'zh_CN';
      default:
        return 'en_US';
    }
  }

  static DigitalPaymentStatus _mapStatus(app.Invoice invoice) {
    switch (invoice.displayStatus) {
      case app.InvoiceStatus.paid:
        return DigitalPaymentStatus.paid;
      case app.InvoiceStatus.overdue:
        return DigitalPaymentStatus.overdue;
      case app.InvoiceStatus.unpaid:
        return DigitalPaymentStatus.sent;
    }
  }

  static DigitalInvoice fromAppInvoice(app.Invoice invoice, InvoiceProvider provider) {
    final sellerName = provider.businessName.isEmpty ? AppTexts.defaultBusinessName : provider.businessName;
    final addressParts = provider.businessAddress.split('\n');
    final clientAddress = invoice.client.address ?? '';

    return DigitalInvoice(
      invoiceNumber: invoice.number,
      purchaseOrderNumber: invoice.poNumber ?? '',
      issueDate: invoice.date,
      dueDate: invoice.dueDate ?? invoice.date.add(const Duration(days: 30)),
      currencyCode: invoice.currency,
      currencySymbol: CurrencyFormat.symbol(invoice.currency).trim(),
      locale: _localeFromCode(provider.languageCode),
      notes: invoice.notes ?? '',
      termsAndConditions: invoice.paymentTerms ??
          'Payment due within the terms stated above. Late payments may incur additional charges.',
      status: _mapStatus(invoice),
      seller: DigitalParty(
        name: sellerName,
        addressLine1: addressParts.isNotEmpty ? addressParts.first : provider.businessAddress,
        addressLine2: addressParts.length > 1 ? addressParts.sublist(1).join(', ') : '',
        email: provider.businessEmail,
        phone: provider.businessPhone,
        taxId: provider.businessTaxId,
        taxIdLabel: 'Tax ID',
      ),
      buyer: DigitalParty(
        name: invoice.client.name,
        addressLine1: clientAddress.split('\n').firstOrNull ?? clientAddress,
        addressLine2: clientAddress.contains('\n') ? clientAddress.split('\n').skip(1).join(', ') : '',
        email: invoice.client.email ?? '',
        phone: invoice.client.phone ?? '',
        taxId: invoice.client.taxId ?? '',
        taxIdLabel: 'Tax ID',
      ),
      invoiceTaxRatePercent: invoice.taxRate,
      items: invoice.items
          .map(
            (item) => DigitalLineItem(
              description: item.description,
              quantity: item.quantity.toDouble(),
              unitPrice: item.unitCost,
            ),
          )
          .toList(),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
