import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../ads/ad_flows.dart';
import '../ads/ad_placement.dart';
import '../ads/ad_remote_config.dart';
import '../ads/ad_service.dart';
import '../l10n/app_strings.dart';
import '../models/invoice.dart';
import '../models/invoice_template.dart';
import '../providers/invoice_provider.dart';
import 'invoice_document_view.dart';

Future<void> showInvoiceTemplatePreviewSheet(
  BuildContext context, {
  required Invoice invoice,
  required InvoiceTemplateId templateId,
  VoidCallback? onApplied,
}) async {
  final strings = AppStrings.read(context);
  final provider = context.read<InvoiceProvider>();
  final previewInvoice = invoice.copyWith(templateId: templateId.name);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              strings.previewTemplate(strings.t(InvoiceTemplateInfo.infoFor(templateId).labelKey)),
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                InvoiceDocumentView(invoice: previewInvoice, provider: provider, strings: strings),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: FilledButton(
                onPressed: () async {
                  final ok = await confirmPremiumTemplateUse(ctx, templateId);
                  if (!ok || !ctx.mounted) return;
                  await showPlacementInterstitial(ctx, AdPlacement.interstitialUseTemplate);
                  if (!ctx.mounted) return;
                  onApplied?.call();
                  Navigator.pop(ctx);
                },
                child: Text(strings.useThisTemplate),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Free templates are always allowed. Paid plans unlock every template.
/// Free users can watch a rewarded ad to use one premium template a single time.
Future<bool> confirmPremiumTemplateUse(BuildContext context, InvoiceTemplateId templateId) async {
  final provider = context.read<InvoiceProvider>();
  if (!InvoiceTemplateInfo.requiresPro(templateId)) return true;
  if (provider.subscriptionTier.canUsePremiumTemplates) return true;

  final strings = AppStrings.read(context);
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final rewardedOn = AdRemoteConfig.instance.isPlacementEnabled(AdPlacement.rewardedTemplate);
      return AlertDialog(
        icon: Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 32),
        title: Text(strings.t('templateUnlockTitle')),
        content: Text(
          rewardedOn ? strings.t('templateUnlockOnceBody') : strings.premiumTemplateRequiredBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(strings.cancel)),
          if (rewardedOn)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'watch'),
              child: Text(strings.t('watchAd')),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'pro'),
            child: Text(strings.t('unlockAllTemplates')),
          ),
        ],
      );
    },
  );
  if (!context.mounted || choice == null) return false;

  if (choice == 'pro') {
    await openPaywall(context);
    if (!context.mounted) return false;
    return context.read<InvoiceProvider>().subscriptionTier.canUsePremiumTemplates;
  }

  final earned = await AdService.instance.showRewarded(
    adUnitId: AdRemoteConfig.instance.rewardedAdUnitId,
  );
  if (!context.mounted) return earned;
  if (!earned) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('rewardedAdNotReady'))),
    );
  }
  return earned;
}

/// @deprecated Use [confirmPremiumTemplateUse].
Future<bool> confirmProTemplateUse(BuildContext context, InvoiceTemplateId templateId) =>
    confirmPremiumTemplateUse(context, templateId);
