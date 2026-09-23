import 'client.dart';
import 'invoice_item.dart';
import 'invoice_template.dart';

enum InvoiceStatus { paid, unpaid, overdue }

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
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get taxAmount => subtotal * (taxRate / 100);

  double get total => subtotal + taxAmount;

  InvoiceTemplateId get template => InvoiceTemplateIdStorage.fromStorage(templateId);

  InvoiceStatus get displayStatus {
    if (status == InvoiceStatus.paid) return InvoiceStatus.paid;
    final deadline = dueDate ?? date.add(const Duration(days: 14));
    final today = DateTime.now();
    final end = DateTime(deadline.year, deadline.month, deadline.day);
    final now = DateTime(today.year, today.month, today.day);
    if (now.isAfter(end)) return InvoiceStatus.overdue;
    return InvoiceStatus.unpaid;
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
    );
  }
}
