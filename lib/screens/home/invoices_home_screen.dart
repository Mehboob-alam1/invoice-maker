import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/blue_screen.dart';
import '../../widgets/invoice_card.dart';
import '../../widgets/theme_toggle_button.dart';
import '../invoice/create_invoice_options_screen.dart';
import '../invoice/create_with_ai_screen.dart';
import '../invoice/invoice_detail_screen.dart';
import '../ocr/ocr_flow.dart';
import '../settings/settings_screen.dart';
import '../../ads/ad_flows.dart';
import '../../ads/ad_placement.dart';
import '../../ads/ad_remote_config.dart';
import '../../navigation/app_page_route.dart';
import '../../widgets/placement_native_ad.dart';
import '../../navigation/invoice_flow.dart';
import '../../navigation/app_route_observer.dart';
import '../../widgets/notification_prompt_sheet.dart';
import '../../services/backup_service.dart';
import '../../services/engagement_service.dart';
import '../../services/home_widget_bridge.dart';
import '../../services/subscription_renewal_prompt.dart';
import '../../services/invoice_reminder_service.dart';
import '../../services/recurring_invoice_service.dart';
import '../../widgets/home_engagement.dart';
import '../../widgets/invoice_dashboard.dart';
import '../../services/invoice_send.dart';
import '../referral/referral_screen.dart';
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
    with SingleTickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  late final TabController _tabController = TabController(length: 3, vsync: this);
  bool _overdueOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await RecurringInvoiceService.instance.catchUp(context.read<InvoiceProvider>());
      if (!mounted) return;
      await NotificationPrompt.maybeAsk(context);
      if (!mounted) return;
      await _openReminderTarget();
      if (!mounted) return;
      await showReferralCelebration(context);
      if (!mounted) return;
      if (!context.read<InvoiceProvider>().referralProActive) {
        await SubscriptionRenewalPrompt.maybeShow(context);
      }
      if (!mounted) return;
      await EngagementService.instance.onHomeVisible(context);
      if (!mounted) return;
      await BackupService.instance.maybeAutoBackup(context.read<InvoiceProvider>());
      if (!mounted) return;
      await _openShortcut();
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
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _openShortcut();
  }

  @override
  void didPopNext() {
    NotificationPrompt.maybeAsk(context);
    showReferralCelebration(context);
    if (!context.read<InvoiceProvider>().referralProActive) {
      SubscriptionRenewalPrompt.maybeShow(context);
    }
    EngagementService.instance.onHomeVisible(context);
  }

  Future<void> _openReminderTarget() async {
    final id = InvoiceReminderService.instance.takePending();
    if (id == null || !mounted) return;
    if (id.startsWith('engagement:')) {
      await _openEngagement(id);
      return;
    }
    final invoice = context.read<InvoiceProvider>().invoiceById(id);
    if (invoice == null) return;
    Navigator.of(context).push(
      appPageRoute(InvoiceDetailScreen(invoiceId: id), adScopeKey: 'invoice_$id'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final current = context.read<InvoiceProvider>().invoiceById(id);
    if (current == null) return;
    await InvoiceSend.sharePdfWithMessage(context, current);
  }

  Future<void> _openShortcut() async {
    final action = await HomeWidgetBridge.takeLaunchAction();
    if (action == null || !mounted) return;
    if (action == 'scan') {
      await startOcrScan(context);
      return;
    }
    if (action == 'ai') {
      Navigator.of(context).push(
        appInvoiceFlowRoute(const CreateWithAiScreen(), adScopeKey: 'create_with_ai'),
      );
      return;
    }
    if (action == 'new') _openCreateInvoice();
  }

  Future<void> _openEngagement(String id) async {
    if (id == 'engagement:winback') {
      await EngagementService.instance.grantWinBack(context);
      return;
    }
    if (id == 'engagement:draft' || id == 'engagement:create') {
      if (!mounted) return;
      _openCreateInvoice();
      return;
    }
    if (id == 'engagement:referral' && mounted) {
      Navigator.of(context).push(appPageRoute(const ReferralScreen()));
    }
  }

  void _openCreateInvoice() {
    onMainScreenClick(context, () {
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
            onScan: () => onMainScreenClick(context, () => startOcrScan(context)),
          );
          final tabs = _TabSwitcher(
            controller: _tabController,
            unpaidLabel: strings.unpaid,
            paidLabel: strings.paid,
            estimatesLabel: strings.estimates,
            onTap: (_) => onMainScreenClick(context, () {}),
          );
          final invite = invoiceProvider.referralCode.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: const Icon(Icons.card_giftcard_rounded, size: 18),
                      label: Text(strings.inviteFriends),
                      onPressed: () => Navigator.of(context).push(appPageRoute(const ReferralScreen())),
                    ),
                  ),
                );
          final unpaid = _overdueOnly
              ? invoiceProvider.unpaidInvoices
                  .where((invoice) => invoice.displayStatus == InvoiceStatus.overdue)
                  .toList()
              : invoiceProvider.unpaidInvoices;
          final dashboard = InvoiceDashboard(provider: invoiceProvider);
          final engagement = HomeEngagement(provider: invoiceProvider);
          final lists = TabBarView(
            controller: _tabController,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: FilterChip(
                      label: Text(strings.overdueOnly),
                      selected: _overdueOnly,
                      onSelected: (selected) => setState(() => _overdueOnly = selected),
                    ),
                  ),
                  Expanded(
                    child: _InvoiceList(
                      invoices: unpaid,
                      showNativeAd: invoiceProvider.invoices.length >= 4,
                    ),
                  ),
                ],
              ),
              _InvoiceList(
                invoices: invoiceProvider.paidInvoices,
                showNativeAd: invoiceProvider.invoices.length >= 4,
              ),
              _InvoiceList(
                invoices: invoiceProvider.estimates,
                showNativeAd: false,
                emptyLabel: strings.noEstimatesYet,
              ),
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
                IconButton(
                  tooltip: 'Premium',
                  icon: const Icon(Icons.workspace_premium_rounded),
                  onPressed: () => openPaywall(context),
                ),
                const ThemeToggleButton(),
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () async {
                    await Navigator.of(context).push(appPageRoute(const SettingsScreen()));
                    if (!context.mounted) return;
                    await openPaywallAfterSettings(context);
                  },
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
                            padding: const EdgeInsets.fromLTRB(20, 28, 12, 24),
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
                                  engagement,
                                  dashboard,
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 4, 20, 8),
                                    child: tabs,
                                  ),
                                  invite,
                                  Expanded(child: lists),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Phones and small tablets. The scan banner, checklist, and
                  // dashboard can be taller than the space above the list, so
                  // that block scrolls instead of overflowing the column.
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, body) {
                                final listHeight = (body.maxHeight * 0.42).clamp(220.0, 480.0);
                                return ListView(
                                  primary: false,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
                                      child: banner,
                                    ),
                                    engagement,
                                    dashboard,
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: hPad),
                                      child: tabs,
                                    ),
                                    invite,
                                    const SizedBox(height: 8),
                                    SizedBox(height: listHeight, child: lists),
                                  ],
                                );
                              },
                            ),
                          ),
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 12),
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
    required this.estimatesLabel,
    required this.onTap,
  });

  final TabController controller;
  final String unpaidLabel;
  final String paidLabel;
  final String estimatesLabel;
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
          Tab(height: 46, text: estimatesLabel),
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
  final bool showNativeAd;
  final String? emptyLabel;

  const _InvoiceList({required this.invoices, this.showNativeAd = false, this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    if (invoices.isEmpty) {
      return EmptyStateView(
        icon: Icons.description_outlined,
        title: emptyLabel ?? strings.startByCreatingInvoice,
      );
    }

    final hPad = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 20.0;
    final insertAd = showNativeAd &&
        invoices.length >= 3 &&
        context.watch<InvoiceProvider>().featureTier.showNativeAds &&
        AdRemoteConfig.instance.isPlacementEnabled(AdPlacement.nativeHomeList);

    return ListView.separated(
      primary: false,
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 20),
      itemCount: invoices.length + (insertAd ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (insertAd && i == 3) {
          return const PlacementNativeAd(
            key: ValueKey('home_list_native'),
            placement: AdPlacement.nativeHomeList,
            inline: true,
          );
        }
        final invoiceIndex = insertAd && i > 3 ? i - 1 : i;
        final invoice = invoices[invoiceIndex];
        return InvoiceCard(
          invoice: invoice,
          onTap: () => onMainScreenClick(context, () {
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