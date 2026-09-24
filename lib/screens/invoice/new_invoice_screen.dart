import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_format.dart';
import '../../l10n/app_strings.dart';
import '../../models/client.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/invoice_template.dart';
import '../../providers/invoice_provider.dart';
import '../../services/invoice_create_gate.dart';
import '../../widgets/client_form_sheet.dart';
import '../../widgets/item_form_sheet.dart';
import '../../widgets/invoice_template_preview_sheet.dart';
import '../../widgets/template_picker.dart';
import '../../ads/ad_action.dart';
import '../../navigation/invoice_flow.dart';
import '../../widgets/ui/app_page_shell.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Client? initialClient;
  final List<InvoiceItem>? initialItems;
  final String? currency;

  const NewInvoiceScreen({
    super.key,
    this.initialClient,
    this.initialItems,
    this.currency,
  });

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  bool _saving = false;
  Client? _client;
  final List<InvoiceItem> _items = [];
  String _currency = 'USD';
  InvoiceTemplateId _template = InvoiceTemplateId.classic;
  final _taxRateController = TextEditingController();
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _client = widget.initialClient;
    if (widget.initialItems != null) _items.addAll(widget.initialItems!);
    if (widget.currency != null) _currency = widget.currency!;
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, i) => sum + i.total);

  double get _taxRate => double.tryParse(_taxRateController.text.trim()) ?? 0;

  double get _total => _subtotal + _subtotal * (_taxRate / 100);

  Future<void> _chooseClient() async {
    final provider = context.read<InvoiceProvider>();
    if (provider.clients.isEmpty) {
      await _addOrEditClient();
      return;
    }

    final selected = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.selectClient, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ...provider.clients.map(
                  (c) => ListTile(
                    leading: const Icon(Icons.person_rounded),
                    title: Text(c.name),
                    subtitle: Text(
                      [c.phone, c.email].where((v) => v != null && v.isNotEmpty).join(' · '),
                    ),
                    onTap: () => Navigator.pop(ctx, c),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_rounded),
                  title: Text(l10n.addNewClient),
                  onTap: () => Navigator.pop(ctx, Client(id: '__new__', name: '')),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    if (selected.id == '__new__') {
      await _addOrEditClient();
    } else {
      setState(() => _client = selected);
    }
  }

  Future<void> _addOrEditClient({Client? existing}) async {
    final result = await showClientFormSheet(context, client: existing);
    if (!mounted || result == null) return;
    final provider = context.read<InvoiceProvider>();
    if (existing == null) {
      setState(() {
        _client = provider.addClient(
          name: result.name,
          phone: result.phone,
          email: result.email,
          address: result.address,
          taxId: result.taxId,
        );
      });
    } else {
      final updated = existing.copyWith(
        name: result.name,
        phone: result.phone,
        email: result.email,
        address: result.address,
        taxId: result.taxId,
      );
      provider.updateClient(updated);
      setState(() => _client = updated);
    }
  }

  Future<void> _addItem() async {
    final provider = context.read<InvoiceProvider>();
    if (provider.catalogItems.isNotEmpty) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) {
          final l10n = ctx.l10n;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.library_books_rounded),
                  title: Text(l10n.fromSavedItems),
                  onTap: () => Navigator.pop(ctx, 'catalog'),
                ),
                ListTile(
                  leading: const Icon(Icons.note_add_rounded),
                  title: Text(l10n.newItem),
                  onTap: () => Navigator.pop(ctx, 'new'),
                ),
              ],
            ),
          );
        },
      );
      if (!mounted) return;
      if (choice == 'catalog') {
        await _addFromCatalog();
        return;
      }
      if (choice == null) return;
    }
    await _addCustomItem();
  }

  Future<void> _addFromCatalog() async {
    final provider = context.read<InvoiceProvider>();
    final selected = await showModalBottomSheet<InvoiceItem>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: provider.catalogItems
              .map(
                (item) => ListTile(
                  title: Text(item.description),
                  subtitle: Text(item.unitCost.toStringAsFixed(2)),
                  onTap: () => Navigator.pop(ctx, item),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _items.add(
        selected.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString()),
      );
    });
  }

  Future<void> _addCustomItem() async {
    final result = await showItemFormSheet(
      context,
      currencyCode: _currency,
      onCurrencyChanged: (c) => setState(() => _currency = c),
    );
    if (!mounted || result == null) return;
    setState(() => _items.add(result));
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

  Invoice _buildPreviewInvoice() {
    final strings = AppStrings.read(context);
    final client = _client ??
        Client(
          id: 'preview',
          name: strings.clientNameHint,
        );
    final items = _items.isEmpty
        ? [
            InvoiceItem(
              id: 'sample',
              description: strings.serviceThisMonth,
              unitCost: 0,
              quantity: 1,
            ),
          ]
        : List<InvoiceItem>.of(_items);
    return Invoice(
      id: 'preview',
      number: '#PREVIEW',
      client: client,
      items: items,
      date: DateTime.now(),
      dueDate: _dueDate,
      currency: _currency,
      taxRate: _taxRate,
      templateId: _template.name,
    );
  }

  Future<void> _saveInvoice() async {
    if (_saving) return;
    if (!await ensureInvoiceQuotaOrPrompt(context)) return;
    if (!mounted) return;
    if (!await confirmProTemplateUse(context, _template)) return;
    if (!mounted) return;
    final strings = AppStrings.read(context);
    if (_client == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.addClientAndItemFirst)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final invoice = context.read<InvoiceProvider>().createInvoice(
            client: _client!,
            items: _items,
            currency: _currency,
            dueDate: _dueDate,
            taxRate: _taxRate,
            templateId: _template.name,
          );
      if (!mounted) return;
      await showInterstitialWithLoadingIfEligible(context);
      if (!mounted) return;
      await navigateAfterInvoiceCreated(context, invoice.id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final strings = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.newInvoice),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
      ),
      body: AppPageShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
          Text(strings.client, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _client == null
              ? _ActionCard(icon: Icons.person_add_alt_1_rounded, label: strings.addClient, onTap: _chooseClient)
              : Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                    title: Text(_client!.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: () {
                      final details = [
                        if (_client!.phone?.isNotEmpty == true) _client!.phone,
                        if (_client!.email?.isNotEmpty == true) _client!.email,
                        if (_client!.address?.isNotEmpty == true) _client!.address,
                      ].join('\n');
                      return details.isEmpty ? null : Text(details);
                    }(),
                    isThreeLine: _client!.address?.isNotEmpty == true,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _addOrEditClient(existing: _client),
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          TemplatePicker(
            selected: _template,
            onChanged: (v) => setState(() => _template = v),
            buildPreviewInvoice: _buildPreviewInvoice,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _taxRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: strings.taxRate, suffixText: '%'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            icon: const Icon(Icons.event),
            label: Text(
              _dueDate == null
                  ? strings.dueDate
                  : '${strings.dueDate}: ${DateFormat.yMMMd().format(_dueDate!)}',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(strings.items, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(strings.currency, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
              const SizedBox(width: 6),
              DropdownButton<String>(
                value: _currency,
                underline: const SizedBox.shrink(),
                items: CurrencyFormat.supportedCodes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? 'USD'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._items.asMap().entries.map((entry) {
            final item = entry.value;
            final details = [
              '${item.quantity} × ${CurrencyFormat.format(_currency, item.unitCost)}',
              if (item.notes?.isNotEmpty == true) item.notes!,
            ].join('\n');
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(details),
                isThreeLine: item.notes?.isNotEmpty == true,
                onTap: () => _editItem(entry.key),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(CurrencyFormat.format(_currency, item.total),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _items.removeAt(entry.key)),
                    ),
                  ],
                ),
              ),
            );
          }),
          _ActionCard(icon: Icons.note_add_rounded, label: strings.addItems, onTap: _addItem),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Text(strings.total, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _currency,
                    underline: const SizedBox.shrink(),
                    items: CurrencyFormat.supportedCodes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                  ),
                  const SizedBox(width: 12),
                  Text(CurrencyFormat.format(_currency, _total),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          if (_client == null && _items.isEmpty) ...[
            const SizedBox(height: 24),
            Center(child: Text(strings.startByAddingClient, style: TextStyle(color: muted))),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _saveInvoice,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_saving ? strings.creatingInvoice : strings.saveInvoice),
          ),
        ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: scheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
