import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../ads/ad_remote_config.dart';
import '../../core/constants/subscription_products.dart';
import '../../core/constants/app_colors.dart';
import '../../core/remote_config/remote_config_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/blue_theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/subscription_tier.dart';
import '../../providers/invoice_provider.dart';
import '../../services/paywall_analytics.dart';
import '../../services/subscription_service.dart';
import '../../widgets/bottom_banner_host.dart';

/// Single weekly plan with a 3-day free trial. The close button waits [delay].
class WeeklyPaywallScreen extends StatefulWidget with NoBottomBanner {
  const WeeklyPaywallScreen({super.key, this.source = PaywallSource.crown});

  final PaywallSource source;

  @override
  State<WeeklyPaywallScreen> createState() => _WeeklyPaywallScreenState();
}

class _WeeklyPaywallScreenState extends State<WeeklyPaywallScreen> with SingleTickerProviderStateMixin {
  bool _canClose = false;
  bool _winBack = false;
  bool _purchased = false;
  bool _closedLogged = false;
  Timer? _closeTimer;
  late final AnimationController _pulse;
  late final String _variant;
  InvoiceProvider? _invoices;

  @override
  void initState() {
    super.initState();
    _variant = RemoteConfigRepository.instance.paywallVariant;
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    final seconds = AdRemoteConfig.instance.paywallCloseDelaySeconds;
    if (seconds == 0) {
      _canClose = true;
    } else {
      _closeTimer = Timer(Duration(seconds: seconds), () {
        if (mounted) setState(() => _canClose = true);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final winBack = prefs.getBool(SubscriptionService.winBackEligibleKey) == true;
      if (winBack) await prefs.setBool(SubscriptionService.winBackEligibleKey, false);
      if (!mounted) return;
      setState(() => _winBack = winBack);
      context.read<SubscriptionService>().loadProducts();
      _invoices = context.read<InvoiceProvider>();
      _invoices!.addListener(_onTier);
      await PaywallAnalytics.log('paywall_shown', variant: _variant, source: widget.source);
    });
  }

  void _onTier() {
    if (!mounted || _purchased) return;
    if (_invoices?.subscriptionTier == SubscriptionTier.free) return;
    _purchased = true;
    PaywallAnalytics.log('paywall_purchase_success', variant: _variant, source: widget.source);
  }

  void _logClosed() {
    if (_closedLogged || _purchased) return;
    _closedLogged = true;
    PaywallAnalytics.log('paywall_closed', variant: _variant, source: widget.source);
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _pulse.dispose();
    _invoices?.removeListener(_onTier);
    _logClosed();
    super.dispose();
  }

  Future<void> _startTrial() async {
    await PaywallAnalytics.log('paywall_plan_selected', variant: _variant, source: widget.source);
    await PaywallAnalytics.log('paywall_purchase_start', variant: _variant, source: widget.source);
    if (!mounted) return;
    final sub = context.read<SubscriptionService>();
    final offer = _winBack ? sub.winBackOffer : null;
    final ok = await sub.purchaseProductId(SubscriptionProducts.weekly, offerToken: offer?.token);
    if (!mounted) return;
    if (!ok && sub.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sub.lastError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final sub = context.watch<SubscriptionService>();
    final tier = context.watch<InvoiceProvider>().subscriptionTier;
    final price = sub.priceForProduct(SubscriptionProducts.weekly);
    final offer = _winBack ? sub.winBackOffer : null;
    final shownPrice = offer?.price ?? price;
    final active = tier != SubscriptionTier.free;
    final headline = _winBack
        ? strings.t('paywallWinBackTitle')
        : switch (widget.source) {
            PaywallSource.aiCap => strings.t('paywallHeadlineAi'),
            PaywallSource.template => strings.t('paywallHeadlineTemplates'),
            PaywallSource.invoiceCap => strings.t('paywallHeadlineInvoices'),
            _ => strings.t('paywallHeadline'),
          };
    final trialLine = _winBack
        ? strings.t('paywallWinBackBody')
        : shownPrice == null
            ? strings.t('paywallTrialLine')
            : strings.t('paywallThenWeekly', {'price': shownPrice});

    final dark = AppTheme.dark;
    return PopScope(
      canPop: _canClose,
      child: Theme(
        data: dark,
        child: Builder(builder: (context) {
          return Scaffold(
          backgroundColor: const Color(0xFF0B1220),
          body: SafeArea(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 56, color: BlueColors.sky),
                    const SizedBox(height: 12),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkTextPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trialLine,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.darkTextSecondary),
                    ),
                    const SizedBox(height: 24),
                    if (_variant == 'C') ...[
                      FadeTransition(
                        opacity: Tween<double>(begin: 0.55, end: 1).animate(_pulse),
                        child: Column(
                          children: [
                            _Feature(text: strings.t('paywallFeatureNoAds')),
                            _Feature(text: strings.t('paywallFeatureTemplates')),
                            _Feature(text: strings.t('paywallFeatureInvoices')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: BlueColors.sky.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_variant == 'B' || _winBack)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                strings.t('paywallBestValue'),
                                style: const TextStyle(
                                  color: BlueColors.sky,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          Text(
                            strings.t('paywallWeeklyTitle'),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shownPrice ?? strings.t('paywallTrialLine'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: BlueColors.bright,
                            ),
                          ),
                          if (_variant != 'C') ...[
                            const SizedBox(height: 16),
                            _Feature(text: strings.t('paywallFeatureNoAds')),
                            _Feature(text: strings.t('paywallFeatureTemplates')),
                            _Feature(text: strings.t('paywallFeatureInvoices')),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.trialDisclaimer,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary),
                    ),
                    const SizedBox(height: 20),
                    if (active)
                      Text(
                        strings.t('paywallAlreadyActive'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )
                    else
                      BlueGradientButton(
                        label: strings.t('paywallCta'),
                        icon: Icons.bolt_rounded,
                        loading: sub.purchasePending,
                        onPressed: sub.purchasePending || !sub.storeAvailable ? null : _startTrial,
                      ),
                    TextButton(
                      onPressed: sub.purchasePending ? null : () => sub.restorePurchases(),
                      child: Text(strings.restorePurchases),
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    tooltip: strings.close,
                    onPressed: _canClose
                        ? () {
                            _logClosed();
                            Navigator.of(context).pop();
                          }
                        : null,
                    icon: Icon(
                      Icons.close_rounded,
                      color: _canClose ? Colors.white : Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        }),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: BlueColors.bright, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.darkTextPrimary)),
          ),
        ],
      ),
    );
  }
}
