import 'client.dart';
import 'invoice_item.dart';
import 'invoice_template.dart';

enum InvoiceStatus { paid, unpaid, overdue, partiallyPaid }

enum DocumentKind { invoice, estimate }

enum EstimateStatus { draft, sent, accepted, declined }

enum Recurrence { none, weekly, monthly, custom }

class Invoice {
  final String id;
  final String number;
  final Client client;
  final List<InvoiceItem> items;
  final DateTime date;
  final DateTime? dueDate;
  final String currency;
  final InvoiceStatus status;
  final double taxRate;
  final String? paymentTerms;
  final String? poNumber;
  final String? notes;
  final String templateId;
  final double amountPaid;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DocumentKind kind;
  final EstimateStatus estimateStatus;
  final double discountValue;
  final bool discountIsPercent;
  final double shipping;
  final double deposit;
  final bool taxInclusive;
  final Recurrence recurrence;
  final int recurrenceEveryDays;
  final DateTime? recurrenceStart;
  final DateTime? recurrenceEnd;
  final DateTime? nextOccurrence;
  final bool recurrenceActive;
  final DateTime? serviceStart;
  final DateTime? serviceEnd;

  Invoice({
    required this.id,
    required this.number,
    required this.client,
    required this.items,
    required this.date,
    this.dueDate,
    this.currency = 'USD',
    this.status = InvoiceStatus.unpaid,
    this.taxRate = 0,
    this.paymentTerms,
    this.poNumber,
    this.notes,
    this.templateId = 'classic',
    this.amountPaid = 0,
    this.paymentMethod,
    this.paidAt,
    this.kind = DocumentKind.invoice,
    this.estimateStatus = EstimateStatus.draft,
    this.discountValue = 0,
    this.discountIsPercent = true,
    this.shipping = 0,
    this.deposit = 0,
    this.taxInclusive = false,
    this.recurrence = Recurrence.none,
    this.recurrenceEveryDays = 30,
    this.recurrenceStart,
    this.recurrenceEnd,
    this.nextOccurrence,
    this.recurrenceActive = false,
    this.serviceStart,
    this.serviceEnd,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get discountAmount {
    if (discountValue <= 0 || subtotal <= 0) return 0;
    final raw = discountIsPercent ? subtotal * (discountValue / 100) : discountValue;
    return raw > subtotal ? subtotal : raw;
  }

  double get taxableBase {
    final base = subtotal - discountAmount;
    return base < 0 ? 0 : base;
  }

  bool get usesItemTax => taxRate <= 0 && items.any((item) => item.taxRate > 0);

  double get taxAmount {
    if (usesItemTax) {
      if (subtotal <= 0) return 0;
      final ratio = taxableBase / subtotal;
      var tax = 0.0;
      for (final item in items) {
        if (item.taxRate <= 0) continue;
        final line = item.total * ratio;
        if (taxInclusive) {
          tax += line - line / (1 + item.taxRate / 100);
        } else {
          tax += line * (item.taxRate / 100);
        }
      }
      return tax;
    }
    if (taxRate <= 0 || taxableBase <= 0) return 0;
    if (taxInclusive) {
      return taxableBase - taxableBase / (1 + taxRate / 100);
    }
    return taxableBase * (taxRate / 100);
  }

  double get total {
    final goods = taxInclusive ? taxableBase : taxableBase + taxAmount;
    return goods + shipping;
  }

  double get balanceDue {
    final left = total - deposit - amountPaid;
    return left < 0 ? 0 : left;
  }

  bool get isFullyPaid => status == InvoiceStatus.paid || (total > 0 && amountPaid + deposit + 0.009 >= total);

  bool get isEstimate => kind == DocumentKind.estimate;

  InvoiceTemplateId get template => InvoiceTemplateIdStorage.fromStorage(templateId);

  InvoiceStatus get displayStatus {
    if (isEstimate) return status;
    if (isFullyPaid) return InvoiceStatus.paid;
    final deadline = dueDate ?? date.add(const Duration(days: 14));
    final today = DateTime.now();
    final end = DateTime(deadline.year, deadline.month, deadline.day);
    final now = DateTime(today.year, today.month, today.day);
    if (now.isAfter(end)) return InvoiceStatus.overdue;
    if (amountPaid > 0.009 || deposit > 0.009) return InvoiceStatus.partiallyPaid;
    return InvoiceStatus.unpaid;
  }

  static DateTime advance(Recurrence recurrence, DateTime from, int everyDays) {
    switch (recurrence) {
      case Recurrence.weekly:
        return from.add(const Duration(days: 7));
      case Recurrence.monthly:
        return DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
      case Recurrence.custom:
        final days = everyDays < 1 ? 1 : everyDays;
        return from.add(Duration(days: days));
      case Recurrence.none:
        return from;
    }
  }

  Invoice copyWith({
    String? id,
    String? number,
    Client? client,
    List<InvoiceItem>? items,
    DateTime? date,
    DateTime? dueDate,
    String? currency,
    InvoiceStatus? status,
    double? taxRate,
    String? paymentTerms,
    String? poNumber,
    String? notes,
    String? templateId,
    double? amountPaid,
    String? paymentMethod,
    DateTime? paidAt,
    DocumentKind? kind,
    EstimateStatus? estimateStatus,
    double? discountValue,
    bool? discountIsPercent,
    double? shipping,
    double? deposit,
    bool? taxInclusive,
    Recurrence? recurrence,
    int? recurrenceEveryDays,
    DateTime? recurrenceStart,
    DateTime? recurrenceEnd,
    bool clearRecurrenceEnd = false,
    DateTime? nextOccurrence,
    bool? recurrenceActive,
    DateTime? serviceStart,
    DateTime? serviceEnd,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      client: client ?? this.client,
      items: items ?? this.items,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      taxRate: taxRate ?? this.taxRate,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      poNumber: poNumber ?? this.poNumber,
      notes: notes ?? this.notes,
      templateId: templateId ?? this.templateId,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      kind: kind ?? this.kind,
      estimateStatus: estimateStatus ?? this.estimateStatus,
      discountValue: discountValue ?? this.discountValue,
      discountIsPercent: discountIsPercent ?? this.discountIsPercent,
      shipping: shipping ?? this.shipping,
      deposit: deposit ?? this.deposit,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEveryDays: recurrenceEveryDays ?? this.recurrenceEveryDays,
      recurrenceStart: recurrenceStart ?? this.recurrenceStart,
      recurrenceEnd: clearRecurrenceEnd ? null : (recurrenceEnd ?? this.recurrenceEnd),
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      recurrenceActive: recurrenceActive ?? this.recurrenceActive,
      serviceStart: serviceStart ?? this.serviceStart,
      serviceEnd: serviceEnd ?? this.serviceEnd,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'client': client.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'date': date.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'currency': currency,
        'status': status.name,
        'taxRate': taxRate,
        'paymentTerms': paymentTerms,
        'poNumber': poNumber,
        'notes': notes,
        'templateId': templateId,
        'amountPaid': amountPaid,
        'paymentMethod': paymentMethod,
        'paidAt': paidAt?.toIso8601String(),
        'kind': kind.name,
        'estimateStatus': estimateStatus.name,
        'discountValue': discountValue,
        'discountIsPercent': discountIsPercent,
        'shipping': shipping,
        'deposit': deposit,
        'taxInclusive': taxInclusive,
        'recurrence': recurrence.name,
        'recurrenceEveryDays': recurrenceEveryDays,
        'recurrenceStart': recurrenceStart?.toIso8601String(),
        'recurrenceEnd': recurrenceEnd?.toIso8601String(),
        'nextOccurrence': nextOccurrence?.toIso8601String(),
        'recurrenceActive': recurrenceActive,
        'serviceStart': serviceStart?.toIso8601String(),
        'serviceEnd': serviceEnd?.toIso8601String(),
      };

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      number: json['number'] as String? ?? '',
      client: Client.fromJson(Map<String, dynamic>.from(json['client'] as Map)),
      items: (json['items'] as List? ?? [])
          .map((e) => InvoiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'] as String) : null,
      currency: json['currency'] as String? ?? 'USD',
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => InvoiceStatus.unpaid,
      ),
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
      paymentTerms: json['paymentTerms'] as String?,
      poNumber: json['poNumber'] as String?,
      notes: json['notes'] as String?,
      templateId: json['templateId'] as String? ?? 'classic',
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String?,
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'] as String) : null,
      kind: DocumentKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => DocumentKind.invoice,
      ),
      estimateStatus: EstimateStatus.values.firstWhere(
        (value) => value.name == json['estimateStatus'],
        orElse: () => EstimateStatus.draft,
      ),
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      discountIsPercent: json['discountIsPercent'] as bool? ?? true,
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
      deposit: (json['deposit'] as num?)?.toDouble() ?? 0,
      taxInclusive: json['taxInclusive'] as bool? ?? false,
      recurrence: Recurrence.values.firstWhere(
        (value) => value.name == json['recurrence'],
        orElse: () => Recurrence.none,
      ),
      recurrenceEveryDays: (json['recurrenceEveryDays'] as num?)?.toInt() ?? 30,
      recurrenceStart: json['recurrenceStart'] != null ? DateTime.tryParse(json['recurrenceStart'] as String) : null,
      recurrenceEnd: json['recurrenceEnd'] != null ? DateTime.tryParse(json['recurrenceEnd'] as String) : null,
      nextOccurrence: json['nextOccurrence'] != null ? DateTime.tryParse(json['nextOccurrence'] as String) : null,
      recurrenceActive: json['recurrenceActive'] as bool? ?? false,
      serviceStart: json['serviceStart'] != null ? DateTime.tryParse(json['serviceStart'] as String) : null,
      serviceEnd: json['serviceEnd'] != null ? DateTime.tryParse(json['serviceEnd'] as String) : null,
    );
  }
}
