import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/app_dialog.dart';
import '../widgets/loading_ad_dialog.dart';
import '../l10n/app_strings.dart';
import '../models/subscription_tier.dart';
import '../navigation/app_page_route.dart';
import '../providers/invoice_provider.dart';
import '../core/remote_config/remote_config_repository.dart';
import '../screens/subscription/weekly_paywall_screen.dart';
import '../services/paywall_analytics.dart';
import 'ad_action.dart';
import 'ad_manager.dart';
import 'ad_placement.dart';
import 'ad_remote_config.dart';
import 'ad_service.dart';
import 'main_screen_click_counter.dart';

Future<void> openPaywall(
  BuildContext context, {
  PaywallSource source = PaywallSource.crown,
}) {
  return Navigator.of(context).push(
    appPageRoute(WeeklyPaywallScreen(source: source), showNativeAd: false),
  );
}

Future<void> openPaywallIfFree(
  BuildContext context, {
  PaywallSource source = PaywallSource.crown,
}) async {
  if (!context.mounted) return;
  if (context.read<InvoiceProvider>().featureTier != SubscriptionTier.free) return;
  await openPaywall(context, source: source);
}

Future<void> openPaywallAfterSettings(BuildContext context) async {
  if (!context.mounted) return;
  if (context.read<InvoiceProvider>().featureTier != SubscriptionTier.free) return;
  if (!await PaywallSettingsGate.allow()) return;
  if (!context.mounted) return;
  await openPaywall(context, source: PaywallSource.settingsExit);
}

/// How often leaving Settings may open the paywall.
class PaywallSettingsGate {
  PaywallSettingsGate._();

  static const _dayKey = 'paywall_after_settings_day';
  static bool _shownThisSession = false;

  static Future<bool> allow() async {
    final mode = RemoteConfigRepository.instance.paywallAfterSettingsMode;
    if (mode == 'never') return false;
    if (mode == 'always') return true;
    if (mode == 'once_per_session') {
      if (_shownThisSession) return false;
      _shownThisSession = true;
      return true;
    }
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_dayKey) == today) return false;
    await prefs.setString(_dayKey, today);
    return true;
  }
}

/// Loads a rewarded ad when the user taps watch, then shows it.
Future<bool> showPlacementRewarded(BuildContext context, AdPlacement placement) async {
  if (!context.mounted) return false;
  final ads = AdService.instance;
  final waiting = !ads.isSdkReady || !ads.rewardedReady;
  if (waiting) showLoadingAdDialog(context);
  try {
    return await ads.showRewarded(
      adUnitId: AdRemoteConfig.instance.rewardedAdUnitId,
      placement: placement,
    );
  } finally {
    if (waiting && context.mounted) dismissLoadingAdDialog(context);
  }
}

/// Interstitial for one Remote Config placement. Loads on demand with a short wait.
Future<bool> showPlacementInterstitial(BuildContext context, AdPlacement placement) async {
  if (!context.mounted) return false;
  if (!AdRemoteConfig.instance.isPlacementWanted(placement)) return false;
  final invoices = context.read<InvoiceProvider>();
  if (invoices.adsHeld || !invoices.featureTier.showInterstitialAds) return false;
  return showInterstitialWithLoadingIfEligible(context);
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
  final invoices = context.read<InvoiceProvider>();
  final enabled = !invoices.adsHeld &&
      invoices.featureTier.showInterstitialAds &&
      AdRemoteConfig.instance.isPlacementWanted(placement);
  if (!enabled) {
    await action();
    return;
  }

  final strings = AppStrings.read(context);
  final choice = await showDialog<_WatchChoice>(
    context: context,
    builder: (ctx) {
      return AppDialog(
        icon: Icons.workspace_premium_rounded,
        title: strings.t('watchOrPremiumTitle'),
        message: strings.t('watchOrPremiumBody'),
        actions: [
          AppDialogAction(
            label: strings.t('buyPremium'),
            icon: Icons.workspace_premium_rounded,
            onPressed: () => Navigator.pop(ctx, _WatchChoice.premium),
          ),
          AppDialogAction(
            label: strings.t('watchAd'),
            icon: Icons.play_circle_outline_rounded,
            style: AppDialogActionStyle.outlined,
            onPressed: () => Navigator.pop(ctx, _WatchChoice.watch),
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
Future<void> afterGenerationAd(
  BuildContext context,
  AdPlacement placement, {
  String? invoiceId,
}) async {
  final shown = await showPlacementInterstitial(context, placement);
  if (shown && invoiceId != null) {
    AdManager.instance.markInvoiceInterstitial(invoiceId);
  }
  if (!context.mounted) return;
  await openPaywallIfFree(context, source: PaywallSource.other);
}
