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
import '../../ads/ad_action.dart';
import '../../navigation/app_page_route.dart';
import '../../navigation/invoice_flow.dart';
import '../../navigation/app_route_observer.dart';
import '../../services/premium_upsell_service.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../../widgets/ui/empty_state_view.dart';

class InvoicesHomeScreen extends StatefulWidget {
  const InvoicesHomeScreen({super.key});

  @override
  State<InvoicesHomeScreen> createState() => _InvoicesHomeScreenState();
}

class _InvoicesHomeScreenState extends State<InvoicesHomeScreen> with SingleTickerProviderStateMixin, RouteAware {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PremiumUpsellService.maybeShow(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.unsubscribe(this);
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    PremiumUpsellService.maybeShow(context);
  }

  void _openCreateInvoice() {
    runWithInterstitial(context, () {
      Navigator.of(context).push(
        appInvoiceFlowRoute(const CreateInvoiceOptionsScreen(), adScopeKey: 'create_invoice_options'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();
    final strings = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.invoices),
            if (invoiceProvider.dailyInvoiceLimit >= 0)
              Text(
                strings.homeQuotaBanner(
                  invoiceProvider.invoicesRemainingToday ?? 0,
                  invoiceProvider.dailyInvoiceLimit,
                ),
                style: theme.textTheme.labelSmall,
              ),
          ],
        ),
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => runWithInterstitial(context, () {
              Navigator.of(context).push(appPageRoute(const SettingsScreen()));
            }),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AppPageShell(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _OcrScannerBanner(
                onScan: () => runWithInterstitial(context, () => startOcrScan(context)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => afterMajorAction(context),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  labelColor: theme.colorScheme.primary,
                  tabs: [
                    Tab(text: strings.unpaid),
                    Tab(text: strings.paid),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
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
                child: FilledButton.icon(
                  onPressed: _openCreateInvoice,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(strings.createInvoice),
                ),
              ),
            ),
          ],
        ),
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
    final strings = context.l10n;

    if (invoices.isEmpty) {
      return EmptyStateView(
        icon: Icons.description_outlined,
        title: strings.startByCreatingInvoice,
        actionLabel: strings.createInvoice,
        onAction: onCreate,
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
          onTap: () => runWithInterstitial(context, () {
            Navigator.of(context).push(
              appPageRoute(
                InvoiceDetailScreen(invoiceId: invoice.id),
                adScopeKey: 'invoice_detail_${invoice.id}',
              ),
            );
          }),
        );
      },
    );
  }
}
