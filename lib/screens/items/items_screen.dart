import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/invoice_item.dart';
import '../../providers/invoice_provider.dart';
import '../../ads/ad_action.dart';
import '../../widgets/item_form_sheet.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../../widgets/ui/empty_state_view.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  Future<void> _edit(BuildContext context, {InvoiceItem? item}) async {
    final result = await showItemFormSheet(context, item: item);
    if (result == null || !context.mounted) return;
    final provider = context.read<InvoiceProvider>();
    if (item == null) {
      provider.addCatalogItem(
        description: result.description,
        notes: result.notes,
        unitCost: result.unitCost,
        quantity: result.quantity,
      );
    } else {
      provider.updateCatalogItem(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<InvoiceProvider>().catalogItems;
    final strings = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(strings.catalogItems)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => runMajorActionAsync(context, () => _edit(context)),
        child: const Icon(Icons.add_rounded),
      ),
      body: AppPageShell(
        child: items.isEmpty
            ? EmptyStateView(
                icon: Icons.inventory_2_outlined,
                title: strings.noItemsYet,
                actionLabel: strings.newItem,
                onAction: () => runMajorActionAsync(context, () => _edit(context)),
              )
            : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                final scheme = Theme.of(context).colorScheme;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.secondary.withValues(alpha: 0.14),
                      foregroundColor: scheme.secondary,
                      child: const Icon(Icons.sell_outlined, size: 20),
                    ),
                    title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      [
                        '${item.quantity} × ${item.unitCost.toStringAsFixed(2)}',
                        if (item.notes?.isNotEmpty == true) item.notes!,
                      ].join(' · '),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => runWithInterstitial(context, () {
                        context.read<InvoiceProvider>().deleteCatalogItem(item.id);
                      }),
                    ),
                    onTap: () => runMajorActionAsync(context, () => _edit(context, item: item)),
                  ),
                );
              },
            ),
      ),
    );
  }
}
