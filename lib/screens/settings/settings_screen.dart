import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_texts.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/theme_provider.dart';
import '../business_setup/edit_business_screen.dart';
import '../clients/clients_screen.dart';
import '../items/items_screen.dart';
import '../onboarding/language_screen.dart';
import '../subscription/pro_paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _feedback(BuildContext context) async {
    final controller = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = ctx.l10n;
        return AlertDialog(
          title: Text(l10n.feedback),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(hintText: l10n.feedbackHint),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.send)),
          ],
        );
      },
    );
    controller.dispose();
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.read(context).thanksFeedback)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<InvoiceProvider>();
    final strings = context.l10n;
    final businessName = provider.businessName;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    businessName.isEmpty ? AppTexts.defaultBusinessName : businessName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  businessName.isNotEmpty ? businessName[0].toUpperCase() : 'M',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _UnlockBanner(
            unlocked: provider.isPro,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProPaywallScreen()),
            ),
          ),
          const SizedBox(height: 20),
          _SettingsSection(items: [
            _SettingsItem(
              icon: Icons.apartment_rounded,
              label: strings.manageBusiness,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditBusinessScreen())),
            ),
            _SettingsItem(
              icon: Icons.groups_rounded,
              label: strings.client,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen())),
            ),
            _SettingsItem(
              icon: Icons.menu_book_rounded,
              label: strings.catalogItems,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen())),
            ),
          ]),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SwitchListTile(
                secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: theme.colorScheme.primary),
                title: Text(strings.darkMode, style: const TextStyle(fontWeight: FontWeight.w600)),
                value: isDark,
                onChanged: (_) => context.read<ThemeProvider>().toggle(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(items: [
            _SettingsItem(
              icon: Icons.public_rounded,
              label: strings.language,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageScreen()),
              ),
            ),
            _SettingsItem(
              icon: Icons.star_rounded,
              label: strings.rateUs,
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) {
                  final l10n = ctx.l10n;
                  return AlertDialog(
                    title: Text(l10n.rateUsTitle),
                    content: Text(l10n.rateUsBody),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok))],
                  );
                },
              ),
            ),
            _SettingsItem(icon: Icons.campaign_rounded, label: strings.feedback, onTap: () => _feedback(context)),
            _SettingsItem(
              icon: Icons.privacy_tip_rounded,
              label: strings.privacyPolicy,
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) {
                  final l10n = ctx.l10n;
                  return AlertDialog(
                    title: Text(l10n.privacyPolicy),
                    content: Text(l10n.privacyBody),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close))],
                  );
                },
              ),
            ),
            _SettingsItem(
              icon: Icons.lock_open_rounded,
              label: strings.restorePurchases,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.isPro ? strings.proAlreadyActive : strings.noPurchaseFound),
                  ),
                );
              },
            ),
            _SettingsItem(
              icon: Icons.ios_share_rounded,
              label: strings.shareApp,
              onTap: () => SharePlus.instance.share(
                ShareParams(text: strings.shareAppText),
              ),
            ),
            _SettingsItem(
              icon: Icons.groups_2_rounded,
              label: strings.communityGuidelines,
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) {
                  final l10n = ctx.l10n;
                  return AlertDialog(
                    title: Text(l10n.communityGuidelines),
                    content: Text(l10n.communityBody),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close))],
                  );
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _UnlockBanner extends StatelessWidget {
  final VoidCallback onTap;
  final bool unlocked;
  const _UnlockBanner({required this.onTap, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    if (unlocked) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(strings.proUnlocked,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.unlockGradient),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.goUnlimited,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(
                    strings.goUnlimitedBody,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5B5BF6),
                      minimumSize: const Size(0, 42),
                    ),
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text(strings.unlock),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _SettingsItem({required this.icon, required this.label, required this.onTap});
}

class _SettingsSection extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;

    return Card(
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: theme.colorScheme.primary),
                title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.chevron_right_rounded, color: muted),
                onTap: item.onTap,
              ),
              if (i != items.length - 1) const Divider(height: 1, indent: 56),
            ],
          );
        }),
      ),
    );
  }
}
