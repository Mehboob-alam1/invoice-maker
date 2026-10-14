import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/ad_remote_config.dart';
import '../core/constants/app_texts.dart';
import '../core/remote_config/remote_config_repository.dart';
import '../core/utils/currency_format.dart';
import '../l10n/app_languages.dart';
import '../l10n/app_strings.dart';
import '../l10n/app_translations.dart';
import '../models/subscription_tier.dart';
import '../providers/invoice_provider.dart';
import 'invoice_reminder_service.dart';
import 'push_notification_service.dart';

/// Checklist rewards, local campaigns, review timing, and notification channels.
class EngagementService {
  EngagementService._();
  static final EngagementService instance = EngagementService._();

  static const _sessionKey = 'engagement_sessions';
  static const _pdfSharesKey = 'engagement_pdf_shares';
  static const _reviewNextKey = 'engagement_review_next';
  static const _paidWaitingKey = 'engagement_paid_waiting';
  static const _paidDoneKey = 'engagement_paid_done';
  static const _announcementKey = 'engagement_announcement_dismissed';
  static const _winBackCreditKey = 'engagement_winback_credit';
  static const _lastOpenKey = 'engagement_last_open';
  static const _draftAnchorKey = 'engagement_draft_anchor';
  static const _referralAnchorKey = 'engagement_referral_anchor';

  static const campaignIds = <int>[900001, 900002, 900003, 900004, 900005, 900006, 900007];

  bool _sessionNoted = false;
  bool _openNoted = false;

  static String channelKey(String channel) => 'engagement_ch_$channel';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<bool> channelEnabled(String channel) async {
    final prefs = await _prefs();
    return prefs.getBool(channelKey(channel)) ?? true;
  }

  Future<Set<String>> enabledChannels() async {
    final enabled = <String>{};
    for (final channel in const ['reminders', 'account', 'tips', 'promos']) {
      if (await channelEnabled(channel)) enabled.add(channel);
    }
    return enabled;
  }

  Future<void> setChannel(String channel, bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(channelKey(channel), enabled);
  }

  Future<void> clearLocal() async {
    final prefs = await _prefs();
    await prefs.remove(_sessionKey);
    await prefs.remove(_pdfSharesKey);
    await prefs.remove(_reviewNextKey);
    await prefs.remove(_paidWaitingKey);
    await prefs.remove(_paidDoneKey);
    await prefs.remove(_announcementKey);
    await prefs.remove(_winBackCreditKey);
    await prefs.remove(_lastOpenKey);
    await prefs.remove(_draftAnchorKey);
    await prefs.remove(_referralAnchorKey);
    for (final channel in const ['reminders', 'account', 'tips', 'promos']) {
      await prefs.remove(channelKey(channel));
    }
  }

  String _text(String language, String key, [Map<String, String> vars = const {}]) {
    var value = kAppTranslations[language]?[key] ?? AppTexts.values[key] ?? key;
    vars.forEach((name, replacement) => value = value.replaceAll('{$name}', replacement));
    return value;
  }

  Future<void> noteSession() async {
    if (_sessionNoted) return;
    _sessionNoted = true;
    final prefs = await _prefs();
    await prefs.setInt(_sessionKey, (prefs.getInt(_sessionKey) ?? 0) + 1);
  }

