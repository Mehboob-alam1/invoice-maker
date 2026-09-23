import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/subscription_tier.dart';
import '../../providers/invoice_provider.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';

/// Plans, pricing (from Play Store), current tier, and daily invoice quota.
class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> with SingleTickerProviderStateMixin {
  bool _yearly = true;
  SubscriptionTier? _selectedPaidTier;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionService>().loadProducts();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _purchase() async {
    final tier = _selectedPaidTier;
    if (tier == null || tier == SubscriptionTier.free) return;
    final sub = context.read<SubscriptionService>();
    final strings = AppStrings.read(context);
    final ok = await sub.purchaseTier(tier, yearly: _yearly);
    if (!ok && mounted && sub.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sub.lastError!)));
    }
    if (!mounted) return;
    if (context.read<InvoiceProvider>().subscriptionTier.index >= tier.index) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.planActivated)));
      if (!context.read<AuthService>().isSignedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.signInToSyncSubscription)),
        );
      }
    }
  }

  Future<void> _restore() async {
    final sub = context.read<SubscriptionService>();
    final strings = AppStrings.read(context);
    await sub.restorePurchases();
    if (!mounted) return;
    final tier = context.read<InvoiceProvider>().subscriptionTier;
    final message = tier == SubscriptionTier.free ? strings.restoreCompleteNone : strings.restoreCompletePro;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final strings = context.l10n;
    final provider = context.watch<InvoiceProvider>();
    final sub = context.watch<SubscriptionService>();
    final current = provider.subscriptionTier;
    _selectedPaidTier ??= switch (current) {
      SubscriptionTier.pro => SubscriptionTier.pro,
      SubscriptionTier.premium => SubscriptionTier.pro,
      SubscriptionTier.free => SubscriptionTier.premium,
    };

    final remaining = provider.invoicesRemainingToday;
    final limit = provider.dailyInvoiceLimit;
    final quotaProgress = limit > 0 ? (provider.invoicesCreatedToday / limit).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 132,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14),
              title: Text(strings.subscriptionPlansTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.unlockGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: sub.purchasePending ? null : _restore, child: Text(strings.restorePurchases)),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _CurrentPlanCard(
                  tier: current,
                  remaining: remaining,
                  limit: limit,
                  createdToday: provider.invoicesCreatedToday,
                  progress: quotaProgress,
                  pulse: _pulse,
                ),
                const SizedBox(height: 22),
                Text(strings.chooseBillingPeriod, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _BillingToggle(
                  yearly: _yearly,
                  onChanged: (v) => setState(() => _yearly = v),
                  monthlyLabel: strings.billingMonthly,
                  yearlyLabel: strings.billingYearly,
                  saveHint: strings.yearlySaveHint,
                  muted: muted,
                ),
                const SizedBox(height: 22),
                _TierCard(
                  tier: SubscriptionTier.free,
                  title: strings.tierFreeName,
                  priceLine: strings.tierFreePrice,
                  features: strings.tierFreeFeatures,
                  isCurrent: current == SubscriptionTier.free,
                  selected: false,
                  onSelect: () {},
                  accent: theme.colorScheme.outline,
                ),
                const SizedBox(height: 14),
                _TierCard(
                  tier: SubscriptionTier.premium,
                  title: strings.tierPremiumName,
                  priceLine: _priceLine(sub, SubscriptionTier.premium, _yearly, strings),
                  features: strings.tierPremiumFeatures,
                  isCurrent: current == SubscriptionTier.premium,
                  selected: _selectedPaidTier == SubscriptionTier.premium,
                  onSelect: () => setState(() => _selectedPaidTier = SubscriptionTier.premium),
                  badge: strings.recommendedPlan,
                  accent: const Color(0xFF6366F1),
                  recommended: true,
                ),
                const SizedBox(height: 14),
                _TierCard(
                  tier: SubscriptionTier.pro,
                  title: strings.tierProName,
                  priceLine: _priceLine(sub, SubscriptionTier.pro, _yearly, strings),
                  features: strings.tierProFeatures,
                  isCurrent: current == SubscriptionTier.pro,
                  selected: _selectedPaidTier == SubscriptionTier.pro,
                  onSelect: () => setState(() => _selectedPaidTier = SubscriptionTier.pro),
                  accent: const Color(0xFF7C3AED),
                  highlight: true,
                ),
                if (!sub.storeAvailable) ...[
                  const SizedBox(height: 16),
                  Text(strings.subscriptionStoreUnavailable, style: TextStyle(color: muted)),
                ],
                if (sub.loadingProducts) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (sub.lastError != null && sub.lastError!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(sub.lastError!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                Text(strings.pricingDisclaimer, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                const SizedBox(height: 8),
                Text(strings.playStoreManageHint, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: AnimatedScale(
            scale: sub.purchasePending ? 0.98 : 1,
            duration: const Duration(milliseconds: 150),
            child: FilledButton(
              onPressed: sub.purchasePending ||
                      !sub.storeAvailable ||
                      current.index >= (_selectedPaidTier?.index ?? 0)
                  ? null
                  : _purchase,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                sub.purchasePending
                    ? strings.purchaseInProgress
                    : current.index >= (_selectedPaidTier?.index ?? 0)
                        ? strings.activePlanBadge
                        : strings.subscribeTo(strings.tierDisplayName(_selectedPaidTier!)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _priceLine(SubscriptionService sub, SubscriptionTier tier, bool yearly, AppStrings strings) {
    final live = sub.priceLabel(tier, yearly: yearly, fallback: '');
    if (live.isNotEmpty) {
      return yearly ? strings.pricePerYear(live) : strings.pricePerMonth(live);
    }
    return yearly ? strings.suggestedYearlyPrice(tier) : strings.suggestedMonthlyPrice(tier);
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.yearly,
    required this.onChanged,
    required this.monthlyLabel,
    required this.yearlyLabel,
    required this.saveHint,
    required this.muted,
  });

  final bool yearly;
  final ValueChanged<bool> onChanged;
  final String monthlyLabel;
  final String yearlyLabel;
  final String saveHint;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _BillingChip(label: monthlyLabel, selected: !yearly, onTap: () => onChanged(false)),
              ),
              Expanded(
                child: _BillingChip(label: yearlyLabel, selected: yearly, onTap: () => onChanged(true)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            saveHint,
            key: ValueKey(yearly),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

class _BillingChip extends StatelessWidget {
  const _BillingChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected
            ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.tier,
    required this.remaining,
    required this.limit,
    required this.createdToday,
    required this.progress,
    required this.pulse,
  });

  final SubscriptionTier tier;
  final int? remaining;
  final int limit;
  final int createdToday;
  final double progress;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final isPro = tier == SubscriptionTier.pro;

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPro
                  ? AppColors.unlockGradient
                  : [
                      theme.colorScheme.primary.withValues(alpha: 0.85 + pulse.value * 0.05),
                      theme.colorScheme.tertiary.withValues(alpha: 0.75),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          if (limit >= 0)
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    color: Colors.white,
                  ),
                  Text(
                    '${remaining ?? 0}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 32),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.currentPlanLabel(strings.tierDisplayName(tier)),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  limit < 0
                      ? strings.unlimitedInvoicesToday
                      : strings.invoicesRemainingToday(remaining ?? 0, limit, createdToday),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w600, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.title,
    required this.priceLine,
    required this.features,
    required this.isCurrent,
    required this.selected,
    required this.onSelect,
    required this.accent,
    this.badge,
    this.highlight = false,
    this.recommended = false,
  });

  final SubscriptionTier tier;
  final String title;
  final String priceLine;
  final List<String> features;
  final bool isCurrent;
  final bool selected;
  final VoidCallback onSelect;
  final Color accent;
  final String? badge;
  final bool highlight;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final strings = context.l10n;
    final interactive = tier != SubscriptionTier.free;

    return AnimatedScale(
      scale: selected ? 1.02 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: interactive ? onSelect : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: selected ? accent : (theme.extension<AppSemanticColors>()?.border ?? Colors.grey), width: selected ? 2.5 : 1),
              gradient: selected
                  ? LinearGradient(
                      colors: [accent.withValues(alpha: 0.08), theme.cardColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : theme.cardColor,
              boxShadow: selected
                  ? [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        tier == SubscriptionTier.pro
                            ? Icons.diamond_rounded
                            : tier == SubscriptionTier.premium
                                ? Icons.star_rounded
                                : Icons.person_outline_rounded,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          Text(priceLine, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: accent)),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Chip(
                        label: Text(strings.activePlanBadge, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      )
                    else if (recommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(badge ?? '', style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 10)),
                      )
                    else if (selected)
                      Icon(Icons.check_circle_rounded, color: accent),
                  ],
                ),
                const SizedBox(height: 14),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_rounded, size: 20, color: accent),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f, style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.35))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
