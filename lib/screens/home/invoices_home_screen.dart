import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/blue_screen.dart';
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
import '../../services/subscription_renewal_prompt.dart';
import '../../widgets/ui/app_page_shell.dart';
import '../../widgets/ui/empty_state_view.dart';

const double _kWideBreakpoint = 900; // tablet landscape / desktop / web
const double _kSidePanelWidth = 380;
const double _kListMaxWidth = 800;

class InvoicesHomeScreen extends StatefulWidget {
  const InvoicesHomeScreen({super.key});

  @override
  State<InvoicesHomeScreen> createState() => _InvoicesHomeScreenState();
}

class _InvoicesHomeScreenState extends State<InvoicesHomeScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SubscriptionRenewalPrompt.maybeShow(context);
      if (!mounted) return;
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
    SubscriptionRenewalPrompt.maybeShow(context);
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

    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          final banner = _OcrScannerBanner(
            onScan: () => runWithInterstitial(context, () => startOcrScan(context)),
          );
          final tabs = _TabSwitcher(
            controller: _tabController,
            unpaidLabel: strings.unpaid,
            paidLabel: strings.paid,
            onTap: (_) => afterMajorAction(context),
          );
          final lists = TabBarView(
            controller: _tabController,
            children: [
              _InvoiceList(invoices: invoiceProvider.unpaidInvoices),
              _InvoiceList(invoices: invoiceProvider.paidInvoices),
            ],
          );
          final createButton = BlueGradientButton(
            label: strings.createInvoice,
            icon: Icons.add_rounded,
            onPressed: _openCreateInvoice,
          );

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
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
              child: LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth >= _kWideBreakpoint;
                  final hPad = c.maxWidth < 360 ? 14.0 : 20.0;

                  // Tablet landscape / desktop: scan + create on the left,
                  // invoices on the right.
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _kSidePanelWidth,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 12, 24),
                            child: Column(
                              children: [
                                banner,
                                const SizedBox(height: 16),
                                createButton,
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: _kListMaxWidth),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 4, 20, 8),
                                    child: tabs,
                                  ),
                                  Expanded(child: lists),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Phones and small tablets.
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 12),
                            child: banner,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: tabs,
                          ),
                          const SizedBox(height: 8),
                          Expanded(child: lists),
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 16),
                              child: createButton,
                            ),
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
}

/// Unpaid / Paid switch styled as a pill with a solid blue indicator.
class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.controller,
    required this.unpaidLabel,
    required this.paidLabel,
    required this.onTap,
  });

  final TabController controller;
  final String unpaidLabel;
  final String paidLabel;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.14)),
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(14),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [BlueColors.bright, BlueColors.light],
          ),
          boxShadow: [
            BoxShadow(
              color: BlueColors.bright.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        tabs: [
          Tab(height: 46, text: unpaidLabel),
          Tab(height: 46, text: paidLabel),
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
    final theme = Theme.of(context);
    final strings = context.l10n;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [BlueColors.deep, BlueColors.bright, Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: BlueColors.bright.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.scanWithOcr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.scanWithOcrSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: onScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: BlueColors.bright,
                            elevation: 0,
                            minimumSize: const Size(0, 46),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<Invoice> invoices;

  const _InvoiceList({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    if (invoices.isEmpty) {
      return EmptyStateView(
        icon: Icons.description_outlined,
        title: strings.startByCreatingInvoice,
      );
    }

    final hPad = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 20.0;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 20),
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