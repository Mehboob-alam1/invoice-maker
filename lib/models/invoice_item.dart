class InvoiceItem {
  final String id;
  final String description;
  final String? notes;
  final double unitCost;
  final int quantity;

  InvoiceItem({
    required this.id,
    required this.description,
    this.notes,
    required this.unitCost,
    required this.quantity,
  });

  double get total => unitCost * quantity;

  InvoiceItem copyWith({
    String? id,
    String? description,
    String? notes,
    bool clearNotes = false,
    double? unitCost,
    int? quantity,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      description: description ?? this.description,
      notes: clearNotes ? null : (notes ?? this.notes),
      unitCost: unitCost ?? this.unitCost,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'notes': notes,
        'unitCost': unitCost,
        'quantity': quantity,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String?,
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
