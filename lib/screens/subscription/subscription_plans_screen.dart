import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/subscription_tier.dart';
import '../../providers/invoice_provider.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/blue_screen.dart';

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
    final base = buildBlueTheme(Theme.of(context));
    return Theme(
      data: base.copyWith(textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme)),
      child: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = _titleColor(theme);
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

    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F8FF);
    final proAccent = isDark ? BlueColors.sky : BlueColors.bright;
    final screenW = MediaQuery.sizeOf(context).width;
    final barPad = screenW < 360 ? 14.0 : 20.0;

    final purchaseDisabled = sub.purchasePending ||
        !sub.storeAvailable ||
        current.index >= (_selectedPaidTier?.index ?? 0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: titleColor,
        centerTitle: false,
        title: Text(
          strings.subscriptionPlansTitle,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.4,
            color: titleColor,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: TextButton(
              onPressed: sub.purchasePending ? null : _restore,
              style: TextButton.styleFrom(
                foregroundColor: scheme.primary,
                textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              child: Text(strings.restorePurchases),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final hPad = w < 360 ? 14.0 : 20.0;
          final cols = w >= 900 ? 3 : (w >= 700 ? 2 : 1);
          const gap = 16.0;

          final planCard = _CurrentPlanCard(
            tier: current,
            remaining: remaining,
            limit: limit,
            createdToday: provider.invoicesCreatedToday,
            progress: quotaProgress,
            pulse: _pulse,
          );

          final billingCard = Container(
            padding: const EdgeInsets.all(18),
            decoration: _surfaceDecoration(theme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.chooseBillingPeriod,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.playStoreSubscriptionHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                ),
                const SizedBox(height: 14),
                _BillingToggle(
                  yearly: _yearly,
                  onChanged: (v) => setState(() => _yearly = v),
                  monthlyLabel: strings.billingMonthly,
                  yearlyLabel: strings.billingYearly,
                  saveHint: strings.yearlySaveHint,
                  muted: muted,
                ),
              ],
            ),
          );

          final freeCard = _TierCard(
            tier: SubscriptionTier.free,
            title: strings.tierFreeName,
            priceLine: strings.tierFreePrice,
            features: strings.tierFreeFeatures,
            isCurrent: current == SubscriptionTier.free,
            selected: false,
            onSelect: () {},
            accent: scheme.outline,
          );
          final premiumCard = _TierCard(
            tier: SubscriptionTier.premium,
            title: strings.tierPremiumName,
            priceLine: _priceLine(sub, SubscriptionTier.premium, _yearly, strings),
            features: strings.tierPremiumFeatures,
            isCurrent: current == SubscriptionTier.premium,
            selected: _selectedPaidTier == SubscriptionTier.premium,
            onSelect: () => setState(() => _selectedPaidTier = SubscriptionTier.premium),
            badge: strings.recommendedPlan,
            accent: BlueColors.light,
            recommended: true,
          );
          final proCard = _TierCard(
            tier: SubscriptionTier.pro,
            title: strings.tierProName,
            priceLine: _priceLine(sub, SubscriptionTier.pro, _yearly, strings),
            features: strings.tierProFeatures,
            isCurrent: current == SubscriptionTier.pro,
            selected: _selectedPaidTier == SubscriptionTier.pro,
            onSelect: () => setState(() => _selectedPaidTier = SubscriptionTier.pro),
            accent: proAccent,
            highlight: true,
          );

          final Widget topSection = cols >= 2
              ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: planCard),
                const SizedBox(width: gap),
                Expanded(child: billingCard),
              ],
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [planCard, const SizedBox(height: gap), billingCard],
          );

          final Widget tierSection;
          if (cols >= 3) {
            tierSection = IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: freeCard),
                  const SizedBox(width: gap),
                  Expanded(child: premiumCard),
                  const SizedBox(width: gap),
                  Expanded(child: proCard),
                ],
              ),
            );
          } else if (cols == 2) {
            tierSection = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: premiumCard),
                      const SizedBox(width: gap),
                      Expanded(child: proCard),
                    ],
                  ),
                ),
                const SizedBox(height: gap),
                freeCard,
              ],
            );
          } else {
            tierSection = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                freeCard,
                const SizedBox(height: 14),
                premiumCard,
                const SizedBox(height: 14),
                proCard,
              ],
            );
          }

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    topSection,
                    const SizedBox(height: 22),
                    tierSection,
                    if (!sub.storeAvailable) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.storefront_rounded, size: 20, color: scheme.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                strings.subscriptionStoreUnavailable,
                                style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (sub.loadingProducts) ...[
                      const SizedBox(height: 20),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (sub.lastError != null && sub.lastError!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(sub.lastError!, style: TextStyle(color: scheme.error, fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _surfaceDecoration(theme, radius: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 20, color: scheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.pricingDisclaimer,
                                  style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  strings.playStoreManageHint,
                                  style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.primary.withValues(alpha: 0.12))),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: EdgeInsets.fromLTRB(barPad, 12, barPad, 12),
                child: AnimatedScale(
                  scale: sub.purchasePending ? 0.98 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: _GradientPurchaseButton(
                    onPressed: purchaseDisabled ? null : _purchase,
                    loading: sub.purchasePending,
                    label: sub.purchasePending
                        ? strings.purchaseInProgress
                        : current.index >= (_selectedPaidTier?.index ?? 0)
                        ? strings.activePlanBadge
                        : strings.subscribeTo(strings.tierDisplayName(_selectedPaidTier!)),
                  ),
                ),
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

// ---------------------------------------------------------------------------
// Shared style helpers
// ---------------------------------------------------------------------------

Color _titleColor(ThemeData theme) => theme.brightness == Brightness.dark ? Colors.white : BlueColors.navy;

BoxDecoration _surfaceDecoration(ThemeData theme, {double radius = 22}) {
  final scheme = theme.colorScheme;
  return BoxDecoration(
    color: scheme.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
    boxShadow: [
      BoxShadow(
        color: scheme.primary.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Gradient purchase button (56 high, radius 16, soft glow)
// ---------------------------------------------------------------------------

class _GradientPurchaseButton extends StatelessWidget {
  const _GradientPurchaseButton({
    required this.label,
    required this.onPressed,
    required this.loading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final fg = enabled || loading ? Colors.white : scheme.onSurface.withValues(alpha: 0.38);

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          gradient: enabled || loading
              ? LinearGradient(
            colors: [BlueColors.bright, BlueColors.light],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: enabled || loading ? null : scheme.onSurface.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled || loading
              ? [
            BoxShadow(
              color: BlueColors.light.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: fg,
                      ),
                    ),
                  ),
                  if (enabled && !loading) ...[
                    const SizedBox(width: 10),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Billing toggle
// ---------------------------------------------------------------------------

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
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
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
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Row(
            key: ValueKey(yearly),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_offer_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  saveHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                ),
              ),
            ],
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
        gradient: selected
            ? LinearGradient(
          colors: [BlueColors.bright, BlueColors.light],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        )
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected
            ? [
          BoxShadow(
            color: BlueColors.light.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Current plan card
// ---------------------------------------------------------------------------

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
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3).toDouble();
    final ring = 64.0 * textScale;

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPro
                  ? const [BlueColors.navy, BlueColors.bright]
                  : [
                BlueColors.bright,
                Color.lerp(BlueColors.light, BlueColors.sky, pulse.value)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: BlueColors.bright.withValues(alpha: 0.3),
                blurRadius: 24,
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
              width: ring,
              height: ring,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: ring,
                    height: ring,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${remaining ?? 0}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: ring,
              height: ring,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.all_inclusive_rounded, color: Colors.white, size: ring * 0.5),
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
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  limit < 0
                      ? strings.unlimitedInvoicesToday
                      : strings.invoicesRemainingToday(remaining ?? 0, limit, createdToday),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tier card
// ---------------------------------------------------------------------------

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

  List<Color> get _tileColors => switch (tier) {
    SubscriptionTier.pro => [BlueColors.bright, BlueColors.light],
    SubscriptionTier.premium => [BlueColors.light, BlueColors.sky],
    SubscriptionTier.free => const [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleColor = _titleColor(theme);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final strings = context.l10n;
    final interactive = tier != SubscriptionTier.free;

    return AnimatedScale(
      scale: selected ? 1.015 : 1,
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
              color: scheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? accent : scheme.primary.withValues(alpha: 0.12),
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected ? accent.withValues(alpha: 0.22) : scheme.primary.withValues(alpha: 0.07),
                  blurRadius: selected ? 24 : 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _tileColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _tileColors.first.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        tier == SubscriptionTier.pro
                            ? Icons.diamond_rounded
                            : tier == SubscriptionTier.premium
                            ? Icons.star_rounded
                            : Icons.person_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            priceLine,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      _Pill(
                        label: strings.activePlanBadge,
                        color: accent,
                        icon: Icons.check_circle_rounded,
                      )
                    else if (recommended)
                      _Pill(
                        label: badge ?? '',
                        color: accent,
                        icon: Icons.bolt_rounded,
                      )
                    else if (selected)
                        Icon(Icons.check_circle_rounded, color: accent),
                  ],
                ),
                const SizedBox(height: 16),
                ...features.map(
                      (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_rounded, size: 15, color: accent),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f,
                            style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.35),
                          ),
                        ),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}