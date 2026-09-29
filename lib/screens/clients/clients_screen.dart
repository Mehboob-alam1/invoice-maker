import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/client.dart';
import '../../providers/invoice_provider.dart';
import '../../ads/ad_action.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/client_form_sheet.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../../widgets/ui/empty_state_view.dart';

const double _kContentMaxWidth = 1100;
const double _kTabletBreakpoint = 700;
const double _kDesktopBreakpoint = 1000;

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

    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final isWide = MediaQuery.sizeOf(context).width >= _kTabletBreakpoint;
          void add() => runMajorActionAsync(context, () => _edit(context));

          return Scaffold(
            appBar: AppBar(title: Text(strings.clients)),
            floatingActionButton: _AddButton(
              extended: isWide,
              label: strings.addNewClient,
              onPressed: add,
            ),
            body: AppPageShell(
              child: clients.isEmpty
                  ? EmptyStateView(
                icon: Icons.groups_rounded,
                title: strings.noClientsYet,
                actionLabel: strings.addNewClient,
                onAction: add,
              )
                  : LayoutBuilder(
                builder: (context, c) {
                  final columns = c.maxWidth >= _kDesktopBreakpoint
                      ? 3
                      : (c.maxWidth >= _kTabletBreakpoint ? 2 : 1);
                  final hPad = c.maxWidth < 360 ? 14.0 : 20.0;
                  // Card height grows with the user's font-size setting.
                  final scale = MediaQuery.textScalerOf(context)
                      .scale(1)
                      .clamp(1.0, 1.6);
                  final cardHeight = 96.0 * scale;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: _kContentMaxWidth),
                      child: GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          12,
                          hPad,
                          96 + MediaQuery.viewPaddingOf(context).bottom,
                        ),
                        itemCount: clients.length,
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: cardHeight,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemBuilder: (context, i) {
                          final client = clients[i];
                          return _ClientCard(
                            client: client,
                            onTap: () => runMajorActionAsync(
                              context,
                                  () => _edit(context, client: client),
                            ),
                            onDelete: () => runWithInterstitial(context, () {
                              context
                                  .read<InvoiceProvider>()
                                  .deleteClient(client.id);
                            }),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.extended,
    required this.label,
    required this.onPressed,
  });

  final bool extended;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shape =
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    const bg = BlueColors.bright;

    if (extended) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: shape,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: bg,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: shape,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onDelete,
  });

  final Client client;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final details = [
      if (client.phone?.isNotEmpty == true) client.phone,
      if (client.email?.isNotEmpty == true) client.email,
      if (client.address?.isNotEmpty == true) client.address,
    ].join(' · ');

    final name = client.name.trim();
    final initial =
    name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: BlueColors.bright.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [BlueColors.bright, BlueColors.sky],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    initial,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          details,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: scheme.error,
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.error.withValues(alpha: 0.08),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}