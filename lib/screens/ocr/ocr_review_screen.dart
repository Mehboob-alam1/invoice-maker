import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/invoice_item.dart';
import '../../providers/invoice_provider.dart';
import '../../services/invoice_parser.dart';
import '../../widgets/item_form_sheet.dart';
import 'ocr_flow.dart';

class OcrReviewScreen extends StatefulWidget {
  final ParsedInvoiceData parsed;

  const OcrReviewScreen({super.key, required this.parsed});

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  late final TextEditingController _clientController;
  late final List<InvoiceItem> _items;
  late String _currency;
  bool _showRaw = false;
  var _didSeedItems = false;

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController(text: widget.parsed.clientName ?? '');
    _items = List.of(widget.parsed.items);
    _currency = widget.parsed.currency ?? 'USD';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeedItems) return;
    _didSeedItems = true;
    if (_items.isEmpty) {
      _items.add(
        InvoiceItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          description: AppStrings.read(context).scannedItem,
          unitCost: 0,
          quantity: 1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _clientController.dispose();
    super.dispose();
  }

  double get _total => _items.fold(0, (sum, i) => sum + i.total);

  Future<void> _editItem(int index) async {
    final result = await showItemFormSheet(context, item: _items[index]);
    if (!mounted || result == null) return;
    setState(() => _items[index] = result);
  }

  void _createInvoice() {
    final strings = AppStrings.read(context);
    final name = _clientController.text.trim().isEmpty ? strings.scannedClient : _clientController.text.trim();
    final provider = context.read<InvoiceProvider>();
    final client = provider.findOrCreateClient(
      name: name,
      email: widget.parsed.email,
      phone: widget.parsed.phone,
    );
    provider.createInvoice(client: client, items: _items, currency: _currency);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(strings.reviewScan)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          scannedImagePreview(widget.parsed.imagePath),
          const SizedBox(height: 16),
          TextField(
            controller: _clientController,
            decoration: InputDecoration(
              labelText: strings.clientName,
              prefixIcon: const Icon(Icons.person_rounded),
            ),
          ),
          if (widget.parsed.email != null || widget.parsed.phone != null) ...[
            const SizedBox(height: 10),
            Text(
              [widget.parsed.email, widget.parsed.phone].whereType<String>().join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Text(strings.items, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              DropdownButton<String>(
                value: _currency,
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                  DropdownMenuItem(value: 'PKR', child: Text('PKR')),
                ],
                onChanged: (v) => setState(() => _currency = v ?? 'USD'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._items.asMap().entries.map((entry) {
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  [
                    '${item.quantity} × ${item.unitCost.toStringAsFixed(2)}',
                    if (item.notes?.isNotEmpty == true) item.notes!,
                  ].join('\n'),
                ),
                trailing: Text(item.total.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () => _editItem(entry.key),
              ),
            );
          }),
          Text('${strings.total} $_currency ${_total.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _showRaw = !_showRaw),
            child: Text(_showRaw ? strings.hideScannedText : strings.showScannedText),
          ),
          if (_showRaw)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.parsed.rawText.isEmpty ? strings.noExtraText : widget.parsed.rawText),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createInvoice,
            icon: const Icon(Icons.check_rounded),
            label: Text(strings.createInvoice),
          ),
        ],
      ),
    );
  }
}
