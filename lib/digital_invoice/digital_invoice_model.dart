enum DigitalPaymentStatus { draft, sent, paid, overdue, cancelled }

extension DigitalPaymentStatusX on DigitalPaymentStatus {
  String get label {
    switch (this) {
      case DigitalPaymentStatus.draft:
        return 'Draft';
      case DigitalPaymentStatus.sent:
        return 'Sent';
      case DigitalPaymentStatus.paid:
        return 'Paid';
      case DigitalPaymentStatus.overdue:
        return 'Overdue';
      case DigitalPaymentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class DigitalParty {
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String country;
  final String email;
  final String phone;
  final String taxId;
  final String taxIdLabel;

  const DigitalParty({
    required this.name,
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.country = '',
    this.email = '',
    this.phone = '',
    this.taxId = '',
    this.taxIdLabel = 'VAT No.',
  });

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ];
    return parts.where((p) => p.trim().isNotEmpty).join(', ');
  }
}

class DigitalBankDetails {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String iban;
  final String swiftBic;

  const DigitalBankDetails({
    this.bankName = '',
    this.accountName = '',
    this.accountNumber = '',
    this.iban = '',
    this.swiftBic = '',
  });

  bool get isEmpty =>
      bankName.isEmpty && accountName.isEmpty && accountNumber.isEmpty && iban.isEmpty && swiftBic.isEmpty;
}

class DigitalLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double taxRatePercent;
  final double discountPercent;

  const DigitalLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.taxRatePercent = 0,
    this.discountPercent = 0,
  });

  double get grossAmount => quantity * unitPrice;
  double get discountAmount => grossAmount * (discountPercent / 100);
  double get netAmount => grossAmount - discountAmount;
  double get taxAmount => netAmount * (taxRatePercent / 100);
  double get lineTotal => netAmount + taxAmount;
}

class TaxBreakdownEntry {
  final double ratePercent;
  final double taxableAmount;
  final double taxAmount;

  const TaxBreakdownEntry({
    required this.ratePercent,
    required this.taxableAmount,
    required this.taxAmount,
  });
}

class DigitalInvoice {
  final String invoiceNumber;
  final String purchaseOrderNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final DigitalParty seller;
  final DigitalParty buyer;
  final List<DigitalLineItem> items;
  final String currencyCode;
  final String currencySymbol;
  final String locale;
  final double shippingCost;
  final double globalDiscountPercent;
  final DigitalBankDetails? bankDetails;
  final String notes;
  final String termsAndConditions;
  final DigitalPaymentStatus status;

  /// Invoice-level tax (matches [app.Invoice.taxRate]); line items stay pre-tax.
  final double invoiceTaxRatePercent;

  const DigitalInvoice({
    required this.invoiceNumber,
    this.purchaseOrderNumber = '',
    required this.issueDate,
    required this.dueDate,
    required this.seller,
    required this.buyer,
    required this.items,
    this.currencyCode = 'USD',
    this.currencySymbol = r'$',
    this.locale = 'en_US',
    this.shippingCost = 0,
    this.globalDiscountPercent = 0,
    this.bankDetails,
    this.notes = '',
    this.termsAndConditions = '',
    this.status = DigitalPaymentStatus.sent,
    this.invoiceTaxRatePercent = 0,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.netAmount);

  double get globalDiscountAmount => subtotal * (globalDiscountPercent / 100);

  double get taxableBase => subtotal - globalDiscountAmount;

  double get totalTax {
    if (invoiceTaxRatePercent > 0) {
      return taxableBase * (invoiceTaxRatePercent / 100);
    }
    return items.fold(0.0, (sum, item) => sum + item.taxAmount);
  }

  double get grandTotal => taxableBase + totalTax + shippingCost;

  List<TaxBreakdownEntry> get taxBreakdown {
    if (invoiceTaxRatePercent > 0) {
      return [
        TaxBreakdownEntry(
          ratePercent: invoiceTaxRatePercent,
          taxableAmount: taxableBase,
          taxAmount: totalTax,
        ),
      ];
    }
    final grouped = <double, List<double>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.taxRatePercent, () => [0, 0]);
      grouped[item.taxRatePercent]![0] += item.netAmount;
      grouped[item.taxRatePercent]![1] += item.taxAmount;
    }
    final entries = grouped.entries
        .map(
          (e) => TaxBreakdownEntry(
            ratePercent: e.key,
            taxableAmount: e.value[0],
            taxAmount: e.value[1],
          ),
        )
        .toList()
      ..sort((a, b) => a.ratePercent.compareTo(b.ratePercent));
    return entries;
  }
}
