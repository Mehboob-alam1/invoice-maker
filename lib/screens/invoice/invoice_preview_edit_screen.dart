import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_format.dart';
import '../../services/invoice_pdf_export.dart';
import '../../l10n/app_strings.dart';
import '../../models/client.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/invoice_template.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/client_form_sheet.dart';
import '../../widgets/item_form_sheet.dart';
import '../../widgets/invoice_document_view.dart';
import '../../widgets/invoice_template_preview_sheet.dart';
import '../../widgets/template_picker.dart';
import '../../navigation/app_page_route.dart';
import '../../navigation/invoice_flow.dart';
import '../../services/premium_upsell_service.dart';
import '../../ads/ad_action.dart';
import '../subscription/pro_paywall_screen.dart';
import 'invoice_detail_screen.dart';

@Deprecated('Use navigateAfterInvoiceCreated from invoice_flow.dart')
void openInvoicePreviewAfterCreate(BuildContext context, String invoiceId) {
  navigateAfterInvoiceCreated(context, invoiceId);
}

class InvoicePreviewEditScreen extends StatefulWidget {
  const InvoicePreviewEditScreen({
    super.key,
    required this.invoiceId,
    this.justCreated = false,
  });

  final String invoiceId;
  final bool justCreated;

  @override
  State<InvoicePreviewEditScreen> createState() => _InvoicePreviewEditScreenState();
}

