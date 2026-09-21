import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/invoice_item.dart';

Future<InvoiceItem?> showItemFormSheet(
  BuildContext context, {
  InvoiceItem? item,
}) {
  return showModalBottomSheet<InvoiceItem>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => ItemFormSheet(item: item),
  );
}

class ItemFormSheet extends StatefulWidget {
  final InvoiceItem? item;

  const ItemFormSheet({
    super.key,
    this.item,
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

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.description ?? '');
    _notes = TextEditingController(text: item?.notes ?? '');
    _price = TextEditingController(
      text: item == null || item.unitCost == 0 ? '' : item.unitCost.toStringAsFixed(2),
    );
    _quantity = TextEditingController(text: '${item?.quantity ?? 1}');
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _price.dispose();
    _quantity.dispose();
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isEdit = widget.item != null;
    final strings = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? strings.editItem : strings.newItem,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
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
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: strings.price,
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
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
              ElevatedButton(
                onPressed: _save,
                child: Text(strings.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
