import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/client.dart';
import '../../providers/invoice_provider.dart';
import '../../ads/ad_action.dart';
import '../../widgets/client_form_sheet.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../../widgets/ui/empty_state_view.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  Future<void> _edit(BuildContext context, {Client? client}) async {
    final result = await showClientFormSheet(context, client: client);
    if (result == null || !context.mounted) return;
    final provider = context.read<InvoiceProvider>();
    if (client == null) {
      provider.addClient(
        name: result.name,
        email: result.email,
        phone: result.phone,
        address: result.address,
        taxId: result.taxId,
      );
    } else {
      provider.updateClient(
        client.copyWith(
          name: result.name,
          email: result.email,
          phone: result.phone,
          address: result.address,
          taxId: result.taxId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = context.watch<InvoiceProvider>().clients;
    final strings = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(strings.clients)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => runMajorActionAsync(context, () => _edit(context)),
        child: const Icon(Icons.add_rounded),
      ),
      body: AppPageShell(
        child: clients.isEmpty
            ? EmptyStateView(
                icon: Icons.groups_rounded,
                title: strings.noClientsYet,
                actionLabel: strings.addNewClient,
                onAction: () => runMajorActionAsync(context, () => _edit(context)),
              )
            : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
              itemCount: clients.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final client = clients[i];
                final scheme = Theme.of(context).colorScheme;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.14),
                      foregroundColor: scheme.primary,
                      child: Text(client.name.isEmpty ? '?' : client.name[0].toUpperCase()),
                    ),
                    title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      [
                        if (client.phone?.isNotEmpty == true) client.phone,
                        if (client.email?.isNotEmpty == true) client.email,
                        if (client.address?.isNotEmpty == true) client.address,
                      ].join(' · '),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => runWithInterstitial(context, () {
                        context.read<InvoiceProvider>().deleteClient(client.id);
                      }),
                    ),
                    onTap: () => runMajorActionAsync(context, () => _edit(context, client: client)),
                  ),
                );
              },
            ),
      ),
    );
  }
}
