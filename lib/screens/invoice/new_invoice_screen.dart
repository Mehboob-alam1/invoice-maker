import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/client.dart';
import '../../models/invoice_item.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/client_form_sheet.dart';
import '../../widgets/item_form_sheet.dart';

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
  Client? _client;
  final List<InvoiceItem> _items = [];
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _client = widget.initialClient;
    if (widget.initialItems != null) _items.addAll(widget.initialItems!);
    if (widget.currency != null) _currency = widget.currency!;
  }

  double get _total => _items.fold(0, (sum, i) => sum + i.total);

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
        );
      });
    } else {
      final updated = existing.copyWith(
        name: result.name,
        phone: result.phone,
        email: result.email,
        address: result.address,
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
    final result = await showItemFormSheet(context);
    if (!mounted || result == null) return;
    setState(() => _items.add(result));
  }

  Future<void> _editItem(int index) async {
    final result = await showItemFormSheet(context, item: _items[index]);
    if (!mounted || result == null) return;
    setState(() => _items[index] = result);
  }

  void _saveInvoice() {
    final strings = AppStrings.read(context);
    if (_client == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.addClientAndItemFirst)),
      );
      return;
    }
    context.read<InvoiceProvider>().createInvoice(client: _client!, items: _items, currency: _currency);
    Navigator.of(context).popUntil((route) => route.isFirst);
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
      body: ListView(
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
          const SizedBox(height: 24),
          Text(strings.items, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ..._items.asMap().entries.map((entry) {
            final item = entry.value;
            final details = [
              '${item.quantity} × \$${item.unitCost.toStringAsFixed(2)}',
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
                    Text('\$${item.total.toStringAsFixed(2)}',
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
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      DropdownMenuItem(value: 'PKR', child: Text('PKR')),
                    ],
                    onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                  ),
                  const SizedBox(width: 12),
                  Text(_total.toStringAsFixed(2),
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
          ElevatedButton(onPressed: _saveInvoice, child: Text(strings.saveInvoice)),
        ],
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
