import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../widgets/blue_screen.dart';
import '../../widgets/client_form_sheet.dart';
import '../../widgets/item_form_sheet.dart';
import '../../widgets/invoice_document_view.dart';
import '../../widgets/invoice_template_preview_sheet.dart';
import '../../widgets/template_picker.dart';
import '../../navigation/app_page_route.dart';
import '../../navigation/invoice_flow.dart';
import '../../services/premium_upsell_service.dart';
import '../../ads/ad_action.dart';
import '../../widgets/ui/app_page_shell.dart';
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
      _syncDraftFromProvider();
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

  Invoice? _invoiceFromProvider() {
    return context.read<InvoiceProvider>().invoiceById(widget.invoiceId);
  }

  Invoice? _workingInvoice() => _draft ?? _invoiceFromProvider();

  void _syncDraftFromProvider() {
    if (_draft != null) return;
    final invoice = _invoiceFromProvider();
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

  void _commitDraft() {
    final base = _workingInvoice();
    if (base == null) return;
    final updated = _buildDraftInvoice(base);
    context.read<InvoiceProvider>().updateInvoice(updated);
    if (!mounted) return;
    setState(() => _draft = updated);
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
    final base = _workingInvoice();
    if (base == null) return false;
    final template = base.template;
    final tier = context.read<InvoiceProvider>().subscriptionTier;
    if (!InvoiceTemplateInfo.canUseTemplate(template, tier)) {
      final ok = await confirmProTemplateUse(context, template);
      if (!ok || !mounted) return false;
    }
    final updated = _buildDraftInvoice(base);
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
    _syncDraftFromProvider();
    final base = _workingInvoice();
    if (base == null) return;
    final snapshot = _buildDraftInvoice(base);
    await runMajorActionAsync(
      context,
      () => InvoicePdfExport.export(context, snapshot, share: share),
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
    _commitDraft();
  }

  Future<void> _editItem(int index) async {
    _syncDraftFromProvider();
    final draft = _draft;
    if (draft == null) return;
    final item = await showItemFormSheet(
      context,
      item: draft.items[index],
      currencyCode: draft.currency,
      onCurrencyChanged: (c) => setState(() => _draft = _draft!.copyWith(currency: c)),
    );
    if (item == null || !mounted || _draft == null) return;
    final items = List<InvoiceItem>.of(_draft!.items);
    items[index] = item;
    setState(() => _draft = _draft!.copyWith(items: items));
    _commitDraft();
  }

  Future<void> _addItem() async {
    _syncDraftFromProvider();
    final draft = _draft;
    if (draft == null) return;
    final item = await showItemFormSheet(
      context,
      currencyCode: draft.currency,
      onCurrencyChanged: (c) => setState(() => _draft = _draft!.copyWith(currency: c)),
    );
    if (item == null || !mounted || _draft == null) return;
    setState(() => _draft = _draft!.copyWith(items: [..._draft!.items, item]));
    _commitDraft();
  }

  void _removeItem(int index) {
    if (_draft == null || _draft!.items.length <= 1) return;
    final items = List<InvoiceItem>.of(_draft!.items)..removeAt(index);
    setState(() => _draft = _draft!.copyWith(items: items));
    _commitDraft();
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
      _commitDraft();
    }
  }

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  ThemeData _themed(BuildContext context) {
    final base = buildBlueTheme(Theme.of(context));
    final isDark = base.brightness == Brightness.dark;
    final text = GoogleFonts.spaceGroteskTextTheme(base.textTheme);
    final titleColor = isDark ? base.colorScheme.onSurface : BlueColors.navy;
    TextStyle? head(TextStyle? s, FontWeight w) =>
        s?.copyWith(fontWeight: w, letterSpacing: -0.4, color: titleColor);
    return base.copyWith(
      textTheme: text.copyWith(
        headlineSmall: head(text.headlineSmall, FontWeight.w800),
        titleLarge: head(text.titleLarge, FontWeight.w800),
        titleMedium: head(text.titleMedium, FontWeight.w800),
        titleSmall: head(text.titleSmall, FontWeight.w700),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: titleColor,
        ),
        iconTheme: IconThemeData(color: titleColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final strings = context.l10n;
    final synced = provider.invoiceById(widget.invoiceId);
    if (_draft == null && synced != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncDraftFromProvider());
    }
    final draft = _workingInvoice();
    final themed = _themed(context);

    if (draft == null) {
      return Theme(
        data: themed,
        child: Scaffold(
          appBar: AppBar(title: Text(strings.invoice)),
          body: AppPageShell(child: Center(child: Text(strings.invoiceDeleted))),
        ),
      );
    }

    final muted = themed.extension<AppSemanticColors>()?.textMuted;
    final previewInvoice = _buildDraftInvoice(draft);

    return Theme(
      data: themed,
      child: Builder(
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final size = MediaQuery.sizeOf(ctx);
          final width = size.width;
          final isDesktop = width >= 900;
          final isTablet = !isDesktop && width >= 700;
          final hPad = width < 360 ? 12.0 : 20.0;
          final maxW = isDesktop ? 1080.0 : 820.0;
          final bottomInset = MediaQuery.paddingOf(ctx).bottom;

          final banner = widget.justCreated ? _buildBanner(ctx, strings) : null;

          final preview = _BlueCard(
            padding: EdgeInsets.zero,
            clip: true,
            child: InvoiceDocumentView(
              invoice: previewInvoice,
              provider: provider,
              strings: strings,
            ),
          );

          final editCard = _buildEditCard(
            ctx,
            strings: strings,
            provider: provider,
            draft: draft,
            previewInvoice: previewInvoice,
            muted: muted,
            twoCol: isTablet,
          );

          Widget content;
          if (isDesktop) {
            content = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: preview),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: editCard),
              ],
            );
          } else {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [preview, const SizedBox(height: 16), editCard],
            );
          }

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
                  _AppBarAction(
                    tooltip: strings.printPdf,
                    icon: Icons.print_outlined,
                    onPressed: () => _exportPdf(share: false),
                  ),
                  _AppBarAction(
                    tooltip: strings.sharePdf,
                    icon: Icons.picture_as_pdf_outlined,
                    onPressed: () => _exportPdf(share: true),
                  ),
                  if (!widget.justCreated)
                    _AppBarAction(
                      tooltip: strings.viewInvoice,
                      icon: Icons.receipt_long_outlined,
                      onPressed: () => runWithInterstitial(context, () {
                        Navigator.of(context).pushReplacement(
                          appPageRoute<void>(
                            InvoiceDetailScreen(invoiceId: widget.invoiceId),
                            adScopeKey: 'invoice_detail_${widget.invoiceId}',
                          ),
                        );
                      }),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
              body: AppPageShell(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32 + bottomInset),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (banner != null) ...[banner, const SizedBox(height: 14)],
                          content,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 12),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isDesktop ? 560 : maxW),
                      child: widget.justCreated
                          ? _JustCreatedActions(
                        finishing: _finishing,
                        onOpenDetail: _openInvoiceDetail,
                        onShare: () => _exportPdf(share: true),
                        onHome: _backToHome,
                      )
                          : BlueGradientButton(
                        onPressed: () => runMajorActionAsync(context, () async {
                    await _save();
                  }),
                  icon: Icons.save_outlined,
                  label: strings.saveChanges,
                ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildBanner(BuildContext ctx, dynamic strings) {
    final theme = Theme.of(ctx);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BlueColors.bright, BlueColors.light, BlueColors.sky],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: BlueColors.bright.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.invoiceCreatedTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.invoiceCreatedBanner,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoUp(bool twoCol, Widget a, Widget b) {
    if (!twoCol) {
      return Column(children: [a, const SizedBox(height: 12), b]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
  }

  Widget _buildEditCard(
      BuildContext ctx, {
        required dynamic strings,
        required InvoiceProvider provider,
        required Invoice draft,
        required Invoice previewInvoice,
        required Color? muted,
        required bool twoCol,
      }) {
    final theme = Theme.of(ctx);
    final cs = theme.colorScheme;
    final clientName = draft.client.name.trim();
    final initial = clientName.isEmpty ? '?' : clientName.characters.first.toUpperCase();

    final clientTile = _InsetTile(
      leading: _GradientTile(
        size: 44,
        radius: 16,
        child: Text(
          initial,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      title: strings.client,
      subtitle: draft.client.name,
      trailing: _ChipButton(
        label: strings.editClient,
        icon: Icons.edit_outlined,
        onPressed: _editClient,
      ),
    );

    final dueTile = _InsetTile(
      leading: const _GradientTile(
        size: 44,
        radius: 16,
        child: Icon(Icons.event_rounded, color: Colors.white, size: 22),
      ),
      title: strings.dueDate,
      subtitle: draft.dueDate != null
          ? DateFormat.yMMMd(provider.languageCode).format(draft.dueDate!)
          : '—',
      trailing: _ChipButton(
        label: strings.date,
        icon: Icons.arrow_forward_rounded,
        onPressed: _pickDueDate,
      ),
    );

    final numberField = _blueField(
      ctx,
      controller: _invoiceNumber,
      label: strings.invoiceNumber,
      icon: Icons.tag_rounded,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onChanged: (_) => setState(() {}),
    );
    final taxField = _blueField(
      ctx,
      controller: _taxRate,
      label: strings.taxRate,
      icon: Icons.percent_rounded,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onChanged: (_) => setState(() {}),
    );
    final poField = _blueField(
      ctx,
      controller: _poNumber,
      label: strings.poNumber,
      icon: Icons.confirmation_number_outlined,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      onChanged: (_) => setState(() {}),
    );
    final termsField = _blueField(
      ctx,
      controller: _paymentTerms,
      label: strings.paymentTerms,
      hint: strings.paymentTermsHint,
      icon: Icons.payments_outlined,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: 2,
      onChanged: (_) => setState(() {}),
    );
    final notesField = _blueField(
      ctx,
      controller: _notes,
      label: strings.notesOptional,
      hint: strings.notesHint,
      icon: Icons.sticky_note_2_outlined,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: 3,
      onChanged: (_) => setState(() {}),
    );

    final canCustomize = context.watch<InvoiceProvider>().subscriptionTier.canCustomizeTemplates;

    return _BlueCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _editExpanded,
          onExpansionChanged: (v) => setState(() => _editExpanded = v),
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          leading: const _GradientTile(
            size: 40,
            radius: 14,
            child: Icon(Icons.tune_rounded, color: Colors.white, size: 20),
          ),
          title: Text(
            strings.editInvoiceForPdf,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _twoUp(twoCol, clientTile, dueTile),
            const SizedBox(height: 12),
            _twoUp(twoCol, numberField, taxField),
            const SizedBox(height: 12),
            poField,
            const SizedBox(height: 12),
            termsField,
            const SizedBox(height: 12),
            notesField,
            const SizedBox(height: 16),
            if (canCustomize)
              TemplatePicker(
                selected: draft.template,
                onChanged: (t) {
                  setState(() => _draft = _draft!.copyWith(templateId: t.name));
                  _commitDraft();
                },
                buildPreviewInvoice: () => _buildDraftInvoice(),
              )
            else
              _InsetTile(
                leading: const _GradientTile(
                  size: 44,
                  radius: 16,
                  child: Icon(Icons.lock_outline_rounded, color: Colors.white, size: 22),
                ),
                title: strings.customizeProOnly,
                trailing: _ChipButton(
                  label: strings.viewPlans,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => Navigator.push(
                    context,
                    appPageRoute(const ProPaywallScreen()),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  strings.items,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.currency,
                        style: theme.textTheme.labelMedium?.copyWith(color: muted),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: CurrencyFormat.supportedCodes.contains(draft.currency)
                              ? draft.currency
                              : 'USD',
                          isDense: true,
                          borderRadius: BorderRadius.circular(16),
                          items: CurrencyFormat.supportedCodes
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _draft = _draft!.copyWith(currency: v));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _ChipButton(
                  label: strings.newItem,
                  icon: Icons.add_rounded,
                  onPressed: _addItem,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(draft.items.length, (i) {
              final item = draft.items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BlueCard(
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Row(
                    children: [
                      _GradientTile(
                        size: 40,
                        radius: 14,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.quantity} × ${CurrencyFormat.format(draft.currency, item.unitCost)} = ${CurrencyFormat.format(draft.currency, item.total)}',
                              style: theme.textTheme.bodySmall?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: cs.primary,
                        onPressed: () => _editItem(i),
                      ),
                      if (draft.items.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: cs.error,
                          onPressed: () => _removeItem(i),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BlueColors.bright, BlueColors.sky],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: BlueColors.bright.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  '${strings.grandTotal}: ${CurrencyFormat.format(draft.currency, previewInvoice.total)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

Widget _blueField(
    BuildContext ctx, {
      required TextEditingController controller,
      required String label,
      required IconData icon,
      required TextInputType keyboardType,
      required TextInputAction textInputAction,
      String? hint,
      int maxLines = 1,
      ValueChanged<String>? onChanged,
    }) {
  final cs = Theme.of(ctx).colorScheme;
  OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: w),
  );
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    maxLines: maxLines,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: cs.primary.withValues(alpha: 0.06),
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines - 1) * 20.0 : 0),
        child: Icon(icon, color: cs.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(Colors.transparent, 1),
      enabledBorder: border(cs.primary.withValues(alpha: 0.10), 1),
      focusedBorder: border(cs.primary, 2),
    ),
  );
}

class _BlueCard extends StatelessWidget {
  const _BlueCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      padding: padding,
      child: child,
    );
  }
}

class _GradientTile extends StatelessWidget {
  const _GradientTile({
    required this.child,
    this.size = 44,
    this.radius = 16,
  });

  final Widget child;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BlueColors.bright, BlueColors.sky],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

class _InsetTile extends StatelessWidget {
  const _InsetTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(color: muted),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: cs.primary.withValues(alpha: 0.08),
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    final cs = Theme.of(context).colorScheme;
    final outlinedStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: cs.primary,
      side: BorderSide(color: cs.primary.withValues(alpha: 0.35), width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlueGradientButton(
          onPressed: finishing ? null : onOpenDetail,
          icon: Icons.arrow_forward_rounded,
          loading: finishing,
          label: strings.continueToInvoice,
        ),        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: finishing ? null : onShare,
                style: outlinedStyle,
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(
                  strings.sharePdf,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: finishing ? null : onHome,
                style: outlinedStyle,
                child: Text(
                  strings.backToInvoices,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}