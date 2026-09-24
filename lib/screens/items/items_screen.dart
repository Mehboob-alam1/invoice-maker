// New packages needed:
//   google_fonts: ^6.2.1   (add to pubspec.yaml)
// New imports needed:
//   import 'package:google_fonts/google_fonts.dart';
//   import '../../core/theme/blue_theme.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/invoice_item.dart';
import '../../providers/invoice_provider.dart';
import '../../ads/ad_action.dart';
import '../../widgets/blue_screen.dart';
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

    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                strings.catalogItems,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.4,
                  color: isDark ? Colors.white : BlueColors.navy,
                ),
              ),
            ),
            floatingActionButton: _GradientFab(
              onPressed: () => runMajorActionAsync(context, () => _edit(context)),
            ),
            body: AppPageShell(
              child: items.isEmpty
                  ? _EmptyStateWrapper(
                strings: strings,
                onAction: () => runMajorActionAsync(context, () => _edit(context)),
              )
                  : _ResponsiveItemsList(
                items: items,
                onTapItem: (item) =>
                    runMajorActionAsync(context, () => _edit(context, item: item)),
                onDeleteItem: (item) => runWithInterstitial(context, () {
                  context.read<InvoiceProvider>().deleteCatalogItem(item.id);
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state, centered with a max width for larger screens.
// ---------------------------------------------------------------------------

class _EmptyStateWrapper extends StatelessWidget {
  const _EmptyStateWrapper({required this.strings, required this.onAction});

  final AppStrings strings;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: strings.noItemsYet,
              actionLabel: strings.newItem,
              onAction: onAction,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive list / grid of catalog items.
// ---------------------------------------------------------------------------

class _ResponsiveItemsList extends StatelessWidget {
  const _ResponsiveItemsList({
    required this.items,
    required this.onTapItem,
    required this.onDeleteItem,
  });

  final List<InvoiceItem> items;
  final ValueChanged<InvoiceItem> onTapItem;
  final ValueChanged<InvoiceItem> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final textScaler = MediaQuery.textScalerOf(context);
    // Base card height scaled with the system text-scale factor so larger
    // accessibility text sizes don't get clipped.
    final baseCardHeight = textScaler.scale(84).clamp(84.0, 160.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 360 ? 12.0 : 20.0;

        int crossAxisCount;
        double maxContentWidth;
        if (width >= 900) {
          crossAxisCount = 3;
          maxContentWidth = 1100;
        } else if (width >= 700) {
          crossAxisCount = 2;
          maxContentWidth = 900;
        } else {
          crossAxisCount = 1;
          maxContentWidth = width;
        }

        final gridPadding = EdgeInsets.fromLTRB(
          horizontalPadding,
          12,
          horizontalPadding,
          88 + bottomSafe,
        );

        if (crossAxisCount == 1) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: ListView.separated(
                padding: gridPadding,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return _ItemCard(
                    item: item,
                    minHeight: baseCardHeight,
                    onTap: () => onTapItem(item),
                    onDelete: () => onDeleteItem(item),
                  );
                },
              ),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: GridView.builder(
              padding: gridPadding,
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: baseCardHeight,
              ),
              itemBuilder: (context, i) {
                final item = items[i];
                return _ItemCard(
                  item: item,
                  minHeight: baseCardHeight,
                  onTap: () => onTapItem(item),
                  onDelete: () => onDeleteItem(item),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Styled item card.
// ---------------------------------------------------------------------------

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.minHeight,
    required this.onTap,
    required this.onDelete,
  });

  final InvoiceItem item;
  final double minHeight;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitle = [
      '${item.quantity} × ${item.unitCost.toStringAsFixed(2)}',
      if (item.notes?.isNotEmpty == true) item.notes!,
    ].join(' · ');

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: BlueColors.bright.withValues(alpha: isDark ? 0.0 : 0.075),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              children: [
                _GradientAvatar(icon: Icons.sell_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.description,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : BlueColors.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: scheme.error,
                  ),
                  onPressed: onDelete,
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.primary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient tile avatar (blue -> sky), white icon.
// ---------------------------------------------------------------------------

class _GradientAvatar extends StatelessWidget {
  const _GradientAvatar({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BlueColors.bright, BlueColors.sky],
        ),
        boxShadow: [
          BoxShadow(
            color: BlueColors.bright.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient floating action button.
// ---------------------------------------------------------------------------

class _GradientFab extends StatelessWidget {
  const _GradientFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BlueColors.bright, BlueColors.sky],
        ),
        boxShadow: [
          BoxShadow(
            color: BlueColors.bright.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}