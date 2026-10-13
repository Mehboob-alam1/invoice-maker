import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../ads/ad_remote_config.dart';
import '../../core/constants/subscription_products.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/blue_theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/subscription_tier.dart';
import '../../providers/invoice_provider.dart';
import '../../services/subscription_service.dart';

/// Single weekly plan with a 3-day free trial. The close button waits [delay].
class WeeklyPaywallScreen extends StatefulWidget {
  const WeeklyPaywallScreen({super.key});

  @override
  State<WeeklyPaywallScreen> createState() => _WeeklyPaywallScreenState();
}

class _WeeklyPaywallScreenState extends State<WeeklyPaywallScreen> {
  bool _canClose = false;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    final seconds = AdRemoteConfig.instance.paywallCloseDelaySeconds;
    if (seconds == 0) {
      _canClose = true;
    } else {
      _closeTimer = Timer(Duration(seconds: seconds), () {
        if (mounted) setState(() => _canClose = true);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionService>().loadProducts();
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  Future<void> _startTrial() async {
    final sub = context.read<SubscriptionService>();
    final ok = await sub.purchaseProductId(SubscriptionProducts.weekly);
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
    final active = tier != SubscriptionTier.free;

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
                      strings.t('paywallHeadline'),
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
                      strings.t('paywallTrialLine'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.darkTextSecondary),
                    ),
                    const SizedBox(height: 24),
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
                            price ?? strings.t('paywallTrialLine'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: BlueColors.bright,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Feature(text: strings.t('paywallFeatureNoAds')),
                          _Feature(text: strings.t('paywallFeatureTemplates')),
                          _Feature(text: strings.t('paywallFeatureInvoices')),
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
                  right: 8,
                  child: IconButton(
                    tooltip: strings.close,
                    onPressed: _canClose ? () => Navigator.of(context).pop() : null,
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
