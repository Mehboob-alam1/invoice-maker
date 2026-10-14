import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/blue_theme.dart';
import '../core/utils/currency_format.dart';
import '../l10n/app_strings.dart';
import '../models/invoice_item.dart';
import '../providers/invoice_provider.dart';
import '../services/ai_helpers.dart';

Future<InvoiceItem?> showItemFormSheet(
  BuildContext context, {
  InvoiceItem? item,
  String? currencyCode,
  ValueChanged<String>? onCurrencyChanged,
}) {
  return showModalBottomSheet<InvoiceItem>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Theme(
      data: buildBlueTheme(Theme.of(ctx)),
      child: ItemFormSheet(
        item: item,
        currencyCode: currencyCode,
        onCurrencyChanged: onCurrencyChanged,
      ),
    ),
  );
}

class ItemFormSheet extends StatefulWidget {
  final InvoiceItem? item;
  final String? currencyCode;
  final ValueChanged<String>? onCurrencyChanged;

  const ItemFormSheet({
    super.key,
    this.item,
    this.currencyCode,
    this.onCurrencyChanged,
  });

  @override
  State<ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final TextEditingController _price;
  late final TextEditingController _quantity;
  late final TextEditingController _tax;
  late String _currency;

  bool get _showCurrency => widget.onCurrencyChanged != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final code = widget.currencyCode ?? 'USD';
    _currency = CurrencyFormat.supportedCodes.contains(code) ? code : 'USD';
    _name = TextEditingController(text: item?.description ?? '');
    _name.addListener(() {
      if (mounted) setState(() {});
    });
    _notes = TextEditingController(text: item?.notes ?? '');
    _price = TextEditingController(
      text: item == null || item.unitCost == 0 ? '' : item.unitCost.toStringAsFixed(2),
    );
    _quantity = TextEditingController(text: '${item?.quantity ?? 1}');
    _tax = TextEditingController(
      text: item == null || item.taxRate == 0 ? '' : item.taxRate.toString(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _price.dispose();
    _quantity.dispose();
    _tax.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final notes = _notes.text.trim();
    Navigator.pop(
      context,
      InvoiceItem(
        id: widget.item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        description: _name.text.trim(),
        notes: notes.isEmpty ? null : notes,
        unitCost: double.tryParse(_price.text.trim()) ?? 0,
        quantity: int.tryParse(_quantity.text.trim()) ?? 1,
        taxRate: double.tryParse(_tax.text.trim()) ?? 0,
      ),
    );
  }

  void _setCurrency(String? code) {
    if (code == null || code == _currency) return;
    setState(() => _currency = code);
    widget.onCurrencyChanged?.call(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isEdit = widget.item != null;
    final strings = context.l10n;
    final pricePrefix = CurrencyFormat.symbol(_currency).trim();
    final suggestions = context.read<InvoiceProvider>().itemSuggestions(_name.text);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? strings.editItem : strings.newItem,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.onSurface
                      : BlueColors.navy,
                ),
              ),
              if (_showCurrency) ...[
                const SizedBox(height: 14),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: strings.currency,
                    prefixIcon: const Icon(Icons.payments_outlined),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currency,
                      isExpanded: true,
                      items: CurrencyFormat.supportedCodes
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: _setCurrency,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                autofocus: !isEdit,
                decoration: InputDecoration(
                  labelText: strings.itemName,
                  hintText: strings.itemNameHint,
                  prefixIcon: const Icon(Icons.inventory_2_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.enterItemName;
                  }
                  return null;
                },
              ),
              if (suggestions.isNotEmpty)
                ...suggestions.map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.description),
                    subtitle: Text(CurrencyFormat.format(_currency, item.unitCost)),
                    onTap: () {
                      _name.text = item.description;
                      _notes.text = item.notes ?? '';
                      _price.text = item.unitCost == 0 ? '' : item.unitCost.toStringAsFixed(2);
                      _quantity.text = '${item.quantity}';
                      _tax.text = item.taxRate == 0 ? '' : item.taxRate.toString();
                    },
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final next = await AiHelpers.improveDescription(context, _name.text);
                    if (next != null && mounted) setState(() => _name.text = next);
                  },
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: Text(strings.improveDescription),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: strings.notesOptional,
                  hintText: strings.notesHint,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.quantity,
                  hintText: '1',
                  prefixIcon: const Icon(Icons.pin_rounded),
                ),
                validator: (value) {
                  final qty = int.tryParse(value?.trim() ?? '');
                  if (qty == null || qty < 1) {
                    return strings.enterQuantity;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tax,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.itemTax,
                  prefixIcon: const Icon(Icons.percent_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: strings.price,
                  hintText: '0.00',
                  prefixText: pricePrefix.isNotEmpty ? '$pricePrefix ' : null,
                  prefixIcon: pricePrefix.isEmpty ? const Icon(Icons.attach_money_rounded) : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.enterPrice;
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return strings.enterValidPrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              BlueGradientButton(
                label: strings.save,
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
