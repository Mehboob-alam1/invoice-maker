import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_format.dart';
import '../../l10n/app_strings.dart';
import '../../models/client.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/invoice_template.dart';
import '../../providers/invoice_provider.dart';
import '../../services/invoice_create_gate.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/client_form_sheet.dart';
import '../../widgets/item_form_sheet.dart';
import '../../widgets/invoice_template_preview_sheet.dart';
import '../../widgets/template_picker.dart';
import '../../ads/ad_action.dart';
import '../../navigation/invoice_flow.dart';
import '../../widgets/ui/app_page_shell.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Client? initialClient;
  final List<InvoiceItem>? initialItems;
  final String? currency;

  const NewInvoiceScreen({
    super.key,
    this.initialClient,
    this.initialItems,
    this.currency,
  });

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  bool _saving = false;
  Client? _client;
  final List<InvoiceItem> _items = [];
  String _currency = 'USD';
  InvoiceTemplateId _template = InvoiceTemplateId.classic;
  final _taxRateController = TextEditingController();
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _client = widget.initialClient;
    if (widget.initialItems != null) _items.addAll(widget.initialItems!);
    if (widget.currency != null) _currency = widget.currency!;
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, i) => sum + i.total);

  double get _taxRate => double.tryParse(_taxRateController.text.trim()) ?? 0;

  double get _total => _subtotal + _subtotal * (_taxRate / 100);

  // ---------------------------------------------------------------------------
  // Logic (unchanged, sheets only wrapped in the blue theme)
  // ---------------------------------------------------------------------------

  Future<void> _chooseClient() async {
    final provider = context.read<InvoiceProvider>();
    if (provider.clients.isEmpty) {
      await _addOrEditClient();
      return;
    }

    final selected = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final l10n = ctx.l10n;
        final t = _themed(ctx);
        return Theme(
          data: t,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectClient,
                      style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    ...provider.clients.map(
                          (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BlueCard(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          onTap: () => Navigator.pop(ctx, c),
                          child: Row(
                            children: [
                              const _GradientTile(
                                size: 40,
                                radius: 14,
                                child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: t.textTheme.titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Builder(builder: (_) {
                                      final sub = [c.phone, c.email]
                                          .where((v) => v != null && v.isNotEmpty)
                                          .join(' · ');
                                      if (sub.isEmpty) return const SizedBox.shrink();
                                      return Text(
                                        sub,
                                        style: t.textTheme.bodySmall?.copyWith(
                                          color: t.extension<AppSemanticColors>()?.textMuted,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _ActionCard(
                      icon: Icons.person_add_alt_1_rounded,
                      label: l10n.addNewClient,
                      onTap: () => Navigator.pop(ctx, Client(id: '__new__', name: '')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    if (selected.id == '__new__') {
      await _addOrEditClient();
    } else {
      setState(() => _client = selected);
    }
  }

  Future<void> _addOrEditClient({Client? existing}) async {
    final result = await showClientFormSheet(context, client: existing);
    if (!mounted || result == null) return;
    final provider = context.read<InvoiceProvider>();
    if (existing == null) {
      final created = provider.addClient(
        name: result.name,
        phone: result.phone,
        email: result.email,
        address: result.address,
        taxId: result.taxId,
      );
      setState(() => _client = created);
    } else {
      final updated = existing.copyWith(
        name: result.name,
        phone: result.phone,
        email: result.email,
        address: result.address,
        taxId: result.taxId,
      );
      provider.updateClient(updated);
      setState(() => _client = updated);
    }
  }

  Future<void> _addItem() async {
    final provider = context.read<InvoiceProvider>();
    if (provider.catalogItems.isNotEmpty) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) {
          final l10n = ctx.l10n;
          return Theme(
            data: _themed(ctx),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionCard(
                      icon: Icons.library_books_rounded,
                      label: l10n.fromSavedItems,
                      onTap: () => Navigator.pop(ctx, 'catalog'),
                    ),
                    const SizedBox(height: 10),
                    _ActionCard(
                      icon: Icons.note_add_rounded,
                      label: l10n.newItem,
                      onTap: () => Navigator.pop(ctx, 'new'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      if (!mounted) return;
      if (choice == 'catalog') {
        await _addFromCatalog();
        return;
      }
      if (choice == null) return;
    }
    await _addCustomItem();
  }

  Future<void> _addFromCatalog() async {
    final provider = context.read<InvoiceProvider>();
    final selected = await showModalBottomSheet<InvoiceItem>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final t = _themed(ctx);
        final muted = t.extension<AppSemanticColors>()?.textMuted;
        return Theme(
          data: t,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: provider.catalogItems
                    .map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BlueCard(
                      radius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      onTap: () => Navigator.pop(ctx, item),
                      child: Row(
                        children: [
                          const _GradientTile(
                            size: 40,
                            radius: 14,
                            child: Icon(Icons.inventory_2_outlined,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.description,
                              style: t.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.unitCost.toStringAsFixed(2),
                            style: t.textTheme.bodyMedium?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() {
      _items.add(
        selected.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString()),
      );
    });
  }

  Future<void> _addCustomItem() async {
    final result = await showItemFormSheet(
      context,
      currencyCode: _currency,
      onCurrencyChanged: (c) => setState(() => _currency = c),
    );
    if (!mounted || result == null) return;
    setState(() => _items.add(result.copyWith()));
  }

  Future<void> _editItem(int index) async {
    final result = await showItemFormSheet(
      context,
      item: _items[index],
      currencyCode: _currency,
      onCurrencyChanged: (c) => setState(() => _currency = c),
    );
    if (!mounted || result == null) return;
    setState(() => _items[index] = result);
  }

  Invoice _buildPreviewInvoice() {
    final strings = AppStrings.read(context);
    final client = _client ??
        Client(
          id: 'preview',
          name: strings.clientNameHint,
        );
    final items = _items.isEmpty
        ? [
      InvoiceItem(
        id: 'sample',
        description: strings.serviceThisMonth,
        unitCost: 0,
        quantity: 1,
      ),
    ]
        : List<InvoiceItem>.of(_items);
    return Invoice(
      id: 'preview',
      number: '#PREVIEW',
      client: client,
      items: items,
      date: DateTime.now(),
      dueDate: _dueDate,
      currency: _currency,
      taxRate: _taxRate,
      templateId: _template.name,
    );
  }

  Future<void> _saveInvoice() async {
    if (_saving) return;
    if (!await ensureInvoiceQuotaOrPrompt(context)) return;
    if (!mounted) return;
    if (!await confirmProTemplateUse(context, _template)) return;
    if (!mounted) return;
    final strings = AppStrings.read(context);
    if (_client == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.addClientAndItemFirst)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final invoice = await context.read<InvoiceProvider>().createInvoice(
        client: _client!,
        items: List<InvoiceItem>.from(_items),
        currency: _currency,
        dueDate: _dueDate,
        taxRate: _taxRate,
        templateId: _template.name,
      );
      if (!mounted) return;
      await showInterstitialWithLoadingIfEligible(context);
      if (!mounted) return;
      await navigateAfterInvoiceCreated(context, invoice.id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final themed = _themed(context);
    return Theme(
      data: themed,
      child: Builder(
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final strings = ctx.l10n;
          final muted = theme.extension<AppSemanticColors>()?.textMuted;
          final width = MediaQuery.sizeOf(ctx).width;
          final isDesktop = width >= 900;
          final isTablet = !isDesktop && width >= 700;
          final hPad = width < 360 ? 12.0 : 20.0;
          final maxW = isDesktop ? 1080.0 : 820.0;

          final clientSection = _buildClientSection(ctx, strings, theme);
          final templateSection = TemplatePicker(
            selected: _template,
            onChanged: (v) => setState(() => _template = v),
            buildPreviewInvoice: _buildPreviewInvoice,
          );
          final detailsSection = _buildDetailsSection(ctx, strings, twoCol: isTablet);
          final itemsSection = _buildItemsSection(ctx, strings, theme, muted);
          final totalSection = _buildTotalSection(ctx, strings, theme);
          final hint = (_client == null && _items.isEmpty)
              ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                strings.startByAddingClient,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ),
          )
              : null;

          Widget content;
          if (isDesktop) {
            content = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      clientSection,
                      const SizedBox(height: 16),
                      templateSection,
                      const SizedBox(height: 16),
                      detailsSection,
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      itemsSection,
                      const SizedBox(height: 16),
                      totalSection,
                      if (hint != null) ...[const SizedBox(height: 16), hint],
                    ],
                  ),
                ),
              ],
            );
          } else {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                clientSection,
                const SizedBox(height: 16),
                templateSection,
                const SizedBox(height: 16),
                detailsSection,
                const SizedBox(height: 20),
                itemsSection,
                const SizedBox(height: 16),
                totalSection,
                if (hint != null) ...[const SizedBox(height: 16), hint],
              ],
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(strings.newInvoice),
              leading: Padding(
                padding: const EdgeInsets.all(6),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                    foregroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            body: AppPageShell(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: content,
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
                    child: BlueGradientButton(
                      onPressed: _saving ? null : _saveInvoice,
                      loading: _saving,
                      icon: Icons.check_circle_outline_rounded,
                      label: _saving ? strings.creatingInvoice : strings.saveInvoice,
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

  Widget _buildClientSection(BuildContext ctx, dynamic strings, ThemeData theme) {
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    Widget body;
    if (_client == null) {
      body = _ActionCard(
        icon: Icons.person_add_alt_1_rounded,
        label: strings.addClient,
        onTap: _chooseClient,
      );
    } else {
      final details = [
        if (_client!.phone?.isNotEmpty == true) _client!.phone,
        if (_client!.email?.isNotEmpty == true) _client!.email,
        if (_client!.address?.isNotEmpty == true) _client!.address,
      ].join('\n');
      body = _BlueCard(
        child: Row(
          children: [
            const _GradientTile(
              size: 48,
              radius: 18,
              child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _client!.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _addOrEditClient(existing: _client),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
                foregroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(icon: Icons.person_rounded, text: strings.client),
        const SizedBox(height: 10),
        body,
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext ctx, dynamic strings, {required bool twoCol}) {
    final theme = Theme.of(ctx);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;

    final taxField = _blueField(
      ctx,
      controller: _taxRateController,
      label: strings.taxRate,
      icon: Icons.percent_rounded,
      suffixText: '%',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onChanged: (_) => setState(() {}),
    );

    final dueTile = _BlueCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: _pickDueDate,
      child: Row(
        children: [
          const _GradientTile(
            size: 40,
            radius: 14,
            child: Icon(Icons.event_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.dueDate,
                  style: theme.textTheme.labelMedium?.copyWith(color: muted),
                ),
                Text(
                  _dueDate == null ? '—' : DateFormat.yMMMd().format(_dueDate!),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, size: 18, color: theme.colorScheme.primary),
        ],
      ),
    );

    Widget row;
    if (twoCol) {
      row = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: taxField),
          const SizedBox(width: 12),
          Expanded(child: dueTile),
        ],
      );
    } else {
      row = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [taxField, const SizedBox(height: 12), dueTile],
      );
    }
    return _BlueCard(child: row);
  }

  Widget _currencyDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _currency,
        isDense: true,
        borderRadius: BorderRadius.circular(16),
        items: CurrencyFormat.supportedCodes
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _currency = v ?? 'USD'),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext ctx, dynamic strings, ThemeData theme, Color? muted) {
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 8,
          spacing: 8,
          children: [
            _SectionTitle(icon: Icons.receipt_long_rounded, text: strings.items),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  _currencyDropdown(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._items.asMap().entries.map((entry) {
          final item = entry.value;
          final details = [
            '${item.quantity} × ${CurrencyFormat.format(_currency, item.unitCost)}',
            if (item.notes?.isNotEmpty == true) item.notes!,
          ].join('\n');
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BlueCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              onTap: () => _editItem(entry.key),
              child: Row(
                children: [
                  _GradientTile(
                    size: 40,
                    radius: 14,
                    child: Text(
                      '${entry.key + 1}',
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
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          details,
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormat.format(_currency, item.total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: cs.error,
                    onPressed: () => setState(() => _items.removeAt(entry.key)),
                  ),
                ],
              ),
            ),
          );
        }),
        _ActionCard(icon: Icons.note_add_rounded, label: strings.addItems, onTap: _addItem),
      ],
    );
  }

  Widget _buildTotalSection(BuildContext ctx, dynamic strings, ThemeData theme) {
    return _BlueCard(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        spacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.total,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 12),
              _currencyDropdown(),
            ],
          ),
          Container(
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
              CurrencyFormat.format(_currency, _total),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
      String? suffixText,
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
      suffixText: suffixText,
      filled: true,
      fillColor: cs.primary.withValues(alpha: 0.06),
      prefixIcon: Icon(icon, color: cs.primary),
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
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: r,
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          child: Padding(padding: padding, child: child),
        ),
      ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GradientTile(
          size: 32,
          radius: 12,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _BlueCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          _GradientTile(
            size: 40,
            radius: 14,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward_rounded, size: 16, color: cs.primary),
          ),
        ],
      ),
    );
  }
}