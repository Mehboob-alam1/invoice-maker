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
import '../../services/ai_helpers.dart';
import '../../services/engagement_service.dart';
import '../../services/invoice_create_gate.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/client_form_sheet.dart';
import '../../widgets/item_form_sheet.dart';
import '../../widgets/invoice_template_preview_sheet.dart';
import '../../widgets/template_picker.dart';
import '../../ads/ad_flows.dart';
import '../../services/paywall_analytics.dart';
import '../../ads/ad_placement.dart';
import '../../navigation/invoice_flow.dart';
import '../../widgets/ui/app_page_shell.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Client? initialClient;
  final List<InvoiceItem>? initialItems;
  final String? currency;
  final DocumentKind documentKind;
  final double? initialTaxRate;
  final String? initialNotes;
  final int? initialDueDays;
  final bool? initialTaxInclusive;
  final String? initialTemplateId;

  const NewInvoiceScreen({
    super.key,
    this.initialClient,
    this.initialItems,
    this.currency,
    this.documentKind = DocumentKind.invoice,
    this.initialTaxRate,
    this.initialNotes,
    this.initialDueDays,
    this.initialTaxInclusive,
    this.initialTemplateId,
  });

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  bool _saving = false;
  bool _canLeave = false;
  bool _leaving = false;
  bool _dirty = false;
  bool _applyingDraft = false;
  Future<void>? _restoreTask;
  Future<void> _draftQueue = Future<void>.value();
  Client? _client;
  final List<InvoiceItem> _items = [];
  String _currency = 'USD';
  InvoiceTemplateId _template = InvoiceTemplateId.classic;
  final _taxRateController = TextEditingController();
  final _discountController = TextEditingController();
  final _shippingController = TextEditingController();
  final _depositController = TextEditingController();
  final _notesController = TextEditingController();
  final _everyDaysController = TextEditingController(text: '30');
  bool _discountIsPercent = true;
  bool _taxInclusive = false;
  bool _repeat = false;
  Recurrence _recurrence = Recurrence.monthly;
  DateTime _repeatStart = DateTime.now();
  DateTime? _repeatEnd;
  DateTime? _serviceStart;
  DateTime? _serviceEnd;
  DateTime? _dueDate = DateTime.now().add(const Duration(days: 7));

  bool get _estimate => widget.documentKind == DocumentKind.estimate;

  @override
  void initState() {
    super.initState();
    _client = widget.initialClient;
    if (widget.initialItems != null) _items.addAll(widget.initialItems!);
    final provider = context.read<InvoiceProvider>();
    if (widget.currency != null) {
      _currency = widget.currency!;
    } else if (provider.defaultCurrency.isNotEmpty) {
      _currency = provider.defaultCurrency;
    }
    if (widget.initialTaxRate != null) {
      _taxRateController.text = widget.initialTaxRate == 0 ? '' : widget.initialTaxRate.toString();
    } else if (provider.defaultTaxRate > 0) {
      _taxRateController.text = provider.defaultTaxRate.toString();
    }
    _taxInclusive = widget.initialTaxInclusive ?? provider.defaultTaxInclusive;
    if (widget.initialNotes != null) _notesController.text = widget.initialNotes!;
    if (widget.initialDueDays != null) {
      _dueDate = DateTime.now().add(Duration(days: widget.initialDueDays!));
    }
    if (widget.initialTemplateId != null) {
      _template = InvoiceTemplateIdStorage.fromStorage(widget.initialTemplateId);
    }
    _taxRateController.addListener(_enqueueDraft);
    _discountController.addListener(_enqueueDraft);
    _shippingController.addListener(_enqueueDraft);
    _depositController.addListener(_enqueueDraft);
    _notesController.addListener(_enqueueDraft);
    if (widget.initialClient == null && widget.initialItems == null) {
      _restoreTask = _restoreDraft();
    }
  }

  void _enqueueDraft() {
    if (_applyingDraft) return;
    _dirty = true;
    _draftQueue = _draftQueue.then((_) => _persistDraft()).catchError((_) {});
  }

  Future<void> _leaveCreateScreen() async {
    if (_leaving) return;
    _leaving = true;
    await _restoreTask;
    if (!mounted) return;
    _enqueueDraft();
    await _draftQueue;
    if (!mounted) return;
    await EngagementService.instance.reschedule(context.read<InvoiceProvider>());
    if (!mounted) return;
    setState(() => _canLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _restoreDraft() async {
    final json = await context.read<InvoiceProvider>().loadNewInvoiceDraft(estimate: _estimate);
    if (!mounted || json == null || _dirty) return;
    _applyingDraft = true;
    try {
      final clientRaw = json['client'];
      final itemsRaw = json['items'];
      final items = <InvoiceItem>[];
      if (itemsRaw is List) {
        for (final e in itemsRaw) {
          if (e is Map) {
            items.add(InvoiceItem.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      if (!mounted) return;
      setState(() {
        if (clientRaw is Map) {
          _client = Client.fromJson(Map<String, dynamic>.from(clientRaw));
        }
        _items
          ..clear()
          ..addAll(items);
        _currency = json['currency'] as String? ?? _currency;
        _template = InvoiceTemplateIdStorage.fromStorage(json['templateId'] as String?);
        final due = json['dueDate'] as String?;
        _dueDate = due == null ? DateTime.now().add(const Duration(days: 7)) : DateTime.tryParse(due) ?? DateTime.now().add(const Duration(days: 7));
        final tax = json['taxRate'];
        if (tax is num && tax > 0) {
          _taxRateController.text = tax.toString();
        }
        _discountController.text = json['discountValue']?.toString() ?? '';
        _shippingController.text = json['shipping']?.toString() ?? '';
        _depositController.text = json['deposit']?.toString() ?? '';
        _notesController.text = json['notes'] as String? ?? '';
        _discountIsPercent = json['discountIsPercent'] as bool? ?? true;
        _taxInclusive = json['taxInclusive'] as bool? ?? _taxInclusive;
        _repeat = json['repeat'] as bool? ?? false;
        _recurrence = Recurrence.values.firstWhere(
          (value) => value.name == json['recurrence'],
          orElse: () => Recurrence.monthly,
        );
      });
    } catch (_) {
    } finally {
      _applyingDraft = false;
    }
  }

  Future<void> _persistDraft() async {
    if (!mounted) return;
    final hasContent = _client != null ||
        _items.isNotEmpty ||
        _dueDate != null ||
        _taxRateController.text.trim().isNotEmpty ||
        _template != InvoiceTemplateId.classic ||
        _currency != 'USD';
    final provider = context.read<InvoiceProvider>();
    if (!hasContent) {
      await provider.clearNewInvoiceDraft();
      return;
    }
    await provider.saveNewInvoiceDraft({
      'client': _client?.toJson(),
      'items': _items.map((e) => e.toJson()).toList(),
      'currency': _currency,
      'templateId': _template.name,
      'dueDate': _dueDate?.toIso8601String(),
      'taxRate': _taxRate,
      'discountValue': _money(_discountController),
      'discountIsPercent': _discountIsPercent,
      'shipping': _money(_shippingController),
      'deposit': _money(_depositController),
      'taxInclusive': _taxInclusive,
      'notes': _notesController.text,
      'repeat': _repeat,
      'recurrence': _recurrence.name,
    }, estimate: _estimate);
  }

  @override
  void dispose() {
    _taxRateController.removeListener(_enqueueDraft);
    _discountController.removeListener(_enqueueDraft);
    _shippingController.removeListener(_enqueueDraft);
    _depositController.removeListener(_enqueueDraft);
    _notesController.removeListener(_enqueueDraft);
    _taxRateController.dispose();
    _discountController.dispose();
    _shippingController.dispose();
    _depositController.dispose();
    _notesController.dispose();
    _everyDaysController.dispose();
    super.dispose();
  }

  double get _taxRate => double.tryParse(_taxRateController.text.trim()) ?? 0;

  double _money(TextEditingController controller) => double.tryParse(controller.text.trim()) ?? 0;

  Invoice _moneyPreview() {
    return Invoice(
      id: 'preview',
      number: _estimate ? 'EST-0000' : '#PREVIEW',
      client: _client ?? Client(id: 'preview', name: ' '),
      items: _items,
      date: DateTime.now(),
      dueDate: _dueDate,
      currency: _currency,
      taxRate: _taxRate,
      templateId: _template.name,
      discountValue: _money(_discountController),
      discountIsPercent: _discountIsPercent,
      shipping: _money(_shippingController),
      deposit: _money(_depositController),
      taxInclusive: _taxInclusive,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      kind: widget.documentKind,
    );
  }

  double get _total => _moneyPreview().total;

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
      _useClient(selected);
    }
  }

  void _useClient(Client client) {
    final memory = context.read<InvoiceProvider>().memoryForClient(client.id);
    setState(() {
      _client = client;
      if (memory != null) {
        _taxRateController.text = memory.taxRate == 0 ? '' : memory.taxRate.toString();
        _notesController.text = memory.notes;
        _dueDate = DateTime.now().add(Duration(days: memory.dueDays));
        _taxInclusive = memory.taxInclusive;
      }
    });
    _enqueueDraft();
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
      _enqueueDraft();
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
      _enqueueDraft();
    }
  }

  Future<void> _suggestDueAndNotes(BuildContext context) async {
    final suggestion = await AiHelpers.suggestDueAndNotes(context, _client?.id);
    if (suggestion == null || !mounted) return;
    setState(() {
      _dueDate = DateTime.now().add(Duration(days: suggestion.dueDays));
      if (suggestion.notes.isNotEmpty) _notesController.text = suggestion.notes;
    });
    _enqueueDraft();
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
      _items.insert(
        0,
        selected.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString()),
      );
    });
    _enqueueDraft();
  }

  Future<void> _addCustomItem() async {
    final result = await showItemFormSheet(
      context,
      currencyCode: _currency,
      onCurrencyChanged: (c) {
        setState(() => _currency = c);
        _enqueueDraft();
      },
    );
    if (!mounted || result == null) return;
    context.read<InvoiceProvider>().addCatalogItem(
      description: result.description,
      notes: result.notes,
      unitCost: result.unitCost,
      quantity: result.quantity,
    );
    setState(() {
      _items.insert(
        0,
        result.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString()),
      );
    });
    _enqueueDraft();
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
    _enqueueDraft();
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
      number: _estimate ? 'EST-0000' : '#PREVIEW',
      client: client,
      items: items,
      date: DateTime.now(),
      dueDate: _dueDate,
      currency: _currency,
      taxRate: _taxRate,
      templateId: _template.name,
      kind: widget.documentKind,
      discountValue: _money(_discountController),
      discountIsPercent: _discountIsPercent,
      shipping: _money(_shippingController),
      deposit: _money(_depositController),
      taxInclusive: _taxInclusive,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
  }

  Future<void> _saveInvoice() async {
    if (_saving) return;
    final provider = context.read<InvoiceProvider>();
    if (_repeat && !_estimate && !provider.canAddRecurring(pro: provider.isPro)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.recurringLimit)));
      await openPaywallIfFree(context, source: PaywallSource.other);
      return;
    }
    if (!_estimate && !await ensureInvoiceQuotaOrPrompt(context)) return;
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
      final repeating = _repeat && !_estimate;
      final invoice = await context.read<InvoiceProvider>().createInvoice(
        client: _client!,
        items: List<InvoiceItem>.from(_items),
        currency: _currency,
        dueDate: _dueDate,
        taxRate: _taxRate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        templateId: _template.name,
        kind: widget.documentKind,
        discountValue: _money(_discountController),
        discountIsPercent: _discountIsPercent,
        shipping: _money(_shippingController),
        deposit: _money(_depositController),
        taxInclusive: _taxInclusive,
        recurrence: repeating ? _recurrence : Recurrence.none,
        recurrenceEveryDays: int.tryParse(_everyDaysController.text.trim()) ?? 30,
        recurrenceStart: repeating ? _repeatStart : null,
        recurrenceEnd: repeating ? _repeatEnd : null,
        nextOccurrence: repeating ? _repeatStart : null,
        recurrenceActive: repeating,
        serviceStart: _serviceStart,
        serviceEnd: _serviceEnd,
        countTowardQuota: !_estimate,
      );
      if (!mounted) return;
      await context.read<InvoiceProvider>().clearNewInvoiceDraft(estimate: _estimate);
      if (!mounted) return;
      await afterGenerationAd(
        context,
        AdPlacement.interstitialSaveInvoice,
        invoiceId: invoice.id,
      );
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
    if (picked != null) {
      setState(() => _dueDate = picked);
      _enqueueDraft();
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
            onChanged: (v) {
              setState(() => _template = v);
              _enqueueDraft();
            },
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

          return PopScope(
            canPop: _canLeave,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _leaveCreateScreen();
            },
            child: Scaffold(
            appBar: AppBar(
              title: Text(_estimate ? strings.newEstimate : strings.newInvoice),
              leading: Padding(
                padding: const EdgeInsets.all(6),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _leaveCreateScreen,
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
                      label: _saving
                          ? strings.creatingInvoice
                          : (_estimate ? strings.saveEstimate : strings.saveInvoice),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlueCard(child: row),
        const SizedBox(height: 12),
        _moneyCard(ctx, strings),
        if (!_estimate) ...[
          const SizedBox(height: 12),
          _repeatCard(ctx, strings),
        ],
      ],
    );
  }

  Widget _moneyCard(BuildContext ctx, dynamic strings) {
    return _BlueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.taxInclusive),
            value: _taxInclusive,
            onChanged: (value) {
              setState(() => _taxInclusive = value);
              _enqueueDraft();
            },
          ),
          Row(
            children: [
              Expanded(
                child: _blueField(
                  ctx,
                  controller: _discountController,
                  label: strings.discount,
                  icon: Icons.sell_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<bool>(
                value: _discountIsPercent,
                items: [
                  DropdownMenuItem(value: true, child: Text(strings.percent)),
                  DropdownMenuItem(value: false, child: Text(strings.amount)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _discountIsPercent = value);
                  _enqueueDraft();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _blueField(
            ctx,
            controller: _shippingController,
            label: strings.shipping,
            icon: Icons.local_shipping_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          _blueField(
            ctx,
            controller: _depositController,
            label: strings.deposit,
            icon: Icons.savings_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          _blueField(
            ctx,
            controller: _notesController,
            label: strings.notes,
            icon: Icons.notes_rounded,
            keyboardType: TextInputType.text,
            onChanged: (_) => setState(() {}),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _suggestDueAndNotes(ctx),
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: Text(strings.suggestDueNotes),
            ),
          ),
          if (_repeat)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(strings.monthTokenHint, style: Theme.of(ctx).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  Widget _repeatCard(BuildContext ctx, dynamic strings) {
    return _BlueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.repeatInvoice),
            value: _repeat,
            onChanged: (value) {
              setState(() => _repeat = value);
              _enqueueDraft();
            },
          ),
          if (_repeat) ...[
            DropdownButton<Recurrence>(
              value: _recurrence,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: Recurrence.weekly, child: Text(strings.repeatWeekly)),
                DropdownMenuItem(value: Recurrence.monthly, child: Text(strings.repeatMonthly)),
                DropdownMenuItem(value: Recurrence.custom, child: Text(strings.repeatCustom)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _recurrence = value);
                _enqueueDraft();
              },
            ),
            if (_recurrence == Recurrence.custom)
              _blueField(
                ctx,
                controller: _everyDaysController,
                label: strings.repeatEveryDays,
                icon: Icons.timelapse_rounded,
                keyboardType: TextInputType.number,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.repeatStart),
              subtitle: Text(DateFormat.yMMMd().format(_repeatStart)),
              onTap: () => _pickNamedDate((date) => _repeatStart = date),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.repeatUntil),
              subtitle: Text(_repeatEnd == null ? '—' : DateFormat.yMMMd().format(_repeatEnd!)),
              onTap: () => _pickNamedDate((date) => _repeatEnd = date),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.serviceFrom),
              subtitle: Text(_serviceStart == null ? '—' : DateFormat.yMMMd().format(_serviceStart!)),
              onTap: () => _pickNamedDate((date) => _serviceStart = date),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.serviceTo),
              subtitle: Text(_serviceEnd == null ? '—' : DateFormat.yMMMd().format(_serviceEnd!)),
              onTap: () => _pickNamedDate((date) => _serviceEnd = date),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickNamedDate(void Function(DateTime date) apply) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => apply(picked));
    _enqueueDraft();
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
        onChanged: (v) {
          setState(() => _currency = v ?? 'USD');
          _enqueueDraft();
        },
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
            '${item.quantity} × ${CurrencyFormat.format(_currency, item.unitCost)}'
                '${item.taxRate > 0 ? ' · ${item.taxRate.toStringAsFixed(0)}%' : ''}',
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
                    onPressed: () {
                      setState(() => _items.removeAt(entry.key));
                      _enqueueDraft();
                    },
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
      TextInputAction textInputAction = TextInputAction.next,
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