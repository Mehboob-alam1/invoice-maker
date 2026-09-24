// New packages needed:
//   google_fonts: ^6.2.1   (add to pubspec.yaml)
// New imports needed:
//   import 'package:google_fonts/google_fonts.dart';
//   import '../../core/theme/blue_theme.dart';

import 'package:ai_invoice_maker_receipt_app/widgets/blue_screen.dart' show BlueGradientButton, buildBlueTheme, BlueColors;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_format.dart';
import '../../l10n/app_strings.dart';
import '../../models/client.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/invoice_template.dart';
import '../../providers/invoice_provider.dart';
import '../../services/invoice_create_gate.dart';
import '../../services/invoice_parser.dart';
import '../../widgets/invoice_document_view.dart';
import '../../widgets/invoice_template_preview_sheet.dart';
import '../../widgets/item_form_sheet.dart';
import '../../widgets/template_picker.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../../widgets/ui/app_section_card.dart';
import '../../navigation/invoice_flow.dart';
import '../../ads/ad_action.dart';
import 'ocr_flow.dart';

class OcrReviewScreen extends StatefulWidget {
  final ParsedInvoiceData parsed;

  const OcrReviewScreen({super.key, required this.parsed});

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  bool _creating = false;
  late final TextEditingController _clientController;
  late final TextEditingController _addressController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _taxRateController;
  late final TextEditingController _paymentTermsController;
  late final TextEditingController _poController;
  late final TextEditingController _notesController;
  late final List<InvoiceItem> _items;
  late String _currency;
  late DateTime _issueDate;
  DateTime? _dueDate;
  late InvoiceTemplateId _template;
  bool _showRaw = false;
  var _didSeedItems = false;

