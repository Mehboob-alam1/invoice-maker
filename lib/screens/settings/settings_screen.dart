import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_strings.dart';
import '../../models/subscription_tier.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/blue_screen.dart';
import '../clients/clients_screen.dart';
import '../items/items_screen.dart';
import '../onboarding/language_screen.dart';
import '../../ads/ad_consent.dart';
import '../../ads/ad_flows.dart';
import '../../ads/ad_placement.dart';
import '../../widgets/placement_native_ad.dart';
import '../../services/backup_service.dart';
import '../../services/engagement_service.dart';
import '../../services/invoice_reminder_service.dart';
import '../referral/referral_screen.dart';
import '../../services/subscription_service.dart';
import '../../ads/ad_action.dart';
import '../../navigation/app_page_route.dart';
import '../../screens/legal/legal_document_screen.dart';
import '../../widgets/account_deletion_flow.dart';
import '../../widgets/rate_feedback_sheet.dart';
import '../../widgets/settings_profile_header.dart';
import '../../widgets/ui/app_page_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // buildBlueTheme is expected to use base.copyWith(...) so extensions such
    // as AppSemanticColors survive.
    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(builder: (innerContext) => _buildBody(innerContext)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<InvoiceProvider>();
    final strings = context.l10n;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);
    final titleColor =
    theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : BlueColors.navy;

    final header = const SettingsProfileHeader();

    final planBanner = _PlanBanner(
      tier: provider.featureTier,
      remaining: provider.invoicesRemainingToday,
      limit: provider.dailyInvoiceLimit,
      note: provider.referralProActive && provider.referralProUntil != null
          ? strings.referralProUntil(
              '${provider.referralProUntil!.year}-${provider.referralProUntil!.month}-${provider.referralProUntil!.day}',
            )
          : null,
      onTap: () {
        if (provider.referralProActive) {
          Navigator.push(context, appPageRoute(const ReferralScreen()));
          return;
        }
        openPaywall(context);
      },
    );

    final workSection = _SettingsSection(items: [
      _SettingsItem(
        icon: Icons.groups_rounded,
        label: strings.client,
        onTap: () => runSettingsNavigation(context, () {
          Navigator.push(context, appPageRoute(const ClientsScreen()));
        }),
      ),
      _SettingsItem(
        icon: Icons.menu_book_rounded,
        label: strings.catalogItems,
        onTap: () => runSettingsNavigation(context, () {
          Navigator.push(context, appPageRoute(const ItemsScreen()));
        }),
      ),
      _SettingsItem(
        icon: Icons.cloud_upload_outlined,
        label: strings.backupTitle,
        onTap: () => BackupService.instance.showSheet(context),
      ),
    ]);

    final generalItems = <_SettingsItem>[
      _SettingsItem(
        icon: Icons.card_giftcard_rounded,
        label: strings.inviteFriends,
        onTap: () => Navigator.push(context, appPageRoute(const ReferralScreen())),
      ),
      if (Platform.isAndroid)
        _SettingsItem(
          icon: Icons.notifications_outlined,
          label: strings.notifications,
          onTap: () => EngagementService.instance.showChannelSettings(context),
        ),
      _SettingsItem(
        icon: Icons.alarm_rounded,
        label: strings.paymentReminders,
        onTap: () => _editPaymentReminders(context),
      ),
      _SettingsItem(
        icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        label: strings.darkMode,
        trailing: Switch(
          value: isDark,
          onChanged: (_) => context.read<ThemeProvider>().toggle(context),
        ),
        onTap: () => context.read<ThemeProvider>().toggle(context),
      ),
      _SettingsItem(
        icon: Icons.public_rounded,
        label: strings.language,
        onTap: () => runSettingsNavigation(context, () {
          Navigator.push(context, appPageRoute(const LanguageScreen()));
        }),
      ),
      _SettingsItem(
        icon: Icons.star_rounded,
        label: strings.rateUs,
        onTap: () => showRateFeedbackSheet(context),
      ),
      _SettingsItem(
        icon: Icons.privacy_tip_rounded,
        label: strings.privacyPolicy,
        onTap: () => Navigator.push(
          context,
          appPageRoute(const LegalDocumentScreen(kind: LegalDocumentKind.privacy)),
        ),
      ),
      if (AdConsent.instance.privacyOptionsRequired)
        _SettingsItem(
          icon: Icons.tune_rounded,
          label: strings.privacyOptions,
          onTap: () => AdConsent.instance.showPrivacyOptions(),
        ),
      _SettingsItem(
        icon: Icons.delete_forever_outlined,
        label: strings.deleteAccount,
        onTap: () => showDeleteAccountDialog(context),
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
        onTap: () => Navigator.push(
          context,
          appPageRoute(const LegalDocumentScreen(kind: LegalDocumentKind.community)),
        ),
      ),
    ];

    final generalSection = _SettingsSection(items: generalItems);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: titleColor),
        title: Text(
          strings.settings,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: titleColor,
          ),
        ),
      ),
      body: AppPageShell(
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final twoColumns = w >= 700;
              final hPad = w < 360 ? 14.0 : (w < 700 ? 20.0 : 28.0);
              final maxW = w >= 900 ? 1100.0 : (w >= 700 ? 820.0 : 560.0);

              final Widget content;
              if (twoColumns) {
                content = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          const SizedBox(height: 20),
                          planBanner,
                          const SizedBox(height: 16),
                          workSection,
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(child: generalSection),
                  ],
                );
              } else {
                content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 20),
                    planBanner,
                    const SizedBox(height: 16),
                    workSection,
                    const SizedBox(height: 16),
                    generalSection,
                  ],
                );
              }

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: content,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Icon(icon, size: 22, color: cs.primary);
  }
}

