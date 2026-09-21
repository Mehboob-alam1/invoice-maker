import '../models/invoice_item.dart';

class ParsedInvoiceData {
  ParsedInvoiceData({
    this.clientName,
    this.email,
    this.phone,
    this.currency,
    List<InvoiceItem>? items,
    this.rawText = '',
    this.imagePath,
  }) : items = items ?? [];

  final String? clientName;
  final String? email;
  final String? phone;
  final String? currency;
  final List<InvoiceItem> items;
  final String rawText;
  final String? imagePath;
}

class InvoiceParser {
  InvoiceParser._();

  static final _emailRegex = RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false);
  static final _phoneRegex = RegExp(r'(?:\+?\d[\d\s().-]{7,}\d)');
  static final _moneyRegex = RegExp(
    r'(?:(USD|EUR|GBP|PKR|INR|Rs\.?|\$|€|£)\s*)(\d{1,3}(?:,\d{3})*(?:\.\d{2})?|\d+\.\d{2}|\d+)|(\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2})',
    caseSensitive: false,
  );
  static final _skipLine = RegExp(
    r'invoice|receipt|subtotal|total|tax|qty|quantity|date|bill to|ship to|thank',
    caseSensitive: false,
  );

  static ParsedInvoiceData parse(String rawText, {String? imagePath}) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? email;
    String? phone;
    String? currency;
    String? clientName;
    final items = <InvoiceItem>[];

    for (final line in lines) {
      email ??= _emailRegex.firstMatch(line)?.group(0);
      phone ??= _phoneRegex.firstMatch(line)?.group(0)?.trim();
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('bill to') ||
          lower.contains('client') ||
          lower.contains('sold to') ||
          lower.contains('customer')) {
        final afterColon = line.split(':');
        if (afterColon.length > 1 && afterColon.last.trim().isNotEmpty) {
          clientName = afterColon.last.trim();
        } else if (i + 1 < lines.length && !_skipLine.hasMatch(lines[i + 1])) {
          clientName = lines[i + 1];
        }
        break;
      }
    }

    final nameCandidates =
        lines.where((l) => !_skipLine.hasMatch(l) && !_moneyRegex.hasMatch(l) && l.length > 2);
    clientName ??= nameCandidates.isEmpty ? null : nameCandidates.first;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_skipLine.hasMatch(line) && !RegExp(r'(item|service|desc)', caseSensitive: false).hasMatch(line)) {
        final money = _moneyRegex.firstMatch(line);
        if (money != null) {
          currency ??= _normalizeCurrency(money.group(1));
        }
        continue;
      }

      final matches = _moneyRegex.allMatches(line).toList();
      if (matches.isEmpty) continue;

      final last = matches.last;
      final amount = _parseAmount(last.group(2) ?? last.group(3));
      if (amount == null || amount <= 0) continue;
      currency ??= _normalizeCurrency(last.group(1));

      var description = line.substring(0, last.start).trim();
      description = description.replaceAll(RegExp(r'[\sx×]+$'), '').trim();
      if (description.isEmpty) description = 'Scanned item';

      var quantity = 1;
      final qtyMatch = RegExp(r'(?:x|×)\s*(\d+)|(\d+)\s*(?:x|×)', caseSensitive: false).firstMatch(description);
      if (qtyMatch != null) {
        quantity = int.tryParse(qtyMatch.group(1) ?? qtyMatch.group(2) ?? '1') ?? 1;
        description = description.replaceAll(qtyMatch.group(0)!, '').trim();
      }

      items.add(
        InvoiceItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_${i}_${items.length}',
          description: description.isEmpty ? 'Scanned item' : description,
          unitCost: quantity > 0 ? amount / quantity : amount,
          quantity: quantity,
        ),
      );
    }

    if (items.isEmpty) {
      final amounts = _moneyRegex
          .allMatches(rawText)
          .map((m) => _parseAmount(m.group(2) ?? m.group(3)))
          .whereType<double>()
          .toList();
      if (amounts.isNotEmpty) {
        amounts.sort();
        items.add(
          InvoiceItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            description: 'Scanned item',
            unitCost: amounts.last,
            quantity: 1,
          ),
        );
      }
    }

    return ParsedInvoiceData(
      clientName: clientName,
      email: email,
      phone: phone,
      currency: currency,
      items: items,
      rawText: rawText,
      imagePath: imagePath,
    );
  }

  static double? _parseAmount(String? raw) {
    if (raw == null) return null;
    return double.tryParse(raw.replaceAll(',', ''));
  }

  static String? _normalizeCurrency(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toUpperCase()) {
      case r'$':
      case 'USD':
        return 'USD';
      case '€':
      case 'EUR':
        return 'EUR';
      case '£':
      case 'GBP':
        return 'GBP';
      case 'RS':
      case 'RS.':
      case 'PKR':
        return 'PKR';
      case 'INR':
        return 'INR';
      default:
        return 'USD';
    }
  }
}
