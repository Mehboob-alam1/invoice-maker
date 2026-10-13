import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/blue_theme.dart';
import '../l10n/app_strings.dart';
import '../models/subscription_tier.dart';
import '../navigation/app_page_route.dart';
import '../providers/invoice_provider.dart';
import '../screens/subscription/weekly_paywall_screen.dart';
import 'ad_action.dart';
import 'ad_placement.dart';
import 'ad_remote_config.dart';
import 'main_screen_click_counter.dart';

Future<void> openPaywall(BuildContext context) {
  return Navigator.of(context).push(
    appPageRoute(const WeeklyPaywallScreen(), showNativeAd: false),
  );
}

Future<void> openPaywallIfFree(BuildContext context) async {
  if (!context.mounted) return;
  if (context.read<InvoiceProvider>().subscriptionTier != SubscriptionTier.free) return;
  await openPaywall(context);
}

/// On-demand interstitial for one Remote Config placement.
Future<void> showPlacementInterstitial(BuildContext context, AdPlacement placement) async {
  if (!context.mounted) return;
  if (!AdRemoteConfig.instance.isPlacementEnabled(placement)) return;
  final tier = context.read<InvoiceProvider>().subscriptionTier;
  if (!tier.showInterstitialAds) return;
  await showInterstitialWithLoadingIfEligible(context);
}

/// First main-screen click, then every third click after that.
Future<void> onMainScreenClick(BuildContext context, VoidCallback action) async {
  final show = MainScreenClickCounter.takeAndShouldShow();
  if (show) {
    await showPlacementInterstitial(context, AdPlacement.interstitialMain);
  }
  if (!context.mounted) return;
  action();
}

enum _WatchChoice { watch, premium }

/// Watch Ad runs [action] after an interstitial. Buy Premium opens the paywall.
Future<void> runWithWatchOrPremium({
  required BuildContext context,
  required AdPlacement placement,
  required Future<void> Function() action,
}) async {
  if (!context.mounted) return;
  final tier = context.read<InvoiceProvider>().subscriptionTier;
  final enabled = tier.showInterstitialAds && AdRemoteConfig.instance.isPlacementEnabled(placement);
  if (!enabled) {
    await action();
    return;
  }

  final strings = AppStrings.read(context);
  final choice = await showDialog<_WatchChoice>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.t('watchOrPremiumTitle')),
        content: Text(strings.t('watchOrPremiumBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _WatchChoice.watch),
            child: Text(strings.t('watchAd')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BlueColors.bright),
            onPressed: () => Navigator.pop(ctx, _WatchChoice.premium),
            child: Text(strings.t('buyPremium')),
          ),
        ],
      );
    },
  );
  if (!context.mounted || choice == null) return;
  if (choice == _WatchChoice.premium) {
    await openPaywall(context);
    return;
  }
  await showPlacementInterstitial(context, placement);
  if (!context.mounted) return;
  await action();
}

/// Interstitial for a generation step, then the paywall for free users.
Future<void> afterGenerationAd(BuildContext context, AdPlacement placement) async {
  await showPlacementInterstitial(context, placement);
  if (!context.mounted) return;
  await openPaywallIfFree(context);
}
