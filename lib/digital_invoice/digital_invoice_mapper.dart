import 'dart:io';

import '../core/constants/app_config.dart';
import '../core/constants/app_texts.dart';
import '../core/remote_config/remote_config_repository.dart';
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
      case app.InvoiceStatus.partiallyPaid:
      case app.InvoiceStatus.unpaid:
        return DigitalPaymentStatus.sent;
    }
  }

  static List<int>? _bytes(String path) {
    if (path.isEmpty) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsBytesSync();
  }

  static DigitalInvoice fromAppInvoice(app.Invoice invoice, InvoiceProvider provider) {
    final sellerName = provider.businessName.isEmpty ? AppTexts.defaultBusinessName : provider.businessName;
    final addressParts = provider.businessAddress.split('\n');
    final clientAddress = invoice.client.address ?? '';

    return DigitalInvoice(
      invoiceNumber: invoice.number,
      purchaseOrderNumber: invoice.poNumber ?? '',
      issueDate: invoice.date,
      dueDate: invoice.dueDate ?? invoice.date.add(const Duration(days: 7)),
      currencyCode: invoice.currency,
      currencySymbol: CurrencyFormat.symbol(invoice.currency).trim(),
      locale: _localeFromCode(provider.languageCode),
      notes: invoice.notes ?? '',
      termsAndConditions: invoice.paymentTerms ??
          'Payment due within the terms stated above. Late payments may incur additional charges.',
      status: _mapStatus(invoice),
      amountPaid: invoice.amountPaid,
      howToPay: _howToPay(provider),
      bankDetails: _bank(provider),
      seller: DigitalParty(
        name: sellerName,
        addressLine1: addressParts.isNotEmpty ? addressParts.first : provider.businessAddress,
        addressLine2: addressParts.length > 1 ? addressParts.sublist(1).join(', ') : '',
        email: provider.businessEmail,
        phone: provider.businessPhone,
        taxId: provider.businessTaxId,
        taxIdLabel: provider.defaultTaxLabel.isEmpty ? 'Tax ID' : provider.defaultTaxLabel,
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
      shippingCost: invoice.shipping,
      globalDiscountPercent: invoice.subtotal <= 0 ? 0 : invoice.discountAmount / invoice.subtotal * 100,
      taxInclusive: invoice.taxInclusive,
      deposit: invoice.deposit,
      documentLabel: invoice.isEstimate ? 'ESTIMATE' : 'INVOICE',
      logoBytes: _bytes(provider.businessLogoPath),
      signatureBytes: _bytes(provider.signaturePath),
      stampBytes: provider.isPro ? _bytes(provider.stampPath) : null,
      watermark: _watermark(invoice, provider),
      watermarkUrl: AppConfig.playStoreUrl,
      items: invoice.items
          .map(
            (item) => DigitalLineItem(
              description: item.description,
              quantity: item.quantity.toDouble(),
              unitPrice: item.unitCost,
              taxRatePercent: invoice.taxRate > 0 ? 0 : item.taxRate,
            ),
          )
          .toList(),
    );
  }

  static String _watermark(app.Invoice invoice, InvoiceProvider provider) {
    if (provider.isPro) return '';
    if (!RemoteConfigRepository.instance.watermarkFooterFree) return '';
    if (provider.watermarkRemovedIds.contains(invoice.id)) return '';
    return AppTexts.watermarkFooter;
  }

  static DigitalBankDetails? _bank(InvoiceProvider provider) {
    final details = DigitalBankDetails(
      bankName: provider.bankName,
      accountName: provider.accountHolder,
      iban: provider.iban,
    );
    return details.isEmpty ? null : details;
  }

  static String _howToPay(InvoiceProvider provider) {
    final lines = <String>[
      if (provider.bankName.trim().isNotEmpty) 'Bank: ${provider.bankName.trim()}',
      if (provider.accountHolder.trim().isNotEmpty) 'Account name: ${provider.accountHolder.trim()}',
      if (provider.iban.trim().isNotEmpty) 'IBAN / account: ${provider.iban.trim()}',
      if (provider.wallet.trim().isNotEmpty) 'Wallet: ${provider.wallet.trim()}',
      if (provider.paymentLink.trim().isNotEmpty) 'Pay online: ${provider.paymentLink.trim()}',
      if (provider.paymentNote.trim().isNotEmpty) provider.paymentNote.trim(),
    ];
    return lines.join('\n');
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
