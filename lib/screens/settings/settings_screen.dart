import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/subscription_tier.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/theme_provider.dart';
import '../clients/clients_screen.dart';
import '../items/items_screen.dart';
import '../onboarding/language_screen.dart';
import '../subscription/subscription_plans_screen.dart';
import '../../services/subscription_service.dart';
import '../../ads/ad_action.dart';
import '../../navigation/app_page_route.dart';
import '../../widgets/settings_profile_header.dart';
import '../../widgets/ui/app_page_shell.dart';

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
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: AppPageShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
          const SettingsProfileHeader(),
          const SizedBox(height: 20),
          _PlanBanner(
            tier: provider.subscriptionTier,
            remaining: provider.invoicesRemainingToday,
            limit: provider.dailyInvoiceLimit,
            onTap: () => runWithInterstitial(context, () {
              Navigator.of(context).push(appPageRoute(const SubscriptionPlansScreen()));
            }),
          ),
          const SizedBox(height: 20),
          _SettingsSection(items: [
            _SettingsItem(
              icon: Icons.groups_rounded,
              label: strings.client,
              onTap: () => runWithInterstitial(context, () {
                Navigator.push(context, appPageRoute(const ClientsScreen()));
              }),
            ),
            _SettingsItem(
              icon: Icons.menu_book_rounded,
              label: strings.catalogItems,
              onTap: () => runWithInterstitial(context, () {
                Navigator.push(context, appPageRoute(const ItemsScreen()));
              }),
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
              onTap: () => runWithInterstitial(context, () {
                Navigator.push(context, appPageRoute(const LanguageScreen()));
              }),
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
              onTap: () async {
                final sub = context.read<SubscriptionService>();
                await sub.restorePurchases();
                if (!context.mounted) return;
                final message = provider.isPremiumOrAbove
                    ? strings.restoreCompletePro
                    : strings.restoreCompleteNone;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      ),
    );
  }
}

class _PlanBanner extends StatelessWidget {
  final SubscriptionTier tier;
  final int? remaining;
  final int limit;
  final VoidCallback onTap;

  const _PlanBanner({
    required this.tier,
    required this.remaining,
    required this.limit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final isPro = tier == SubscriptionTier.pro;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPro ? const LinearGradient(colors: AppColors.unlockGradient) : null,
          color: isPro ? null : theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.currentPlanLabel(strings.tierDisplayName(tier)),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: isPro ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              limit < 0
                  ? strings.unlimitedInvoicesToday
                  : strings.homeQuotaBanner(remaining ?? 0, limit),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isPro ? Colors.white.withValues(alpha: 0.92) : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: isPro ? Colors.white : theme.colorScheme.primary,
              ),
              child: Text(strings.subscriptionPlansTitle),
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
