import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/invoice_card.dart';
import '../../widgets/theme_toggle_button.dart';
import '../invoice/create_invoice_options_screen.dart';
import '../invoice/invoice_detail_screen.dart';
import '../ocr/ocr_flow.dart';
import '../settings/settings_screen.dart';

class InvoicesHomeScreen extends StatefulWidget {
  const InvoicesHomeScreen({super.key});

  @override
  State<InvoicesHomeScreen> createState() => _InvoicesHomeScreenState();
}

class _InvoicesHomeScreenState extends State<InvoicesHomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  void _openCreateInvoice() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateInvoiceOptionsScreen()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();
    final strings = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.invoices),
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _OcrScannerBanner(onScan: () => startOcrScan(context)),
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: strings.unpaid),
              Tab(text: strings.paid),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InvoiceList(
                  invoices: invoiceProvider.unpaidInvoices,
                  onCreate: _openCreateInvoice,
                ),
                _InvoiceList(
                  invoices: invoiceProvider.paidInvoices,
                  onCreate: _openCreateInvoice,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: ElevatedButton.icon(
                onPressed: _openCreateInvoice,
                icon: const Icon(Icons.add_rounded),
                label: Text(strings.createInvoice),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OcrScannerBanner extends StatelessWidget {
  final VoidCallback onScan;

  const _OcrScannerBanner({required this.onScan});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.scanWithOcr,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 6),
                Text(strings.scanWithOcrSubtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: onScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: scheme.primary,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text(strings.ocrScanner),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;
  final VoidCallback onCreate;

  const _InvoiceList({required this.invoices, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final strings = context.l10n;

    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 72, color: muted),
            const SizedBox(height: 16),
            Text(strings.startByCreatingInvoice, style: theme.textTheme.bodyLarge?.copyWith(color: muted)),
            const SizedBox(height: 16),
            TextButton(onPressed: onCreate, child: Text(strings.createInvoice)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: invoices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final invoice = invoices[i];
        return InvoiceCard(
          invoice: invoice,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id)),
          ),
        );
      },
    );
  }
}
