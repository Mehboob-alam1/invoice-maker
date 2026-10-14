import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_strings.dart';
import '../../providers/invoice_provider.dart';
import '../../services/referral_service.dart';
import '../../widgets/blue_screen.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    ReferralService.instance.logScreen();
    _refresh();
  }

  Future<void> _refresh() async {
    await ReferralService.instance.refresh();
    if (mounted) setState(() {});
  }

  Future<void> _share() async {
    final code = context.read<InvoiceProvider>().referralCode;
    if (code.isEmpty) return;
    await ReferralService.instance.logShare('share_sheet');
    await SharePlus.instance.share(
      ShareParams(text: ReferralService.instance.shareMessage(code)),
    );
    if (!mounted) return;
    context.read<InvoiceProvider>().markInvited();
  }

  Future<void> _copy() async {
    final code = context.read<InvoiceProvider>().referralCode;
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    await ReferralService.instance.logCopy();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.codeCopied)),
    );
  }

  Future<void> _enterCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.haveACode),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: ctx.l10n.referralCode),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(ctx.l10n.save)),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty || !mounted) return;
    setState(() => _busy = true);
    final message = await ReferralService.instance.applyCode(code, source: 'manual');
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final strings = context.l10n;
    final code = provider.referralCode;
    final next = _nextMilestone(provider.qualifiedReferrals);
    final progress = next == null ? 1.0 : provider.qualifiedReferrals / next;

    return Theme(
      data: buildBlueTheme(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(title: Text(strings.inviteFriends)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(strings.referralHeadline, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SelectableText(
              code.isEmpty ? '…' : code,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(onPressed: code.isEmpty ? null : _copy, icon: const Icon(Icons.copy_rounded), label: Text(strings.copyCode)),
                FilledButton.icon(onPressed: code.isEmpty ? null : _share, icon: const Icon(Icons.share_rounded), label: Text(strings.shareInvite)),
              ],
            ),
            const SizedBox(height: 20),
            Text(strings.referralProgress(provider.qualifiedReferrals, provider.pendingReferrals)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress.clamp(0, 1)),
            const SizedBox(height: 8),
            Text(next == null ? strings.referralMilestonesDone : strings.referralNextMilestone(next)),
            const SizedBox(height: 20),
            Text(strings.referralRewardsList),
            const SizedBox(height: 12),
            Text(strings.referralTerms),
            const SizedBox(height: 16),
            TextButton(onPressed: _busy ? null : _enterCode, child: Text(strings.haveACode)),
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(_status!),
            ],
          ],
        ),
      ),
    );
  }

  int? _nextMilestone(int count) {
    const steps = [1, 3, 5, 10];
    for (final step in steps) {
      if (count < step) return step;
    }
    return null;
  }
}

Future<void> showReferralCelebration(BuildContext context) async {
  final notice = await ReferralService.instance.takeNewRewardNotice();
  if (notice == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.celebration_rounded),
      title: Text(notice.title),
      content: Text(notice.body),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.ok)),
      ],
    ),
  );
}
