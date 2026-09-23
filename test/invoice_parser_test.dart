import 'package:ai_invoice_maker_receipt_app/services/invoice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoiceParser', () {
    test('extracts buyer, items, tax, and invoice metadata', () {
      const text = '''
ACME SUPPLY CO
Invoice No: INV-2024-88
Invoice Date: 03/15/2024
Due Date: 04/14/2024
PO Number: PO-9912

Bill To:
Northwind Traders
12 Market Street
VAT No: GB123456789
billing@northwind.com

Description                    Qty   Price    Total
Web hosting                     1   120.00   120.00
Support hours                   5    40.00   200.00

Subtotal: 320.00
VAT (20%): 64.00
Grand Total: 384.00
Payment terms: Net 30
''';

      final parsed = InvoiceParser.parse(text);

      expect(parsed.invoiceNumber, 'INV-2024-88');
      expect(parsed.clientName, contains('Northwind'));
      expect(parsed.email, 'billing@northwind.com');
      expect(parsed.clientTaxId, 'GB123456789');
      expect(parsed.poNumber, 'PO-9912');
      expect(parsed.taxRate, 20);
      expect(parsed.paymentTerms, contains('Net 30'));
      expect(parsed.items.length, greaterThanOrEqualTo(2));
      expect(parsed.items.any((i) => i.description.toLowerCase().contains('hosting')), isTrue);
    });

    test('skips footer totals when building line items', () {
      const text = '''
Bill To: Sample Client
Design work 1 x 500.00 500.00
Subtotal 500.00
Total 500.00
''';
      final parsed = InvoiceParser.parse(text);
      expect(parsed.items.length, 1);
      expect(parsed.items.first.total, closeTo(500, 0.01));
    });

    test('removes subtotal line parsed as an extra item', () {
      const text = '''
Bill To: Client
Widget A 1 200.00 200.00
Widget B 1 120.00 120.00
Subtotal 320.00
Total 320.00
''';
      final parsed = InvoiceParser.parse(text);
      expect(parsed.items.length, 2);
      expect(parsed.items.fold<double>(0, (s, i) => s + i.total), closeTo(320, 0.01));
    });

    test('does not apply tax when line items already match receipt total', () {
      const text = '''
Bill To: Client
Service 1 384.00 384.00
VAT (20%): 64.00
Grand Total: 384.00
''';
      final parsed = InvoiceParser.parse(text);
      expect(parsed.items.length, 1);
      expect(parsed.items.first.total, closeTo(384, 0.01));
      expect(parsed.taxRate ?? 0, 0);
    });
  });
}
