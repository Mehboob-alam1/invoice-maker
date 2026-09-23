import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/invoice.dart';
import '../models/invoice_template.dart';
import '../providers/invoice_provider.dart';
import '../screens/subscription/subscription_plans_screen.dart';
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

/// Returns true if [templateId] is free or user's tier includes premium templates.
Future<bool> confirmPremiumTemplateUse(BuildContext context, InvoiceTemplateId templateId) async {
  final provider = context.read<InvoiceProvider>();
  if (InvoiceTemplateInfo.canUseTemplate(templateId, provider.subscriptionTier)) return true;

  final strings = AppStrings.read(context);
  final unlock = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(strings.premiumTemplateRequired),
      content: Text(strings.premiumTemplateRequiredBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.viewPlans)),
      ],
    ),
  );
  if (unlock != true || !context.mounted) return false;

  await Navigator.of(context).push(appPageRoute(const SubscriptionPlansScreen()));
  if (!context.mounted) return false;
  return InvoiceTemplateInfo.canUseTemplate(templateId, context.read<InvoiceProvider>().subscriptionTier);
}

/// @deprecated Use [confirmPremiumTemplateUse].
Future<bool> confirmProTemplateUse(BuildContext context, InvoiceTemplateId templateId) =>
    confirmPremiumTemplateUse(context, templateId);
