import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/invoice.dart';
import '../models/invoice_template.dart';
import '../providers/invoice_provider.dart';
import 'invoice_template_preview_sheet.dart';

class TemplatePicker extends StatelessWidget {
  const TemplatePicker({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.buildPreviewInvoice,
  });

  final InvoiceTemplateId selected;
  final ValueChanged<InvoiceTemplateId> onChanged;
  final Invoice Function() buildPreviewInvoice;

  Future<void> _openSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
        child: _TemplatePickerSheet(
          selected: selected,
          buildPreviewInvoice: buildPreviewInvoice,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final info = InvoiceTemplateInfo.infoFor(selected);
    final maxW = MediaQuery.sizeOf(context).width * 0.78;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.invoiceTemplate, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW.clamp(240, 320)),
            child: InkWell(
              onTap: () => _openSheet(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _TemplatePreviewThumb(info: info, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.t(info.labelKey),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            strings.browseAllTemplates,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.unfold_more_rounded, size: 22, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplatePickerSheet extends StatelessWidget {
  const _TemplatePickerSheet({
    required this.selected,
    required this.buildPreviewInvoice,
    required this.onChanged,
  });

  final InvoiceTemplateId selected;
  final Invoice Function() buildPreviewInvoice;
  final ValueChanged<InvoiceTemplateId> onChanged;

  Future<void> _preview(BuildContext context, InvoiceTemplateId id) {
    return showInvoiceTemplatePreviewSheet(
      context,
      invoice: buildPreviewInvoice(),
      templateId: id,
      onApplied: () => onChanged(id),
    );
  }

  Future<void> _useTemplate(BuildContext context, InvoiceTemplateId id) async {
    final ok = await confirmProTemplateUse(context, id);
    if (!ok || !context.mounted) return;
    onChanged(id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final tier = context.watch<InvoiceProvider>().subscriptionTier;
    final hasPremiumTemplates = tier.canUsePremiumTemplates;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(strings.chooseTemplate, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(strings.templatesSheetSubtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Text(strings.invoiceTemplate, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(strings.freeTemplatesHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        _TemplateGrid(
          templates: InvoiceTemplateInfo.freeTemplates,
          selected: selected,
          onPreview: (id) => _preview(context, id),
          onUse: (id) => _useTemplate(context, id),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(strings.premiumTemplates, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (!hasPremiumTemplates) ...[
              const SizedBox(width: 8),
              Icon(Icons.workspace_premium, size: 18, color: theme.colorScheme.primary),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(strings.previewAnyTemplateHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        _TemplateGrid(
          templates: InvoiceTemplateInfo.premiumTemplates,
          selected: selected,
          onPreview: (id) => _preview(context, id),
          onUse: (id) => _useTemplate(context, id),
        ),
      ],
    );
  }
}

class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid({
    required this.templates,
    required this.selected,
    required this.onPreview,
    required this.onUse,
  });

  final List<InvoiceTemplateInfo> templates;
  final InvoiceTemplateId selected;
  final ValueChanged<InvoiceTemplateId> onPreview;
  final ValueChanged<InvoiceTemplateId> onUse;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        const columns = 2;
        final tileWidth = (constraints.maxWidth - spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: templates
              .map(
                (template) => SizedBox(
                  width: tileWidth,
                  child: _TemplateGridCard(
                    template: template,
                    selected: template.id == selected,
                    onPreview: () => onPreview(template.id),
                    onUse: () => onUse(template.id),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _TemplateGridCard extends StatelessWidget {
  const _TemplateGridCard({
    required this.template,
    required this.selected,
    required this.onPreview,
    required this.onUse,
  });

  final InvoiceTemplateInfo template;
  final bool selected;
  final VoidCallback onPreview;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.12);

    return Material(
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.06) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPreview,
              child: Stack(
                children: [
                  _TemplatePreviewThumb(info: template, size: 68, fullWidth: true),
                  if (selected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.check, size: 13, color: Colors.white),
                      ),
                    ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(strings.preview, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.t(template.labelKey),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (template.proOnly)
                  Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: onUse,
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 11)),
                child: Text(strings.useThisTemplate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePreviewThumb extends StatelessWidget {
  const _TemplatePreviewThumb({
    required this.info,
    required this.size,
    this.fullWidth = false,
  });

  final InvoiceTemplateInfo info;
  final double size;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = info.previewGradient;

    if (gradient != null) {
      return Container(
        height: size,
        width: fullWidth ? double.infinity : size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
      );
    }

    return Container(
      height: size,
      width: fullWidth ? double.infinity : size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: switch (info.id) {
        InvoiceTemplateId.modern => Column(
            children: [
              Container(
                height: size * 0.32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
              ),
              Expanded(child: Container(color: theme.cardColor)),
            ],
          ),
        InvoiceTemplateId.minimal => Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, width: 28, color: theme.dividerColor),
                const Spacer(),
                Container(height: 3, width: double.infinity, color: theme.dividerColor.withValues(alpha: 0.5)),
                const SizedBox(height: 4),
                Container(height: 3, width: double.infinity, color: theme.dividerColor.withValues(alpha: 0.35)),
              ],
            ),
          ),
        _ => Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
      },
    );
  }
}
