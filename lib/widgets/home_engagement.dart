import 'package:flutter/material.dart';

import '../ads/ad_flows.dart';
import '../core/remote_config/remote_config_repository.dart';
import '../l10n/app_strings.dart';
import '../navigation/app_page_route.dart';
import '../navigation/invoice_flow.dart';
import '../providers/invoice_provider.dart';
import '../screens/business_setup/edit_business_screen.dart';
import '../screens/invoice/create_invoice_options_screen.dart';
import '../screens/invoice/invoice_detail_screen.dart';
import '../screens/referral/referral_screen.dart';
import '../services/engagement_service.dart';

/// Home checklist, weekly send streak, and a Remote Config announcement.
class HomeEngagement extends StatelessWidget {
  const HomeEngagement({super.key, required this.provider});

  final InvoiceProvider provider;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final config = RemoteConfigRepository.instance;
    final title = config.announcementTitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty)
          _AnnouncementBanner(
            id: config.announcementId.isEmpty ? title : config.announcementId,
            title: title,
            body: config.announcementBody,
          ),
        if (!provider.checklistRewardGranted) _ChecklistCard(provider: provider, strings: strings),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            strings.streakSent(provider.sharesThisWeekCount),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _AnnouncementBanner extends StatefulWidget {
  const _AnnouncementBanner({required this.id, required this.title, required this.body});

  final String id;
  final String title;
  final String body;

  @override
  State<_AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<_AnnouncementBanner> {
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    EngagementService.instance.dismissedAnnouncementId().then((dismissed) {
      if (!mounted) return;
      setState(() => _hidden = dismissed == widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.campaign_outlined, color: scheme.onPrimaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
                    if (widget.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(widget.body),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.announcementDismiss,
                onPressed: () async {
                  await EngagementService.instance.dismissAnnouncement(widget.id);
                  if (mounted) setState(() => _hidden = true);
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.provider, required this.strings});

  final InvoiceProvider provider;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final steps = <({String label, bool done, VoidCallback onTap})>[
      (
        label: strings.checklistLogo,
        done: provider.businessLogoPath.isNotEmpty,
        onTap: () => Navigator.of(context).push(appPageRoute(const EditBusinessScreen())),
      ),
      (
        label: strings.checklistPayment,
        done: provider.hasPaymentDetails,
        onTap: () => Navigator.of(context).push(appPageRoute(const EditBusinessScreen())),
      ),
      (
        label: strings.checklistInvoice,
        done: provider.hasCreatedFirstInvoice,
        onTap: () => onMainScreenClick(context, () {
          Navigator.of(context).push(
            appInvoiceFlowRoute(const CreateInvoiceOptionsScreen(), adScopeKey: 'create_invoice_options'),
          );
        }),
      ),
      (
        label: strings.checklistShare,
        done: provider.hasSharedInvoice,
        onTap: () {
          final invoice = provider.invoices.where((item) => !item.isEstimate).firstOrNull;
          if (invoice == null) {
            onMainScreenClick(context, () {
              Navigator.of(context).push(
                appInvoiceFlowRoute(const CreateInvoiceOptionsScreen(), adScopeKey: 'create_invoice_options'),
              );
            });
            return;
          }
          Navigator.of(context).push(
            appPageRoute(
              InvoiceDetailScreen(invoiceId: invoice.id),
              adScopeKey: 'invoice_${invoice.id}',
            ),
          );
        },
      ),
      (
        label: strings.checklistInvite,
        done: provider.hasInvitedFriend,
        onTap: () => Navigator.of(context).push(appPageRoute(const ReferralScreen())),
      ),
    ];
    final done = steps.where((step) => step.done).length;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: Text(strings.checklistTitle),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: done / steps.length, minHeight: 6),
            ),
          ),
          children: [
            for (final step in steps)
              ListTile(
                dense: true,
                leading: Icon(
                  step.done ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: step.done ? scheme.primary : scheme.outline,
                ),
                title: Text(step.label),
                onTap: step.done ? null : step.onTap,
              ),
          ],
        ),
      ),
    );
  }
}
