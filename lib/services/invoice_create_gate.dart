import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ad_config.dart';
import '../ads/ad_placement.dart';
import '../ads/ad_remote_config.dart';
import '../l10n/app_strings.dart';
import '../ads/ad_flows.dart';
import '../widgets/app_dialog.dart';
import '../services/paywall_analytics.dart';
import '../models/subscription_tier.dart';
import '../providers/invoice_provider.dart';
/// Returns `true` if the user may create another invoice today.
Future<bool> ensureInvoiceQuotaOrPrompt(BuildContext context) async {
  final provider = context.read<InvoiceProvider>();
  if (provider.canCreateInvoiceToday) return true;

  final strings = AppStrings.read(context);
  final watchOn = provider.featureTier == SubscriptionTier.free &&
      _rewardedPlacementOn(AdPlacement.rewardedExtraInvoice);
  final choice = await showDialog<_CapChoice>(
    context: context,
    builder: (ctx) => AppDialog(
      icon: Icons.receipt_long_rounded,
      tone: AppDialogTone.warning,
      title: strings.dailyInvoiceLimitTitle,
      message: strings.dailyInvoiceLimitBody(provider.dailyInvoiceLimit),
      actions: [
        AppDialogAction(
          label: watchOn ? strings.goPro : strings.viewPlans,
          icon: Icons.workspace_premium_rounded,
          onPressed: () => Navigator.pop(ctx, _CapChoice.upgrade),
        ),
        if (watchOn)
          AppDialogAction(
            label: strings.watchAdForInvoice,
            icon: Icons.play_circle_outline_rounded,
            style: AppDialogActionStyle.outlined,
            onPressed: () => Navigator.pop(ctx, _CapChoice.watch),
          ),
        AppDialogAction(
          label: strings.cancel,
          style: AppDialogActionStyle.text,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return false;
  if (choice == _CapChoice.watch) {
    final earned = await _watchRewarded(context, AdPlacement.rewardedExtraInvoice);
    if (!context.mounted || !earned) return false;
    context.read<InvoiceProvider>().grantExtraInvoiceToday();
    return context.read<InvoiceProvider>().canCreateInvoiceToday;
  }
  await openPaywall(context, source: PaywallSource.invoiceCap);
  return false;
}

/// Returns `true` if the user can open Create with AI (free credits or paid allowance left).
Future<bool> ensurePaidAiAccessOrPrompt(BuildContext context) async {
  final provider = context.read<InvoiceProvider>();
  if (provider.canOpenCreateWithAi) return true;

  final strings = AppStrings.read(context);
  final isFree = provider.featureTier == SubscriptionTier.free;
  final watchOn = isFree && _rewardedPlacementOn(AdPlacement.rewardedAiCredit);
  final choice = await showDialog<_CapChoice>(
    context: context,
    builder: (ctx) => AppDialog(
      icon: Icons.auto_awesome_rounded,
      tone: AppDialogTone.warning,
      title: isFree ? strings.aiMonthlyLimitTitle : strings.aiPaidRequiredTitle,
      message: isFree
          ? strings.aiFreeCreditsUsedBody(provider.monthlyAiCredits)
          : strings.aiPaidRequiredBody,
      actions: [
        AppDialogAction(
          label: watchOn ? strings.goPro : strings.viewPlans,
          icon: Icons.workspace_premium_rounded,
          onPressed: () => Navigator.pop(ctx, _CapChoice.upgrade),
        ),
        if (watchOn)
          AppDialogAction(
            label: strings.watchAdForAiCredit,
            icon: Icons.play_circle_outline_rounded,
            style: AppDialogActionStyle.outlined,
            onPressed: () => Navigator.pop(ctx, _CapChoice.watch),
          ),
        AppDialogAction(
          label: strings.cancel,
          style: AppDialogActionStyle.text,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return false;
  if (choice == _CapChoice.watch) {
    final earned = await _watchRewarded(context, AdPlacement.rewardedAiCredit);
    if (!context.mounted || !earned) return false;
    context.read<InvoiceProvider>().grantBonusAiCredit();
    return context.read<InvoiceProvider>().canOpenCreateWithAi;
  }
  await openPaywall(context, source: PaywallSource.aiCap);
  return false;
}

/// Validates monthly AI token budget and per-request size before generating.
Future<bool> ensureAiGenerationAllowed(BuildContext context, {required String inputText}) async {
  final provider = context.read<InvoiceProvider>();
  if (!await ensurePaidAiAccessOrPrompt(context)) return false;
  if (!context.mounted) return false;

  final strings = AppStrings.read(context);
  final maxChars = provider.maxAiInputCharacters;
  if (inputText.trim().length > maxChars) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.short_text_rounded,
        tone: AppDialogTone.warning,
        title: strings.aiInputTooLongTitle,
        message: strings.aiInputTooLongBody(maxChars, provider.maxAiTokensPerRequest),
        actions: [
          AppDialogAction(label: strings.ok, onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
    return false;
  }

  final estimated = InvoiceProvider.estimateAiTokensForInput(inputText);
  if (provider.canAffordAiGeneration(estimated)) return true;

  final watchOn = provider.featureTier == SubscriptionTier.free &&
      _rewardedPlacementOn(AdPlacement.rewardedAiCredit);
  final choice = await showDialog<_CapChoice>(
    context: context,
    builder: (ctx) => AppDialog(
      icon: Icons.auto_awesome_rounded,
      tone: AppDialogTone.warning,
      title: strings.aiMonthlyLimitTitle,
      message: strings.aiMonthlyLimitBody(
        provider.aiTokensRemainingThisMonth,
        provider.monthlyAiTokenLimit,
        estimated,
      ),
      actions: [
        AppDialogAction(
          label: watchOn ? strings.goPro : strings.viewPlans,
          icon: Icons.workspace_premium_rounded,
          onPressed: () => Navigator.pop(ctx, _CapChoice.upgrade),
        ),
        if (watchOn)
          AppDialogAction(
            label: strings.watchAdForAiCredit,
            icon: Icons.play_circle_outline_rounded,
            style: AppDialogActionStyle.outlined,
            onPressed: () => Navigator.pop(ctx, _CapChoice.watch),
          ),
        AppDialogAction(
          label: strings.cancel,
          style: AppDialogActionStyle.text,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return false;
  if (choice == _CapChoice.watch) {
    final earned = await _watchRewarded(context, AdPlacement.rewardedAiCredit);
    if (!context.mounted || !earned) return false;
    final invoices = context.read<InvoiceProvider>();
    invoices.grantBonusAiCredit();
    return invoices.canAffordAiGeneration(estimated);
  }
  await openPaywall(context, source: PaywallSource.aiCap);
  return false;
}

enum _CapChoice { watch, upgrade }

bool _rewardedPlacementOn(AdPlacement placement) {
  return AdConfig.isSupported && AdRemoteConfig.instance.isPlacementWanted(placement);
}

Future<bool> _watchRewarded(BuildContext context, AdPlacement placement) async {
  final earned = await showPlacementRewarded(context, placement);
  if (!context.mounted) return false;
  if (earned) return true;
  final strings = AppStrings.read(context);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AppDialog(
      icon: Icons.hourglass_empty_rounded,
      tone: AppDialogTone.warning,
      title: strings.t('rewardedAdNotReadyTitle'),
      message: strings.t('rewardedAdNotReady'),
      actions: [
        AppDialogAction(label: strings.ok, onPressed: () => Navigator.pop(ctx)),
      ],
    ),
  );
  return false;
}
