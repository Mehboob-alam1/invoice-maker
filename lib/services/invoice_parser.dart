import '../models/invoice_item.dart';

class ParsedInvoiceData {
  ParsedInvoiceData({
    this.clientName,
    this.email,
    this.phone,
    this.address,
    this.clientTaxId,
    this.invoiceNumber,
    this.issueDate,
    this.dueDate,
    this.currency,
    this.taxRate,
    this.paymentTerms,
    this.poNumber,
    this.notes,
    List<InvoiceItem>? items,
    this.rawText = '',
    this.imagePath,
  }) : items = items ?? [];

  final String? clientName;
  final String? email;
  final String? phone;
  final String? address;
  final String? clientTaxId;
  final String? invoiceNumber;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? currency;
  final double? taxRate;
  final String? paymentTerms;
  final String? poNumber;
  final String? notes;
  final List<InvoiceItem> items;
  final String rawText;
  final String? imagePath;
}

class InvoiceParser {
  InvoiceParser._();

  static final _emailRegex = RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false);
  static final _phoneRegex = RegExp(r'(?:\+?\d[\d\s().-]{7,}\d)');
  static final _moneyRegex = RegExp(
    r'(?:(USD|EUR|GBP|PKR|INR|CAD|AUD|AED|JPY|CHF|Rs\.?|\$|€|£|₹)\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?|\d+\.\d{2}|\d+)',
    caseSensitive: false,
  );
  static final _summaryLine = RegExp(
    r'\b(sub\s*total|subtotal|grand\s*total|total\s*due|amount\s*due|balance\s*due|total|tax|vat|gst|hst|sales\s*tax|discount|shipping|freight|paid|change)\b',
    caseSensitive: false,
  );
  static final _invoiceNoRegex = RegExp(
    r'(?:invoice|inv\.?|facture|rechnung|bill)\s*(?:#|no\.?|number|num\.?|n[°º])?\s*[:\-]?\s*([A-Z0-9][A-Z0-9\-_/]{1,})',
    caseSensitive: false,
  );
  static final _poRegex = RegExp(
    r'(?:p\.?o\.?\s*(?:#|no\.?|number)?|purchase\s*order)\s*[:\-]?\s*([A-Z0-9][A-Z0-9\-_/]{1,})',
    caseSensitive: false,
  );
  static final _taxIdRegex = RegExp(
    r'(?:vat|gst|tax\s*id|tin|ein|abn|nif|siret|uid|iva)\s*(?:#|no\.?|number|id)?\s*[:\-]?\s*([A-Z0-9][A-Z0-9\-./]{4,})',
    caseSensitive: false,
  );
  static final _taxRateRegex = RegExp(
    r'(?:vat|tax|gst|hst)\s*[\(\[]?\s*(\d{1,2}(?:\.\d{1,2})?)\s*%\s*[\)\]]?',
    caseSensitive: false,
  );
  static final _dateRegex = RegExp(
    r'(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|\d{4}[/\-.]\d{1,2}[/\-.]\d{1,2})',
  );
  static final _buyerHeader = RegExp(
    r'^(bill\s*to|billed\s*to|invoice\s*to|sold\s*to|customer|client|ship\s*to|buyer)\b',
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
    String? address;
    String? clientTaxId;
    String? invoiceNumber;
    DateTime? issueDate;
    DateTime? dueDate;
    double? taxRate;
    String? paymentTerms;
    String? poNumber;
    final notes = <String>[];
    final items = <InvoiceItem>[];
    final usedAmounts = <double>{};

    for (final line in lines) {
      email ??= _emailRegex.firstMatch(line)?.group(0);
      phone ??= _phoneRegex.firstMatch(line)?.group(0)?.trim();
      clientTaxId ??= _taxIdRegex.firstMatch(line)?.group(1)?.trim();
    }

    invoiceNumber ??= _firstMatchGroup(rawText, _invoiceNoRegex);
    poNumber ??= _firstMatchGroup(rawText, _poRegex);

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('payment terms') || lower.contains('terms:')) {
        if (paymentTerms == null) {
          final extracted = line.split(':').skip(1).join(':').trim();
          paymentTerms = extracted.isEmpty ? null : extracted;
        }
        if (paymentTerms == null || paymentTerms.isEmpty) {
          final i = lines.indexOf(line);
          if (i + 1 < lines.length) paymentTerms = lines[i + 1];
        }
      }
      if (lower.contains('net ') && lower.contains('day')) {
        paymentTerms ??= line;
      }
    }

    taxRate ??= double.tryParse(_taxRateRegex.firstMatch(rawText)?.group(1) ?? '');

    issueDate ??= _extractLabeledDate(lines, const [
      'invoice date',
      'issue date',
      'date of issue',
      'date:',
      'dated',
    ]);
    dueDate ??= _extractLabeledDate(lines, const [
      'due date',
      'payment due',
      'due by',
      'pay by',
      'due:',
    ]);
    issueDate ??= _extractLabeledDate(lines, const ['date']);

    final buyerBlock = _extractBuyerBlock(lines);
    clientName ??= buyerBlock.name;
    address ??= buyerBlock.address;
    if (buyerBlock.email != null) email ??= buyerBlock.email;
    if (buyerBlock.phone != null) phone ??= buyerBlock.phone;

    clientName ??= _fallbackClientName(lines);

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isSummaryOnlyLine(line)) {
        final money = _lastMoneyOnLine(line);
        if (money != null) {
          currency ??= money.currency;
          usedAmounts.add(money.amount);
        }
        continue;
      }

      final parsed = _parseLineItem(line, i);
      if (parsed == null) continue;
      currency ??= parsed.currency;
      if (_isLikelyDuplicateSummary(parsed.amount, usedAmounts)) continue;
      items.add(parsed.item);
    }

    if (items.isEmpty) {
      final fallbackItems = _fallbackItemsFromAmounts(rawText, usedAmounts);
      items.addAll(fallbackItems);
    } else {
      _pruneSummaryDuplicates(items, usedAmounts);
      _removeSubtotalDuplicateLines(items);
      _removeSummaryDescriptionItems(items);
    }

    taxRate = _reconcileTaxRate(items, taxRate, usedAmounts);

    for (final line in lines) {
      if (line.length > 20 &&
          !_moneyRegex.hasMatch(line) &&
          !_buyerHeader.hasMatch(line.toLowerCase()) &&
          !line.toLowerCase().contains('invoice')) {
        if (line.toLowerCase().contains('thank') || line.toLowerCase().contains('note')) {
          notes.add(line);
        }
      }
    }

    return ParsedInvoiceData(
      clientName: clientName,
      email: email,
      phone: phone,
      address: address,
      clientTaxId: clientTaxId,
      invoiceNumber: invoiceNumber,
      issueDate: issueDate,
      dueDate: dueDate,
      currency: currency,
      taxRate: taxRate,
      paymentTerms: paymentTerms,
      poNumber: poNumber,
      notes: notes.isEmpty ? null : notes.take(2).join('\n'),
      items: items,
      rawText: rawText,
      imagePath: imagePath,
    );
  }

  static String? _firstMatchGroup(String text, RegExp regex) {
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }

  static _BuyerBlock _extractBuyerBlock(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      if (!_buyerHeader.hasMatch(lines[i])) continue;
      final afterColon = lines[i].split(':');
      final collected = <String>[];
      if (afterColon.length > 1 && afterColon.last.trim().isNotEmpty) {
        collected.add(afterColon.last.trim());
      }
      var j = i + 1;
      while (j < lines.length && collected.length < 5) {
        final next = lines[j];
        if (_buyerHeader.hasMatch(next) || _looksLikeSectionBreak(next)) break;
        if (_summaryLine.hasMatch(next) && _lastMoneyOnLine(next) != null) break;
        collected.add(next);
        j++;
      }
      if (collected.isEmpty) continue;
      final name = collected.first;
      final rest = collected.skip(1).where((l) => !_emailRegex.hasMatch(l) && !_phoneRegex.hasMatch(l)).toList();
      final blockEmail = collected.map((l) => _emailRegex.firstMatch(l)?.group(0)).whereType<String>().firstOrNull;
      final blockPhone = collected.map((l) => _phoneRegex.firstMatch(l)?.group(0)).whereType<String>().firstOrNull;
      return _BuyerBlock(
        name: name,
        address: rest.isEmpty ? null : rest.join('\n'),
        email: blockEmail,
        phone: blockPhone,
      );
    }
    return const _BuyerBlock();
  }

  static bool _looksLikeSectionBreak(String line) {
    final lower = line.toLowerCase();
    return lower.contains('description') ||
        lower.contains('item') && lower.contains('qty') ||
        lower.startsWith('from:') ||
        lower.startsWith('sold by');
  }

  static String? _fallbackClientName(List<String> lines) {
    for (final line in lines) {
      if (_buyerHeader.hasMatch(line)) continue;
      if (_summaryLine.hasMatch(line)) continue;
      if (_moneyRegex.hasMatch(line)) continue;
      if (_invoiceNoRegex.hasMatch(line)) continue;
      if (line.length < 3 || line.length > 60) continue;
      if (RegExp(r'^\d').hasMatch(line)) continue;
      return line;
    }
    return null;
  }

  static DateTime? _extractLabeledDate(List<String> lines, List<String> labels) {
    for (final label in labels) {
      for (var i = 0; i < lines.length; i++) {
        final lower = lines[i].toLowerCase();
        if (!lower.contains(label)) continue;
        final inline = _dateRegex.firstMatch(lines[i]);
        if (inline != null) return _parseDate(inline.group(1)!);
        if (i + 1 < lines.length) {
          final next = _dateRegex.firstMatch(lines[i + 1]);
          if (next != null) return _parseDate(next.group(1)!);
        }
      }
    }
    return null;
  }

  static DateTime? _parseDate(String raw) {
    final normalized = raw.replaceAll('.', '/').replaceAll('-', '/');
    final parts = normalized.split('/');
    if (parts.length != 3) return null;
    try {
      if (parts[0].length == 4) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
      var d = int.parse(parts[0]);
      var m = int.parse(parts[1]);
      var y = int.parse(parts[2]);
      if (y < 100) y += 2000;
      if (m > 12 && d <= 12) {
        final swap = m;
        m = d;
        d = swap;
      }
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  static bool _isSummaryOnlyLine(String line) {
    if (!_summaryLine.hasMatch(line)) return false;
    return !RegExp(r'(item|service|product|description|qty|quantity)', caseSensitive: false).hasMatch(line);
  }

  static _MoneyOnLine? _lastMoneyOnLine(String line) {
    final matches = _moneyRegex.allMatches(line).toList();
    if (matches.isEmpty) return null;
    final last = matches.last;
    final amount = _parseAmount(last.group(2));
    if (amount == null) return null;
    return _MoneyOnLine(amount: amount, currency: _normalizeCurrency(last.group(1)));
  }

  static _ParsedLine? _parseLineItem(String line, int index) {
    if (line.length < 3) return null;
    if (_isSummaryOnlyLine(line)) return null;
    if (_buyerHeader.hasMatch(line)) return null;
    if (_invoiceNoRegex.hasMatch(line) && line.length < 40) return null;

    final normalized = line.replaceAll('\t', ' ').replaceAll(RegExp(r'\s{2,}'), ' ');
    final tableMatch = RegExp(
      r'^(.+?)\s+(\d+(?:\.\d+)?)\s+(\d{1,3}(?:,\d{3})*(?:\.\d{2})?|\d+\.\d{2})\s+(\d{1,3}(?:,\d{3})*(?:\.\d{2})?|\d+\.\d{2})$',
    ).firstMatch(normalized);
    if (tableMatch != null) {
      final qty = double.tryParse(tableMatch.group(2)!) ?? 1;
      final unit = _parseAmount(tableMatch.group(3));
      final lineTotal = _parseAmount(tableMatch.group(4));
      if (lineTotal == null || lineTotal <= 0) return null;
      final quantity = qty < 1 ? 1 : qty.round();
      final unitCost = unit ?? (lineTotal / quantity);
      return _ParsedLine(
        item: InvoiceItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_$index',
          description: tableMatch.group(1)!.trim(),
          unitCost: unitCost,
          quantity: quantity,
        ),
        amount: lineTotal,
        currency: null,
      );
    }

    final matches = _moneyRegex.allMatches(line).toList();
    if (matches.isEmpty) return null;
    final last = matches.last;
    final amount = _parseAmount(last.group(2));
    if (amount == null || amount <= 0) return null;

    var description = line.substring(0, last.start).trim();
    description = description.replaceAll(RegExp(r'[\s\-–—x×]+$', caseSensitive: false), '').trim();
    if (description.isEmpty || description.length < 2) return null;
    if (_summaryLine.hasMatch(description) && description.split(' ').length <= 3) return null;

    var quantity = 1;
    final qtyMatch = RegExp(r'(?:^|\s)(\d+(?:\.\d+)?)\s*(?:x|×|\*)\s*|(?:x|×|\*)\s*(\d+(?:\.\d+)?)', caseSensitive: false)
        .firstMatch(description);
    if (qtyMatch != null) {
      final q = qtyMatch.group(1) ?? qtyMatch.group(2);
      quantity = double.tryParse(q ?? '1')?.round() ?? 1;
      description = description.replaceAll(qtyMatch.group(0)!, '').trim();
    }

    final unitPriceMatch = RegExp(r'@\s*(\d+(?:\.\d{2})?)').firstMatch(line);
    final unitCost = unitPriceMatch != null
        ? double.tryParse(unitPriceMatch.group(1)!)
        : (quantity > 0 ? amount / quantity : amount);

    return _ParsedLine(
      item: InvoiceItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_$index',
        description: description,
        unitCost: unitCost ?? amount,
        quantity: quantity,
      ),
      amount: amount,
      currency: _normalizeCurrency(last.group(1)),
    );
  }

  static List<InvoiceItem> _fallbackItemsFromAmounts(String rawText, Set<double> usedAmounts) {
    final amounts = _moneyRegex
        .allMatches(rawText)
        .map((m) => _parseAmount(m.group(2)))
        .whereType<double>()
        .where((a) => a > 0)
        .toList();
    if (amounts.isEmpty) return [];
    amounts.sort();
    final candidate = amounts.lastWhere((a) => !usedAmounts.contains(a), orElse: () => amounts.last);
    return [
      InvoiceItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        description: 'Scanned item',
        unitCost: candidate,
        quantity: 1,
      ),
    ];
  }

  static void _pruneSummaryDuplicates(List<InvoiceItem> items, Set<double> usedAmounts) {
    if (items.length <= 1 || usedAmounts.isEmpty) return;
    items.removeWhere((item) {
      if (!_summaryDescription.hasMatch(item.description.trim())) return false;
      final t = item.total;
      for (final used in usedAmounts) {
        if ((used - t).abs() < 0.02) return true;
      }
      return false;
    });
  }

  static final _summaryDescription = RegExp(
    r'^(sub\s*total|subtotal|grand\s*total|total\s*due|amount\s*due|balance\s*due|total|tax|vat|gst|hst|sales\s*tax)\b',
    caseSensitive: false,
  );

  /// Drops a line whose amount equals the sum of the other lines (e.g. "Subtotal 320").
  static void _removeSubtotalDuplicateLines(List<InvoiceItem> items) {
    while (items.length > 1) {
      final subtotal = items.fold<double>(0, (s, i) => s + i.total);
      var removed = false;
      for (var i = items.length - 1; i >= 0; i--) {
        final without = subtotal - items[i].total;
        if (without > 0 && (items[i].total - without).abs() < 0.03) {
          items.removeAt(i);
          removed = true;
          break;
        }
        if (items.length > 1 && (items[i].total - subtotal).abs() < 0.03) {
          items.removeAt(i);
          removed = true;
          break;
        }
      }
      if (!removed) break;
    }
  }

  static void _removeSummaryDescriptionItems(List<InvoiceItem> items) {
    items.removeWhere((item) {
      final d = item.description.trim();
      if (d.isEmpty) return false;
      return _summaryDescription.hasMatch(d);
    });
  }

  /// Avoid applying tax again when line items already equal the receipt total.
  static double? _reconcileTaxRate(List<InvoiceItem> items, double? taxRate, Set<double> usedAmounts) {
    if (taxRate == null || taxRate <= 0 || items.isEmpty) return taxRate;
    final sub = items.fold<double>(0, (s, i) => s + i.total);
    final withTax = sub * (1 + taxRate / 100);
    final hasSubtotalLine = usedAmounts.any((a) => (a - sub).abs() < 0.03);
    final hasWithTaxLine = usedAmounts.any((a) => (a - withTax).abs() < 0.03);
    if (hasSubtotalLine && hasWithTaxLine) return taxRate;
    if (usedAmounts.any((a) => (a - sub).abs() < 0.03) && !hasWithTaxLine) {
      return 0;
    }
    return taxRate;
  }

  static bool _isLikelyDuplicateSummary(double amount, Set<double> usedAmounts) {
    for (final used in usedAmounts) {
      if ((used - amount).abs() < 0.02) return true;
    }
    return false;
  }

  static double? _parseAmount(String? raw) {
    if (raw == null) return null;
    return double.tryParse(raw.replaceAll(',', ''));
  }

  static String? _normalizeCurrency(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
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
      case '₹':
        return 'INR';
      case 'CAD':
        return 'CAD';
      case 'AUD':
        return 'AUD';
      case 'AED':
        return 'AED';
      case 'JPY':
      case '¥':
        return 'JPY';
      case 'CHF':
        return 'CHF';
      default:
        return null;
    }
  }
}

class _BuyerBlock {
  const _BuyerBlock({this.name, this.address, this.email, this.phone});
  final String? name;
  final String? address;
  final String? email;
  final String? phone;
}

class _MoneyOnLine {
  const _MoneyOnLine({required this.amount, this.currency});
  final double amount;
  final String? currency;
}

class _ParsedLine {
  const _ParsedLine({required this.item, required this.amount, this.currency});
  final InvoiceItem item;
  final double amount;
  final String? currency;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
