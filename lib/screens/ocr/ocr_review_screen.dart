import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_format.dart';
import '../../l10n/app_strings.dart';
import '../../models/client.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/invoice_template.dart';
import '../../providers/invoice_provider.dart';
import '../../services/invoice_create_gate.dart';
import '../../services/invoice_parser.dart';
import '../../widgets/invoice_document_view.dart';
import '../../widgets/invoice_template_preview_sheet.dart';
import '../../widgets/item_form_sheet.dart';
import '../../widgets/template_picker.dart';
import '../../navigation/invoice_flow.dart';
import '../../ads/ad_action.dart';
import 'ocr_flow.dart';

class OcrReviewScreen extends StatefulWidget {
  final ParsedInvoiceData parsed;

  const OcrReviewScreen({super.key, required this.parsed});

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  bool _creating = false;
  late final TextEditingController _clientController;
  late final TextEditingController _addressController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _taxRateController;
  late final TextEditingController _paymentTermsController;
  late final TextEditingController _poController;
  late final TextEditingController _notesController;
  late final List<InvoiceItem> _items;
  late String _currency;
  late DateTime _issueDate;
  DateTime? _dueDate;
  late InvoiceTemplateId _template;
  bool _showRaw = false;
  var _didSeedItems = false;

  @override
  void initState() {
    super.initState();
    final p = widget.parsed;
    _clientController = TextEditingController(text: p.clientName ?? '');
    _addressController = TextEditingController(text: p.address ?? '');
    _taxIdController = TextEditingController(text: p.clientTaxId ?? '');
    _emailController = TextEditingController(text: p.email ?? '');
    _phoneController = TextEditingController(text: p.phone ?? '');
    _invoiceNumberController = TextEditingController(text: p.invoiceNumber ?? '');
    final parsedTax = p.taxRate;
    _taxRateController = TextEditingController(
      text: parsedTax == null ? '' : parsedTax.toStringAsFixed(parsedTax % 1 == 0 ? 0 : 1),
    );
    _paymentTermsController = TextEditingController(text: p.paymentTerms ?? '');
    _poController = TextEditingController(text: p.poNumber ?? '');
    _notesController = TextEditingController(text: p.notes ?? '');
    _items = List.of(p.items);
    _currency = p.currency ?? 'USD';
    if (!CurrencyFormat.supportedCodes.contains(_currency)) _currency = 'USD';
    _issueDate = p.issueDate ?? DateTime.now();
    _dueDate = p.dueDate;
    _template = InvoiceTemplateId.classic;
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
    _addressController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _invoiceNumberController.dispose();
    _taxRateController.dispose();
    _paymentTermsController.dispose();
    _poController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _taxRate => double.tryParse(_taxRateController.text.trim()) ?? 0;

  double get _subtotal => _items.fold(0, (sum, i) => sum + i.total);

  double get _grandTotal => _subtotal + _subtotal * (_taxRate / 100);

  Future<void> _pickDate({required bool due}) async {
    final initial = due ? (_dueDate ?? _issueDate.add(const Duration(days: 30))) : _issueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (due) {
        _dueDate = picked;
      } else {
        _issueDate = picked;
      }
    });
  }

  Future<void> _editItem(int index) async {
    final result = await showItemFormSheet(
      context,
      item: _items[index],
      currencyCode: _currency,
      onCurrencyChanged: (c) => setState(() => _currency = c),
    );
    if (!mounted || result == null) return;
    setState(() => _items[index] = result);
  }

  Invoice _previewInvoice(Client client) {
    return Invoice(
      id: 'preview',
      number: _invoiceNumberController.text.trim().isEmpty ? '#PREVIEW' : _invoiceNumberController.text.trim(),
      client: client,
      items: _items,
      date: _issueDate,
      dueDate: _dueDate,
      currency: _currency,
      taxRate: _taxRate,
      paymentTerms: _emptyToNull(_paymentTermsController.text),
      poNumber: _emptyToNull(_poController.text),
      notes: _emptyToNull(_notesController.text),
      templateId: _template.name,
    );
  }

  String? _emptyToNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  Client _previewClient(AppStrings strings) {
    return Client(
      id: 'preview',
      name: _clientController.text.trim().isEmpty ? strings.scannedClient : _clientController.text.trim(),
      email: _emptyToNull(_emailController.text),
      phone: _emptyToNull(_phoneController.text),
      address: _emptyToNull(_addressController.text),
      taxId: _emptyToNull(_taxIdController.text),
    );
  }

  Future<void> _createInvoice() async {
    if (_creating) return;
    if (!await ensureInvoiceQuotaOrPrompt(context)) return;
    if (!mounted) return;
    if (!await confirmProTemplateUse(context, _template)) return;
    if (!mounted) return;
    setState(() => _creating = true);
    final strings = AppStrings.read(context);
    final name = _clientController.text.trim().isEmpty ? strings.scannedClient : _clientController.text.trim();
    final provider = context.read<InvoiceProvider>();
    final client = provider.findOrCreateClient(
      name: name,
      email: _emptyToNull(_emailController.text),
      phone: _emptyToNull(_phoneController.text),
      address: _emptyToNull(_addressController.text),
      taxId: _emptyToNull(_taxIdController.text),
    );
    final invoice = provider.createInvoice(
      client: client,
      items: _items,
      currency: _currency,
      number: _emptyToNull(_invoiceNumberController.text),
      date: _issueDate,
      dueDate: _dueDate,
      taxRate: _taxRate,
      paymentTerms: _emptyToNull(_paymentTermsController.text),
      poNumber: _emptyToNull(_poController.text),
      notes: _emptyToNull(_notesController.text),
      templateId: _template.name,
    );
    if (!mounted) return;
    try {
      await showInterstitialWithLoadingIfEligible(context);
      if (!mounted) return;
      await navigateAfterInvoiceCreated(context, invoice.id);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _showPreview() {
    final strings = AppStrings.read(context);
    final provider = context.read<InvoiceProvider>();
    final client = _previewClient(strings);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(strings.previewInvoice, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            InvoiceDocumentView(invoice: _previewInvoice(client), provider: provider, strings: strings),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.l10n;
    final locale = context.watch<InvoiceProvider>().languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.reviewScan),
        actions: [
          TextButton(
            onPressed: () => runWithInterstitial(context, _showPreview),
            child: Text(strings.previewInvoice),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          scannedImagePreview(widget.parsed.imagePath),
          const SizedBox(height: 16),
          Text(strings.billTo, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _clientController,
            decoration: InputDecoration(labelText: strings.clientName, prefixIcon: const Icon(Icons.person_rounded)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: strings.address, prefixIcon: const Icon(Icons.location_on_outlined)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _taxIdController,
            decoration: InputDecoration(labelText: strings.taxId, hintText: strings.taxIdHint),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: strings.email, prefixIcon: const Icon(Icons.email_outlined)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: strings.phoneNumber, prefixIcon: const Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 20),
          Text(strings.invoice, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _invoiceNumberController,
            decoration: InputDecoration(labelText: strings.invoiceNumber, prefixIcon: const Icon(Icons.tag)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(due: false),
                  icon: const Icon(Icons.event),
                  label: Text('${strings.issueDate}\n${DateFormat.yMMMd(locale).format(_issueDate)}', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(due: true),
                  icon: const Icon(Icons.event_available),
                  label: Text(
                    _dueDate == null
                        ? strings.dueDate
                        : '${strings.dueDate}\n${DateFormat.yMMMd(locale).format(_dueDate!)}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _poController,
            decoration: InputDecoration(labelText: strings.poNumber),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _paymentTermsController,
            decoration: InputDecoration(labelText: strings.paymentTerms, hintText: strings.paymentTermsHint),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _taxRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: strings.taxRate, suffixText: '%'),
          ),
          const SizedBox(height: 20),
          TemplatePicker(
            selected: _template,
            onChanged: (v) => setState(() => _template = v),
            buildPreviewInvoice: () => _previewInvoice(_previewClient(context.l10n)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(strings.items, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              DropdownButton<String>(
                value: _currency,
                items: CurrencyFormat.supportedCodes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
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
                    '${item.quantity} × ${CurrencyFormat.format(_currency, item.unitCost)}',
                    if (item.notes?.isNotEmpty == true) item.notes!,
                  ].join('\n'),
                ),
                trailing: Text(CurrencyFormat.format(_currency, item.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () => _editItem(entry.key),
              ),
            );
          }),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _totalRow(strings.subtotal, _subtotal),
                  if (_taxRate > 0) _totalRow('${strings.tax} ($_taxRate%)', _subtotal * _taxRate / 100),
                  const Divider(),
                  _totalRow(strings.grandTotal, _grandTotal, bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: strings.notesOptional, hintText: strings.notesHint),
          ),
          const SizedBox(height: 12),
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
          FilledButton.icon(
            onPressed: _creating ? null : _createInvoice,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: _creating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_creating ? strings.creatingInvoice : strings.createInvoice),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(
            CurrencyFormat.format(_currency, amount),
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