  Future<void> onHomeVisible(BuildContext context) async {
    if (!context.mounted) return;
    await noteSession();
    if (!context.mounted) return;
    final provider = context.read<InvoiceProvider>();
    final milestone = provider.claimNewMilestone();
    if (milestone != null && context.mounted) {
      final strings = AppStrings.read(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.milestoneToast(milestone))),
      );
    }
    if (!context.mounted) return;
    if (provider.claimChecklistReward() && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.read(context).checklistReward)),
      );
    }
    if (!context.mounted) return;
    await maybeAskDeferred(context);
    if (!context.mounted) return;
    await reschedule(provider);
    if (!context.mounted) return;
    await PushNotificationService.instance.syncTopics(
      languageCode: provider.languageCode,
      pro: provider.featureTier == SubscriptionTier.pro,
      channels: await enabledChannels(),
    );
  }

  Future<void> afterShare(BuildContext context) async {
    if (!context.mounted) return;
    context.read<InvoiceProvider>().markInvoiceShared();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.read(context).shareInviteSnack)),
    );
    await considerReview(context, reason: 'share');
  }

  Future<void> considerReview(BuildContext context, {required String reason}) async {
    final prefs = await _prefs();
    if (reason == 'share') {
      final count = (prefs.getInt(_pdfSharesKey) ?? 0) + 1;
      await prefs.setInt(_pdfSharesKey, count);
      if (count < 2) return;
    } else if (reason == 'paid') {
      if (prefs.getBool(_paidDoneKey) ?? false) return;
    } else {
      return;
    }
    if (!await _canAskReview(prefs)) {
      if (reason == 'paid') await prefs.setBool(_paidWaitingKey, true);
      return;
    }
    if (!context.mounted) return;
    await _askReview(context);
    if (reason == 'paid') await prefs.setBool(_paidDoneKey, true);
  }

  Future<void> maybeAskDeferred(BuildContext context) async {
    final prefs = await _prefs();
    final waitingPaid = prefs.getBool(_paidWaitingKey) ?? false;
    final shares = prefs.getInt(_pdfSharesKey) ?? 0;
    if (!waitingPaid && shares < 2) return;
    if (!await _canAskReview(prefs)) return;
    if (!context.mounted) return;
    await _askReview(context);
    if (waitingPaid) {
      await prefs.setBool(_paidWaitingKey, false);
      await prefs.setBool(_paidDoneKey, true);
    }
  }

  Future<bool> _canAskReview(SharedPreferences prefs) async {
    if (!RemoteConfigRepository.instance.reviewPromptEnabled) return false;
    if ((prefs.getInt(_sessionKey) ?? 0) <= 1) return false;
    final next = prefs.getInt(_reviewNextKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch >= next;
  }

  Future<void> _askReview(BuildContext context) async {
    final prefs = await _prefs();
    await prefs.setInt(
      _reviewNextKey,
      DateTime.now().add(const Duration(days: 60)).millisecondsSinceEpoch,
    );
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (error) {
      debugPrint('In-app review skipped: $error');
    }
  }

  Future<void> grantWinBack(BuildContext context) async {
    final prefs = await _prefs();
    if (prefs.getBool(_winBackCreditKey) ?? false) return;
    await prefs.setBool(_winBackCreditKey, true);
    if (!context.mounted) return;
    context.read<InvoiceProvider>().grantBonusAiCredit();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.read(context).winBackGranted)),
    );
  }

  Future<String?> dismissedAnnouncementId() async {
    final prefs = await _prefs();
    return prefs.getString(_announcementKey);
  }

  Future<void> dismissAnnouncement(String id) async {
    final prefs = await _prefs();
    await prefs.setString(_announcementKey, id);
  }

  void applyDeviceLanguage(InvoiceProvider provider) {
    if (provider.onboardingLanguageDone) return;
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
    final known = AppLanguages.all.any((language) => language.code == code);
    if (!known || provider.languageCode == code) return;
    provider.setLanguage(code);
  }

  ({String bank, String wallet}) paymentHints(String languageCode) {
    final country = AppLanguages.all
            .where((language) => language.code == languageCode)
            .map((language) => language.countryCode.toUpperCase())
            .firstOrNull ??
        'DEFAULT';
    Map<String, dynamic> root = {};
    try {
      final decoded = jsonDecode(RemoteConfigRepository.instance.marketDefaultsJson);
      if (decoded is Map) root = Map<String, dynamic>.from(decoded);
    } catch (_) {}
    final entry = root[country] ?? root[country.toLowerCase()] ?? root['default'] ?? root['DEFAULT'];
    if (entry is! Map) return (bank: '', wallet: '');
    final pick = Map<String, dynamic>.from(entry);
    return (
      bank: pick['bank']?.toString() ?? '',
      wallet: pick['wallet']?.toString() ?? '',
    );
  }

  Future<void> reschedule(InvoiceProvider provider) async {
    final reminders = InvoiceReminderService.instance;
    for (final id in campaignIds) {
      await reminders.cancelCampaign(id);
    }
    if (!AdRemoteConfig.instance.pushNotificationsEnabled) return;

    final prefs = await _prefs();
    if (!_openNoted) {
      _openNoted = true;
      await prefs.setInt(_lastOpenKey, DateTime.now().millisecondsSinceEpoch);
    }
    final language = provider.languageCode;
    final occupied = <String>{};

    Future<void> offer({
      required int id,
      required String channel,
      required DateTime when,
      required String title,
      required String body,
      required String payload,
    }) async {
      if (!await channelEnabled(channel)) return;
      final fire = _respectNight(when);
      final day = '${fire.year}-${fire.month}-${fire.day}';
      if (occupied.contains(day)) return;
      if (!fire.isAfter(DateTime.now())) return;
      occupied.add(day);
      await reminders.scheduleCampaign(
        id: id,
        title: title,
        body: body,
        when: fire,
        channelId: 'engagement_$channel',
        channelName: channel,
        payload: payload,
      );
    }

    if (await provider.hasOpenInvoiceDraft()) {
      final anchor = prefs.getInt(_draftAnchorKey) ?? 0;
      final start = anchor == 0 ? DateTime.now().millisecondsSinceEpoch : anchor;
      if (anchor == 0) await prefs.setInt(_draftAnchorKey, start);
      await offer(
        id: 900001,
        channel: 'tips',
        when: DateTime.fromMillisecondsSinceEpoch(start).add(const Duration(hours: 2)),
        title: _text(language, 'draftAbandonedTitle'),
        body: _text(language, 'draftAbandonedBody'),
        payload: 'engagement:draft',
      );
    } else {
      await prefs.remove(_draftAnchorKey);
    }

    if (!provider.hasCreatedFirstInvoice) {
      final launch = provider.firstLaunchAt ?? DateTime.now();
      await offer(
        id: 900002,
        channel: 'tips',
        when: DateTime(launch.year, launch.month, launch.day, 10).add(const Duration(days: 1)),
        title: 'Invoice GO',
        body: _text(language, 'firstInvoiceNudgeBody'),
        payload: 'engagement:create',
      );
      await offer(
        id: 900003,
        channel: 'tips',
        when: DateTime(launch.year, launch.month, launch.day, 10).add(const Duration(days: 3)),
        title: 'Invoice GO',
        body: _text(language, 'firstInvoiceNudgeBody'),
        payload: 'engagement:create',
      );
    }

    final unpaid = provider.unpaidInvoices;
    if (RemoteConfigRepository.instance.weeklySummaryEnabled && unpaid.isNotEmpty) {
      final currency = unpaid.first.currency;
      final amount = unpaid
          .where((invoice) => invoice.currency == currency)
          .fold<double>(0, (sum, invoice) => sum + (invoice.balanceDue > 0.009 ? invoice.balanceDue : invoice.total));
      await offer(
        id: 900004,
        channel: 'account',
        when: _nextMondayMorning(DateTime.now()),
        title: 'Invoice GO',
        body: _text(language, 'weeklySummaryBody', {
          'n': '${unpaid.length}',
          'amount': CurrencyFormat.format(currency, amount),
        }),
        payload: 'engagement:summary',
      );
    }

    final invoiceCount = provider.invoices.where((invoice) => !invoice.isEstimate).length;
    final noInvites = !provider.hasInvitedFriend &&
        provider.qualifiedReferrals == 0 &&
        provider.pendingReferrals == 0;
    if (invoiceCount >= 2 && noInvites) {
      final anchor = prefs.getInt(_referralAnchorKey) ?? 0;
      final start = anchor == 0 ? DateTime.now().millisecondsSinceEpoch : anchor;
      if (anchor == 0) await prefs.setInt(_referralAnchorKey, start);
      final from = DateTime.fromMillisecondsSinceEpoch(start);
      await offer(
        id: 900007,
        channel: 'promos',
        when: DateTime(from.year, from.month, from.day, 10).add(const Duration(days: 5)),
        title: 'Invoice GO',
        body: _text(language, 'referralNudgeBody'),
        payload: 'engagement:referral',
      );
    } else {
      await prefs.remove(_referralAnchorKey);
    }

    final lastOpen = DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_lastOpenKey) ?? DateTime.now().millisecondsSinceEpoch);
    await offer(
      id: 900005,
      channel: 'promos',
      when: DateTime(lastOpen.year, lastOpen.month, lastOpen.day, 10).add(const Duration(days: 3)),
      title: 'Invoice GO',
      body: _text(language, 'winBackBody'),
      payload: 'engagement:winback',
    );
    await offer(
      id: 900006,
      channel: 'promos',
      when: DateTime(lastOpen.year, lastOpen.month, lastOpen.day, 10).add(const Duration(days: 7)),
      title: 'Invoice GO',
      body: _text(language, 'winBackBody'),
      payload: 'engagement:winback',
    );
  }

  DateTime _respectNight(DateTime when) {
    if (when.hour >= 22) {
      final next = when.add(const Duration(days: 1));
      return DateTime(next.year, next.month, next.day, 9, when.minute);
    }
    if (when.hour < 8) {
      return DateTime(when.year, when.month, when.day, 9, when.minute);
    }
    return when;
  }

  DateTime _nextMondayMorning(DateTime now) {
    var day = DateTime(now.year, now.month, now.day, 9);
    final daysUntilMonday = (DateTime.monday - day.weekday) % 7;
    day = day.add(Duration(days: daysUntilMonday));
    if (!day.isAfter(now)) day = day.add(const Duration(days: 7));
    return day;
  }

  Future<void> showChannelSettings(BuildContext context) async {
    final prefs = await _prefs();
    if (!context.mounted) return;
    final strings = AppStrings.read(context);
    final values = <String, bool>{
      for (final channel in const ['reminders', 'account', 'tips', 'promos'])
        channel: prefs.getBool(channelKey(channel)) ?? true,
    };
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocal) {
            final labels = {
              'reminders': strings.channelReminders,
              'account': strings.channelAccount,
              'tips': strings.channelTips,
              'promos': strings.channelPromos,
            };
            return AlertDialog(
              title: Text(strings.notifications),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.notificationChannelsHint),
                  const SizedBox(height: 8),
                  for (final channel in labels.keys)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(labels[channel]!),
                      value: values[channel] ?? true,
                      onChanged: (enabled) async {
                        setLocal(() => values[channel] = enabled);
                        await setChannel(channel, enabled);
                        if (!context.mounted) return;
                        final provider = context.read<InvoiceProvider>();
                        await InvoiceReminderService.instance.sync(provider.invoices, pro: provider.isPro);
                        await PushNotificationService.instance.syncTopics(
                          languageCode: provider.languageCode,
                          pro: provider.featureTier == SubscriptionTier.pro,
                          channels: await enabledChannels(),
                        );
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(strings.close),
                ),
                FilledButton(
                  onPressed: () async {
                    await PushNotificationService.instance.requestPermissionFromSettings();
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: Text(strings.notifications),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
