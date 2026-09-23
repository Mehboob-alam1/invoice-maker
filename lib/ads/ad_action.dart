import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';
import '../widgets/loading_ad_dialog.dart';
import 'ad_service.dart';

/// After a major user action (save, share, navigate, etc.) on Free tier.
Future<void> afterMajorAction(BuildContext context) =>
    showInterstitialWithLoadingIfEligible(context);

/// Loads if needed, shows loading UI only while fetching, then presents interstitial when ready.
Future<void> showInterstitialWithLoadingIfEligible(BuildContext context) async {
  if (!context.mounted) return;
  final tier = context.read<InvoiceProvider>().subscriptionTier;
  final ads = AdService.instance;

  if (!ads.shouldAttemptInterstitial(tier)) {
    ads.preloadInterstitial();
    return;
  }

  final alreadyReady = ads.interstitialReady;
  var loadingDialogVisible = false;

  try {
    if (!alreadyReady) {
      if (!context.mounted) return;
      loadingDialogVisible = true;
      showLoadingAdDialog(context);
      await WidgetsBinding.instance.endOfFrame;
    }

    final loaded = alreadyReady || await ads.ensureInterstitialLoaded();

    if (loadingDialogVisible && context.mounted) {
      dismissLoadingAdDialog(context);
      loadingDialogVisible = false;
    }

    if (!context.mounted) return;
    if (!loaded || !ads.interstitialReady) {
      ads.preloadInterstitial();
      return;
    }

    await ads.showInterstitialIfEligible(tier: tier);
  } finally {
    if (loadingDialogVisible && context.mounted) {
      dismissLoadingAdDialog(context);
    }
  }
}

/// Runs [action], then shows an interstitial for non‑Pro users (Pro skips interstitial only).
Future<void> runWithInterstitial(BuildContext context, VoidCallback action) async {
  action();
  await showInterstitialWithLoadingIfEligible(context);
}

Future<void> runWithInterstitialAsync(BuildContext context, Future<void> Function() action) async {
  await action();
  await showInterstitialWithLoadingIfEligible(context);
}

/// Runs async work, then interstitial — alias for major taps (export, save, etc.).
Future<void> runMajorActionAsync(BuildContext context, Future<void> Function() action) =>
    runWithInterstitialAsync(context, action);
