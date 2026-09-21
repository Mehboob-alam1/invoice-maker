import 'client.dart';
import 'invoice_item.dart';

enum InvoiceStatus { paid, unpaid, overdue }

class Invoice {
  final String id;
  final String number;
  final Client client;
  final List<InvoiceItem> items;
  final DateTime date;
  final String currency;
  final InvoiceStatus status;

  Invoice({
    required this.id,
    required this.number,
    required this.client,
    required this.items,
    required this.date,
    this.currency = 'USD',
    this.status = InvoiceStatus.unpaid,
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);

  InvoiceStatus get displayStatus {
    if (status == InvoiceStatus.paid) return InvoiceStatus.paid;
    if (DateTime.now().difference(date).inDays > 14) return InvoiceStatus.overdue;
    return InvoiceStatus.unpaid;
  }

  Invoice copyWith({
    String? id,
    String? number,
    Client? client,
    List<InvoiceItem>? items,
    DateTime? date,
    String? currency,
    InvoiceStatus? status,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      client: client ?? this.client,
      items: items ?? this.items,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'client': client.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'date': date.toIso8601String(),
        'currency': currency,
        'status': status.name,
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
      currency: json['currency'] as String? ?? 'USD',
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => InvoiceStatus.unpaid,
      ),
    );
  }
}
