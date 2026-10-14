import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';
import '../core/remote_config/remote_config_repository.dart';
import 'ad_service.dart';

/// After a major user action (save, share, navigate, etc.) on Free tier.
Future<void> afterMajorAction(BuildContext context) =>
    showInterstitialWithLoadingIfEligible(context);

/// Presents a preloaded interstitial. If none is cached yet, the action continues
/// and the next one keeps loading in the background.
Future<bool> showInterstitialWithLoadingIfEligible(BuildContext context) async {
  if (!context.mounted) return false;
  final tier = context.read<InvoiceProvider>().featureTier;
  final ads = AdService.instance;

  if (!ads.shouldAttemptInterstitial(tier) || !ads.interstitialReady) {
    ads.preloadInterstitial();
    return false;
  }

  return ads.showInterstitialIfEligible(tier: tier);
}

/// Opens a settings list. An interstitial runs only when
/// `ad_interstitial_nav_screens` is on.
Future<void> runSettingsNavigation(BuildContext context, VoidCallback action) async {
  action();
  if (!RemoteConfigRepository.instance.interstitialNavScreens) return;
  await showInterstitialWithLoadingIfEligible(context);
}

/// Runs [action], then shows an interstitial for non-Pro users.
Future<void> runWithInterstitial(BuildContext context, VoidCallback action) async {
  action();
  await showInterstitialWithLoadingIfEligible(context);
}

Future<void> runWithInterstitialAsync(BuildContext context, Future<void> Function() action) async {
  await action();
  if (!context.mounted) return;
  await showInterstitialWithLoadingIfEligible(context);
}

/// Runs async work, then interstitial — alias for major taps (export, save, etc.).
Future<void> runMajorActionAsync(BuildContext context, Future<void> Function() action) =>
    runWithInterstitialAsync(context, action);