  @override
  void initState() {
    super.initState();
    final p = widget.parsed;
    _clientController = TextEditingController(text: p.clientName ?? '');
    _addressController = TextEditingController(text: p.address ?? '');
    _taxIdController = TextEditingController(text: p.clientTaxId ?? '');
    _emailController = TextEditingController(text: p.email ?? '');
    _phoneController = TextEditingController(text: p.phone ?? '');
    _invoiceNumberController = TextEditingController(text: p.invoiceNumber ?? '');
    final parsedTax = p.taxRate;
    _taxRateController = TextEditingController(
      text: parsedTax == null ? '' : parsedTax.toStringAsFixed(parsedTax % 1 == 0 ? 0 : 1),
    );
    _paymentTermsController = TextEditingController(text: p.paymentTerms ?? '');
    _poController = TextEditingController(text: p.poNumber ?? '');
    _notesController = TextEditingController(text: p.notes ?? '');
    _items = List.of(p.items);
    _currency = p.currency ?? 'USD';
    if (!CurrencyFormat.supportedCodes.contains(_currency)) _currency = 'USD';
    _issueDate = p.issueDate ?? DateTime.now();
    _dueDate = p.dueDate;
    _template = InvoiceTemplateId.classic;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeedItems) return;
    _didSeedItems = true;
    if (_items.isEmpty) {
      _items.add(
        InvoiceItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          description: AppStrings.read(context).scannedItem,
          unitCost: 0,
          quantity: 1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _clientController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _invoiceNumberController.dispose();
    _taxRateController.dispose();
    _paymentTermsController.dispose();
    _poController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _taxRate => double.tryParse(_taxRateController.text.trim()) ?? 0;

  double get _subtotal => _items.fold(0, (sum, i) => sum + i.total);

  double get _grandTotal => _subtotal + _subtotal * (_taxRate / 100);

  Future<void> _pickDate({required bool due}) async {
    final initial = due ? (_dueDate ?? _issueDate.add(const Duration(days: 30))) : _issueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (due) {
        _dueDate = picked;
      } else {
        _issueDate = picked;
      }
    });
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

  Invoice _previewInvoice(Client client) {
    return Invoice(
      id: 'preview',
      number: _invoiceNumberController.text.trim().isEmpty ? '#PREVIEW' : _invoiceNumberController.text.trim(),
      client: client,
      items: _items,
      date: _issueDate,
      dueDate: _dueDate,
      currency: _currency,
      taxRate: _taxRate,
      paymentTerms: _emptyToNull(_paymentTermsController.text),
      poNumber: _emptyToNull(_poController.text),
      notes: _emptyToNull(_notesController.text),
      templateId: _template.name,
    );
  }

  String? _emptyToNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  Client _previewClient(AppStrings strings) {
    return Client(
      id: 'preview',
      name: _clientController.text.trim().isEmpty ? strings.scannedClient : _clientController.text.trim(),
      email: _emptyToNull(_emailController.text),
      phone: _emptyToNull(_phoneController.text),
      address: _emptyToNull(_addressController.text),
      taxId: _emptyToNull(_taxIdController.text),
    );
  }

  Future<void> _createInvoice() async {
    if (_creating) return;
    if (!await ensureInvoiceQuotaOrPrompt(context)) return;
    if (!mounted) return;
    if (!await confirmProTemplateUse(context, _template)) return;
    if (!mounted) return;
    setState(() => _creating = true);
    final strings = AppStrings.read(context);
    final name = _clientController.text.trim().isEmpty ? strings.scannedClient : _clientController.text.trim();
    final provider = context.read<InvoiceProvider>();
    final client = provider.findOrCreateClient(
      name: name,
      email: _emptyToNull(_emailController.text),
      phone: _emptyToNull(_phoneController.text),
      address: _emptyToNull(_addressController.text),
      taxId: _emptyToNull(_taxIdController.text),
    );
    final invoice = provider.createInvoice(
      client: client,
      items: _items,
      currency: _currency,
      number: _emptyToNull(_invoiceNumberController.text),
      date: _issueDate,
      dueDate: _dueDate,
      taxRate: _taxRate,
      paymentTerms: _emptyToNull(_paymentTermsController.text),
      poNumber: _emptyToNull(_poController.text),
      notes: _emptyToNull(_notesController.text),
      templateId: _template.name,
    );
    if (!mounted) return;
    try {
      await showInterstitialWithLoadingIfEligible(context);
      if (!mounted) return;
      await navigateAfterInvoiceCreated(context, invoice.id);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _showPreview() {
    final strings = AppStrings.read(context);
    final provider = context.read<InvoiceProvider>();
    final client = _previewClient(strings);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Theme(
        data: buildBlueTheme(Theme.of(ctx)),
        child: Builder(
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text(
                    strings.previewInvoice,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : BlueColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InvoiceDocumentView(invoice: _previewInvoice(client), provider: provider, strings: strings),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final strings = context.l10n;
          final locale = context.watch<InvoiceProvider>().languageCode;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final scheme = Theme.of(context).colorScheme;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                strings.reviewScan,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.4,
                  color: isDark ? Colors.white : BlueColors.navy,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => runWithInterstitial(context, _showPreview),
                  style: TextButton.styleFrom(foregroundColor: BlueColors.bright),
                  child: Text(
                    strings.previewInvoice,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: AppPageShell(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final horizontalPadding = width < 360 ? 12.0 : 20.0;
                  final maxContentWidth = width >= 900 ? 1000.0 : width;
                  final bottomSafe = MediaQuery.paddingOf(context).bottom;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          24 + bottomSafe,
                        ),
                        children: [
                          scannedImagePreview(widget.parsed.imagePath),
                          const SizedBox(height: 16),
                          AppSectionCard(
                            title: strings.billTo,
                            icon: Icons.person_outline_rounded,
                            child: Column(
                              children: [
                                TextField(
                                  controller: _clientController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: strings.clientName,
                                    prefixIcon: const Icon(Icons.person_rounded),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _addressController,
                                  minLines: 2,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.streetAddress,
                                  decoration: InputDecoration(
                                    labelText: strings.address,
                                    prefixIcon: const Icon(Icons.location_on_outlined),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _taxIdController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: strings.taxId,
                                    hintText: strings.taxIdHint,
                                    prefixIcon: const Icon(Icons.badge_outlined),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: strings.email,
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: strings.phoneNumber,
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppSectionCard(
                            title: strings.invoice,
                            icon: Icons.receipt_long_outlined,
                            child: Column(
                              children: [
                                TextField(
                                  controller: _invoiceNumberController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: strings.invoiceNumber,
                                    prefixIcon: const Icon(Icons.tag),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                LayoutBuilder(
                                  builder: (context, dateConstraints) {
                                    final stacked = dateConstraints.maxWidth < 340;
                                    final issueBtn = _DateChipButton(
                                      icon: Icons.event,
                                      label: strings.issueDate,
                                      value: DateFormat.yMMMd(locale).format(_issueDate),
                                      onTap: () => _pickDate(due: false),
                                    );
                                    final dueBtn = _DateChipButton(
                                      icon: Icons.event_available,
                                      label: strings.dueDate,
                                      value: _dueDate == null ? null : DateFormat.yMMMd(locale).format(_dueDate!),
                                      onTap: () => _pickDate(due: true),
                                    );
                                    if (stacked) {
                                      return Column(
                                        children: [
                                          issueBtn,
                                          const SizedBox(height: 10),
                                          dueBtn,
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(child: issueBtn),
                                        const SizedBox(width: 10),
                                        Expanded(child: dueBtn),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _poController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: strings.poNumber,
                                    prefixIcon: const Icon(Icons.numbers_rounded),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _paymentTermsController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: strings.paymentTerms,
                                    hintText: strings.paymentTermsHint,
                                    prefixIcon: const Icon(Icons.schedule_rounded),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _taxRateController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: strings.taxRate,
                                    prefixIcon: const Icon(Icons.percent_rounded),
                                    suffixText: '%',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TemplatePicker(
                            selected: _template,
                            onChanged: (v) => setState(() => _template = v),
                            buildPreviewInvoice: () => _previewInvoice(_previewClient(context.l10n)),
                          ),
                          const SizedBox(height: 16),
                          AppSectionCard(
                            title: strings.items,
                            icon: Icons.list_alt_rounded,
                            trailing: _CurrencyPill(
                              currency: _currency,
                              onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                            ),
                            child: Column(
                              children: [
                                ..._items.asMap().entries.map((entry) {
                                  final item = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _OcrItemRow(
                                      item: item,
                                      currency: _currency,
                                      onTap: () => _editItem(entry.key),
                                    ),
                                  );
                                }),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    children: [
                                      _totalRow(strings.subtotal, _subtotal),
                                      if (_taxRate > 0)
                                        _totalRow('${strings.tax} ($_taxRate%)', _subtotal * _taxRate / 100),
                                      Divider(color: scheme.primary.withValues(alpha: 0.12)),
                                      _totalRow(strings.grandTotal, _grandTotal, bold: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppSectionCard(
                            title: strings.notesOptional,
                            icon: Icons.notes_rounded,
                            child: TextField(
                              controller: _notesController,
                              minLines: 2,
                              maxLines: 4,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(hintText: strings.notesHint),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _showRaw = !_showRaw),
                              style: TextButton.styleFrom(foregroundColor: BlueColors.bright),
                              icon: Icon(_showRaw ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                              label: Text(
                                _showRaw ? strings.hideScannedText : strings.showScannedText,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          if (_showRaw)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
                              ),
                              child: Text(
                                widget.parsed.rawText.isEmpty ? strings.noExtraText : widget.parsed.rawText,
                                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                              ),
                            ),
                          const SizedBox(height: 20),
                          BlueGradientButton(
                            label: _creating ? strings.creatingInvoice : strings.createInvoice,
                            icon: Icons.check_rounded,
                            loading: _creating,
                            onPressed: _creating ? null : _createInvoice,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(
            CurrencyFormat.format(_currency, amount),
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date picker chip button (replaces OutlinedButton.icon for issue/due date).
// ---------------------------------------------------------------------------

class _DateChipButton extends StatelessWidget {
  const _DateChipButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: scheme.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: BlueColors.bright),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      value ?? '—',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : BlueColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Currency pill dropdown (trailing widget for the Items section card).
// ---------------------------------------------------------------------------

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({required this.currency, required this.onChanged});

  final String currency;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currency,
          isDense: true,
          icon: Icon(Icons.expand_more_rounded, size: 18, color: scheme.primary),
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: scheme.primary,
          ),
          items: CurrencyFormat.supportedCodes
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Styled invoice item row.
// ---------------------------------------------------------------------------

class _OcrItemRow extends StatelessWidget {
  const _OcrItemRow({required this.item, required this.currency, required this.onTap});

  final InvoiceItem item;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitle = [
      '${item.quantity} × ${CurrencyFormat.format(currency, item.unitCost)}',
      if (item.notes?.isNotEmpty == true) item.notes!,
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: BlueColors.bright.withValues(alpha: isDark ? 0.0 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [BlueColors.bright, BlueColors.sky],
                  ),
                ),
                child: const Icon(Icons.sell_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.description,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: -0.1,
                        color: isDark ? Colors.white : BlueColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormat.format(currency, item.total),
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}