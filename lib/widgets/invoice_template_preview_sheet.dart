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
import '../services/paywall_analytics.dart';
import '../services/referral_service.dart';
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
                  final provider = ctx.read<InvoiceProvider>();
                  final already = provider.canUseTemplate(templateId);
                  final ok = await confirmPremiumTemplateUse(ctx, templateId);
                  if (!ok || !ctx.mounted) return;
                  if (already) {
                    await showPlacementInterstitial(ctx, AdPlacement.interstitialUseTemplate);
                  }
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

/// Free templates need no ad. A premium template needs one rewarded ad for this app session.
Future<bool> confirmPremiumTemplateUse(BuildContext context, InvoiceTemplateId templateId) async {
  final provider = context.read<InvoiceProvider>();
  if (provider.canUseTemplate(templateId)) return true;

  final strings = AppStrings.read(context);
  final rewardedOn = AdRemoteConfig.instance.isPlacementEnabled(AdPlacement.rewardedTemplate);
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => _TemplateChoiceDialog(
      icon: Icons.lock_open_rounded,
      iconColors: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
      title: strings.t('templateUnlockTitle'),
      body: rewardedOn ? strings.t('templateUnlockOnceBody') : strings.premiumTemplateRequiredBody,
      primaryLabel: rewardedOn ? strings.t('watchAdToUse') : null,
      primaryIcon: Icons.play_circle_fill_rounded,
      primaryValue: 'watch',
      tokenLabel: provider.templateTokens > 0 ? strings.useTemplateToken : null,
      secondaryLabel: strings.t('unlockAllTemplates'),
      secondaryIcon: Icons.workspace_premium_rounded,
      secondaryValue: 'pro',
      cancelLabel: strings.cancel,
    ),
  );
  if (!context.mounted || choice == null) return false;

  if (choice == 'token') {
    final unlocked = await ReferralService.instance.spendTemplateToken(templateId);
    return unlocked && context.mounted && context.read<InvoiceProvider>().canUseTemplate(templateId);
  }

  if (choice == 'pro') {
    await openPaywall(context, source: PaywallSource.template);
    if (!context.mounted) return false;
    return context.read<InvoiceProvider>().canUseTemplate(templateId);
  }

  final earned = await AdService.instance.showRewarded(
    adUnitId: AdRemoteConfig.instance.rewardedAdUnitId,
  );
  if (!context.mounted) return false;
  if (!earned) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _TemplateChoiceDialog(
        icon: Icons.lock_outline_rounded,
        iconColors: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
        title: strings.t('rewardedAdNotReadyTitle'),
        body: strings.t('rewardedAdNotReady'),
        secondaryLabel: strings.ok,
        secondaryIcon: Icons.check_rounded,
        secondaryValue: 'ok',
      ),
    );
    return false;
  }

  context.read<InvoiceProvider>().unlockTemplate(templateId);
  if (!context.mounted) return true;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _TemplateChoiceDialog(
      icon: Icons.check_rounded,
      iconColors: const [Color(0xFF16A34A), Color(0xFF059669)],
      title: strings.t('templateUnlockedTitle'),
      body: strings.t('templateUnlockedBody'),
      secondaryLabel: strings.ok,
      secondaryIcon: Icons.check_rounded,
      secondaryValue: 'ok',
    ),
  );
  return true;
}

class _TemplateChoiceDialog extends StatelessWidget {
  const _TemplateChoiceDialog({
    required this.icon,
    required this.iconColors,
    required this.title,
    required this.body,
    this.primaryLabel,
    this.primaryIcon,
    this.primaryValue,
    this.tokenLabel,
    this.secondaryLabel,
    this.secondaryIcon,
    this.secondaryValue,
    this.cancelLabel,
  });

  final IconData icon;
  final List<Color> iconColors;
  final String title;
  final String body;
  final String? primaryLabel;
  final IconData? primaryIcon;
  final String? primaryValue;
  final String? tokenLabel;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final String? secondaryValue;
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: iconColors.first.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45, color: muted),
            ),
            const SizedBox(height: 22),
            if (primaryLabel != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, primaryValue),
                  icon: Icon(primaryIcon ?? Icons.play_circle_fill_rounded),
                  label: Text(primaryLabel!),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            if (primaryLabel != null && (tokenLabel != null || secondaryLabel != null)) const SizedBox(height: 10),
            if (tokenLabel != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'token'),
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: Text(tokenLabel!),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            if (tokenLabel != null && secondaryLabel != null) const SizedBox(height: 10),
            if (secondaryLabel != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: primaryLabel == null
                    ? FilledButton.icon(
                        onPressed: () => Navigator.pop(context, secondaryValue),
                        icon: Icon(secondaryIcon ?? Icons.check_rounded),
                        label: Text(secondaryLabel!),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context, secondaryValue),
                        icon: Icon(secondaryIcon ?? Icons.workspace_premium_rounded),
                        label: Text(secondaryLabel!),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
            if (cancelLabel != null)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(cancelLabel!),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// @deprecated Use [confirmPremiumTemplateUse].
Future<bool> confirmProTemplateUse(BuildContext context, InvoiceTemplateId templateId) =>
    confirmPremiumTemplateUse(context, templateId);