class _InvoicePreviewEditScreenState extends State<InvoicePreviewEditScreen> {
  Invoice? _draft;
  late final TextEditingController _notes;
  late final TextEditingController _paymentTerms;
  late final TextEditingController _poNumber;
  late final TextEditingController _taxRate;
  late final TextEditingController _invoiceNumber;
  bool _editExpanded = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController();
    _paymentTerms = TextEditingController();
    _poNumber = TextEditingController();
    _taxRate = TextEditingController();
    _invoiceNumber = TextEditingController();
    _editExpanded = widget.justCreated;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromProvider();
      if (widget.justCreated) _schedulePostCreateExtras();
    });
  }

  Future<void> _schedulePostCreateExtras() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    await PremiumUpsellService.maybeShow(context, forceIfLowQuota: true);
    if (!mounted) return;
    await showInterstitialWithLoadingIfEligible(context);
  }

  void _loadFromProvider() {
    final invoice = context.read<InvoiceProvider>().invoiceById(widget.invoiceId);
    if (invoice == null || !mounted) return;
    setState(() {
      _draft = invoice;
      _notes.text = invoice.notes ?? '';
      _paymentTerms.text = invoice.paymentTerms ?? '';
      _poNumber.text = invoice.poNumber ?? '';
      _taxRate.text = invoice.taxRate > 0 ? invoice.taxRate.toString() : '';
      _invoiceNumber.text = invoice.number;
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    _paymentTerms.dispose();
    _poNumber.dispose();
    _taxRate.dispose();
    _invoiceNumber.dispose();
    super.dispose();
  }

  String? _emptyToNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  Invoice _buildDraftInvoice([Invoice? source]) {
    final base = source ?? _draft!;
    final rate = double.tryParse(_taxRate.text.trim()) ?? 0;
    return base.copyWith(
      number: _invoiceNumber.text.trim().isEmpty ? base.number : _invoiceNumber.text.trim(),
      taxRate: rate,
      paymentTerms: _emptyToNull(_paymentTerms.text),
      poNumber: _emptyToNull(_poNumber.text),
      notes: _emptyToNull(_notes.text),
    );
  }

  Future<bool> _save({bool quiet = false}) async {
    if (_draft == null) return false;
    final template = _draft!.template;
    final tier = context.read<InvoiceProvider>().subscriptionTier;
    if (!InvoiceTemplateInfo.canUseTemplate(template, tier)) {
      final ok = await confirmProTemplateUse(context, template);
      if (!ok || !mounted) return false;
    }
    final updated = _buildDraftInvoice();
    context.read<InvoiceProvider>().updateInvoice(updated);
    setState(() => _draft = updated);
    if (!quiet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.read(context).saveChanges)),
      );
    }
    return true;
  }

  Future<void> _openInvoiceDetail() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final ok = await _save(quiet: true);
    if (!ok || !mounted) {
      setState(() => _finishing = false);
      return;
    }
    HapticFeedback.lightImpact();
    await showInterstitialWithLoadingIfEligible(context);
    if (!mounted) {
      setState(() => _finishing = false);
      return;
    }
    await Navigator.of(context).pushReplacement(
      appInvoiceFlowRoute<void>(
        InvoiceDetailScreen(invoiceId: widget.invoiceId),
        adScopeKey: 'invoice_detail_${widget.invoiceId}',
      ),
    );
  }

  Future<void> _backToHome() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await _save(quiet: true);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    await showInterstitialWithLoadingIfEligible(context);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _exportPdf({required bool share}) async {
    if (_draft == null) return;
    await runMajorActionAsync(
      context,
      () => InvoicePdfExport.export(context, _buildDraftInvoice(), share: share),
    );
  }

  Future<void> _editClient() async {
    if (_draft == null) return;
    final result = await showClientFormSheet(context, client: _draft!.client);
    if (result == null || !mounted) return;
    final updatedClient = Client(
      id: _draft!.client.id,
      name: result.name,
      phone: result.phone,
      email: result.email,
      address: result.address,
      taxId: result.taxId,
    );
    context.read<InvoiceProvider>().updateClient(updatedClient);
    setState(() => _draft = _draft!.copyWith(client: updatedClient));
  }

  Future<void> _editItem(int index) async {
    if (_draft == null) return;
    final item = await showItemFormSheet(
      context,
      item: _draft!.items[index],
      currencyCode: _draft!.currency,
      onCurrencyChanged: (c) => setState(() => _draft = _draft!.copyWith(currency: c)),
    );
    if (item == null || !mounted) return;
    final items = List<InvoiceItem>.of(_draft!.items);
    items[index] = item;
    setState(() => _draft = _draft!.copyWith(items: items));
  }

  Future<void> _addItem() async {
    final item = await showItemFormSheet(
      context,
      currencyCode: _draft!.currency,
      onCurrencyChanged: (c) => setState(() => _draft = _draft!.copyWith(currency: c)),
    );
    if (item == null || !mounted || _draft == null) return;
    setState(() => _draft = _draft!.copyWith(items: [..._draft!.items, item]));
  }

  void _removeItem(int index) {
    if (_draft == null || _draft!.items.length <= 1) return;
    final items = List<InvoiceItem>.of(_draft!.items)..removeAt(index);
    setState(() => _draft = _draft!.copyWith(items: items));
  }

  Future<void> _pickDueDate() async {
    if (_draft == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft!.dueDate ?? _draft!.date.add(const Duration(days: 14)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _draft = _draft!.copyWith(dueDate: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final strings = context.l10n;
    final synced = provider.invoiceById(widget.invoiceId);
    if (_draft == null && synced != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProvider());
    }
    final draft = _draft ?? synced;
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.invoice)),
        body: Center(child: Text(strings.invoiceDeleted)),
      );
    }

    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final previewInvoice = _buildDraftInvoice(draft);

    return PopScope(
      canPop: !widget.justCreated || _finishing,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !widget.justCreated) return;
        await _backToHome();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(strings.previewInvoice),
        actions: [
          IconButton(
            tooltip: strings.printPdf,
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _exportPdf(share: false),
          ),
          IconButton(
            tooltip: strings.sharePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _exportPdf(share: true),
          ),
          if (!widget.justCreated)
            IconButton(
              tooltip: strings.viewInvoice,
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => runWithInterstitial(context, () {
                Navigator.of(context).pushReplacement(
                  appPageRoute<void>(
                    InvoiceDetailScreen(invoiceId: widget.invoiceId),
                    adScopeKey: 'invoice_detail_${widget.invoiceId}',
                  ),
                );
              }),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (widget.justCreated)
            Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.invoiceCreatedTitle,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(strings.invoiceCreatedBanner, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.justCreated) const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: InvoiceDocumentView(invoice: previewInvoice, provider: provider, strings: strings),
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            initiallyExpanded: _editExpanded,
            onExpansionChanged: (v) => setState(() => _editExpanded = v),
            title: Text(strings.editInvoiceForPdf, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.client),
                subtitle: Text(draft.client.name),
                trailing: TextButton(onPressed: _editClient, child: Text(strings.editClient)),
              ),
              TextField(
                controller: _invoiceNumber,
                decoration: InputDecoration(labelText: strings.invoiceNumber),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.dueDate),
                subtitle: Text(
                  draft.dueDate != null
                      ? DateFormat.yMMMd(provider.languageCode).format(draft.dueDate!)
                      : '—',
                ),
                trailing: TextButton(onPressed: _pickDueDate, child: Text(strings.date)),
              ),
              TextField(
                controller: _taxRate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: strings.taxRate),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _poNumber,
                decoration: InputDecoration(labelText: strings.poNumber),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _paymentTerms,
                decoration: InputDecoration(labelText: strings.paymentTerms, hintText: strings.paymentTermsHint),
                maxLines: 2,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: strings.notesOptional, hintText: strings.notesHint),
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (context.watch<InvoiceProvider>().subscriptionTier.canCustomizeTemplates)
                TemplatePicker(
                  selected: draft.template,
                  onChanged: (t) => setState(() => _draft = _draft!.copyWith(templateId: t.name)),
                  buildPreviewInvoice: () => _buildDraftInvoice(),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: Text(strings.customizeProOnly),
                  trailing: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      appPageRoute(const ProPaywallScreen()),
                    ),
                    child: Text(strings.viewPlans),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(strings.items, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(strings.currency, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
                  const SizedBox(width: 6),
                  DropdownButton<String>(
                    value: CurrencyFormat.supportedCodes.contains(draft.currency) ? draft.currency : 'USD',
                    underline: const SizedBox.shrink(),
                    items: CurrencyFormat.supportedCodes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _draft = _draft!.copyWith(currency: v));
                    },
                  ),
                  TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: Text(strings.newItem)),
                ],
              ),
              ...List.generate(draft.items.length, (i) {
                final item = draft.items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.description),
                    subtitle: Text(
                      '${item.quantity} × ${CurrencyFormat.format(draft.currency, item.unitCost)} = ${CurrencyFormat.format(draft.currency, item.total)}',
                      style: TextStyle(color: muted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editItem(i)),
                        if (draft.items.length > 1)
                          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _removeItem(i)),
                      ],
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${strings.grandTotal}: ${CurrencyFormat.format(draft.currency, previewInvoice.total)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: widget.justCreated ? _JustCreatedActions(
            finishing: _finishing,
            onOpenDetail: _openInvoiceDetail,
            onShare: () => _exportPdf(share: true),
            onHome: _backToHome,
          ) : FilledButton.icon(
            onPressed: () => runMajorActionAsync(context, () async {
              await _save();
            }),
            icon: const Icon(Icons.save_outlined),
            label: Text(strings.saveChanges),
          ),
        ),
      ),
      ),
    );
  }
}

class _JustCreatedActions extends StatelessWidget {
  const _JustCreatedActions({
    required this.finishing,
    required this.onOpenDetail,
    required this.onShare,
    required this.onHome,
  });

  final bool finishing;
  final VoidCallback onOpenDetail;
  final VoidCallback onShare;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: finishing ? null : onOpenDetail,
          icon: finishing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.arrow_forward_rounded),
          label: Text(strings.continueToInvoice),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: finishing ? null : onShare,
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(strings.sharePdf),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: finishing ? null : onHome,
                child: Text(strings.backToInvoices),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
