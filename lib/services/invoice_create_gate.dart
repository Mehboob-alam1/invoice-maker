import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../navigation/app_page_route.dart';
import '../providers/invoice_provider.dart';
import '../screens/subscription/subscription_plans_screen.dart';
import 'premium_upsell_service.dart';

/// Returns `true` if the user may create another invoice today.
Future<bool> ensureInvoiceQuotaOrPrompt(BuildContext context) async {
  final provider = context.read<InvoiceProvider>();
  if (provider.canCreateInvoiceToday) return true;

  final strings = AppStrings.read(context);
  final upgrade = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(strings.dailyInvoiceLimitTitle),
      content: Text(strings.dailyInvoiceLimitBody(provider.dailyInvoiceLimit)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.viewPlans)),
      ],
    ),
  );
  if (upgrade == true && context.mounted) {
    await Navigator.of(context).push(appPageRoute(const SubscriptionPlansScreen()));
  } else if (context.mounted) {
    await PremiumUpsellService.maybeShow(context, forceIfLowQuota: true);
  }
  return false;
}

/// Returns `true` if the user's plan includes Create with AI (Premium or Pro).
Future<bool> ensurePaidAiAccessOrPrompt(BuildContext context) async {
  final provider = context.read<InvoiceProvider>();
  if (provider.subscriptionTier.canUseAiInvoice) return true;

  final strings = AppStrings.read(context);
  final upgrade = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(strings.aiPaidRequiredTitle),
      content: Text(strings.aiPaidRequiredBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.viewPlans)),
      ],
    ),
  );
  if (upgrade == true && context.mounted) {
    await Navigator.of(context).push(appPageRoute(const SubscriptionPlansScreen()));
  }
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
      builder: (ctx) => AlertDialog(
        title: Text(strings.aiInputTooLongTitle),
        content: Text(strings.aiInputTooLongBody(maxChars, provider.maxAiTokensPerRequest)),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.ok))],
      ),
    );
    return false;
  }

  final estimated = InvoiceProvider.estimateAiTokensForInput(inputText);
  if (provider.canAffordAiGeneration(estimated)) return true;

  final upgrade = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(strings.aiMonthlyLimitTitle),
      content: Text(
        strings.aiMonthlyLimitBody(
          provider.aiTokensRemainingThisMonth,
          provider.monthlyAiTokenLimit,
          estimated,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.viewPlans)),
      ],
    ),
  );
  if (upgrade == true && context.mounted) {
    await Navigator.of(context).push(appPageRoute(const SubscriptionPlansScreen()));
  }
  return false;
}