class _PlanBanner extends StatelessWidget {
  final SubscriptionTier tier;
  final int? remaining;
  final int limit;
  final String? note;
  final VoidCallback onTap;

  const _PlanBanner({
    required this.tier,
    required this.remaining,
    required this.limit,
    required this.onTap,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPro = tier == SubscriptionTier.pro;

    return Material(
      color: isPro ? cs.primary : cs.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: isPro ? cs.onPrimary : cs.primary,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.currentPlanLabel(strings.tierDisplayName(tier)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPro ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      limit < 0
                          ? strings.unlimitedInvoicesToday
                          : strings.homeQuotaBanner(remaining ?? 0, limit),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isPro ? cs.onPrimary.withValues(alpha: 0.85) : cs.onSurfaceVariant,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isPro ? cs.onPrimary.withValues(alpha: 0.85) : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isPro ? cs.onPrimary : cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
}

class _SettingsSection extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: List.generate(items.length, (i) {
        final item = items[i];
        return Column(
          children: [
            InkWell(
              onTap: item.onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      _IconTile(icon: item.icon),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                        ),
                      ),
                      item.trailing ??
                          Icon(Icons.chevron_right_rounded, size: 22, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            if (i == 2)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: PlacementNativeAd(placement: AdPlacement.nativeSettings, inline: true),
              ),
            if (i != items.length - 1)
              Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
          ],
        );
      }),
    );
  }
}

Future<void> _editPaymentReminders(BuildContext context) async {
  final provider = context.read<InvoiceProvider>();
  final current = await InvoiceReminderService.instance.settings();
  if (!context.mounted) return;
  var time = TimeOfDay(hour: current.hour, minute: current.minute);
  final messageCtrl = TextEditingController(text: current.message);
  final pro = provider.isPro;
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final l10n = ctx.l10n;
          return AlertDialog(
            title: Text(l10n.paymentReminders),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pro ? l10n.reminderProHint : l10n.reminderFreeHint),
                if (pro) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: time);
                      if (picked != null) setLocal(() => time = picked);
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text('${l10n.reminderTime}: ${time.format(ctx)}'),
                  ),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l10n.reminderMessage),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
              if (pro) FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.save)),
            ],
          );
        },
      );
    },
  );
  final message = messageCtrl.text;
  messageCtrl.dispose();
  if (saved == true) {
    await InvoiceReminderService.instance.saveSettings(
      hour: time.hour,
      minute: time.minute,
      message: message,
    );
    await InvoiceReminderService.instance.sync(provider.invoices, pro: true);
  }
}