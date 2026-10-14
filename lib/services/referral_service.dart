import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/remote_config/remote_config_repository.dart';
import '../models/invoice_template.dart';
import '../providers/invoice_provider.dart';
import 'push_notification_service.dart';
import 'referral_link.dart';
import 'user_database_service.dart';

class ReferralRewardNotice {
  const ReferralRewardNotice({required this.title, required this.body});

  final String title;
  final String body;
}

/// Referral rewards are stored in Supabase. The app cannot grant them itself.
class ReferralService {
  ReferralService._();
  static final ReferralService instance = ReferralService._();

  static const _referrerReadKey = 'referral_install_referrer_read';
  static const _pendingCodeKey = 'pending_referral_code';
  static const _installIdKey = 'referral_installation_id';
  static const _seenRewardsKey = 'referral_seen_reward_count';

  InvoiceProvider? _provider;
  bool _started = false;

  Future<void> start(InvoiceProvider provider) async {
    _provider = provider;
    provider.onFirstInvoiceCreated = () {
      Future<void>(() => qualifyIfNeeded());
    };
    provider.onSpendServerCredits = (credits) {
      Future<void>(() => spendAiCredits(credits));
    };
    if (_started) return;
    _started = true;
    await _captureInstallReferrer();
    await refresh();
    await _applyPendingCode(source: 'install_referrer');
    if (provider.hasCreatedFirstInvoice) {
      await qualifyIfNeeded();
    }
  }

  Future<void> refresh() async {
    final provider = _provider;
    if (provider == null || !RemoteConfigRepository.instance.referralEnabled) return;
    if (!UserDatabaseService.instance.isReady) return;
    try {
      final data = await UserDatabaseService.instance.ensureReferralProfile(
        installationId: await _installationId(),
        fcmToken: PushNotificationService.instance.token ?? '',
      );
      if (data == null) return;
      final untilRaw = data['referralProUntil'] as String?;
      final serverNow = DateTime.tryParse(data['serverNow'] as String? ?? '');
      provider.applyReferralProfile(
        code: data['referralCode'] as String? ?? '',
        bonusCredits: (data['bonusAiCredits'] as num?)?.toInt() ?? 0,
        tokens: (data['templateTokens'] as num?)?.toInt() ?? 0,
        qualified: (data['referralCount'] as num?)?.toInt() ?? (data['qualified'] as num?)?.toInt() ?? 0,
        pending: (data['pending'] as num?)?.toInt() ?? 0,
        proUntil: untilRaw == null ? null : DateTime.tryParse(untilRaw),
        serverNow: serverNow,
        unlockedTemplates: [
          for (final id in (data['tokenUnlockedTemplates'] as List? ?? [])) id.toString(),
        ],
      );
    } catch (error) {
      debugPrint('Referral refresh skipped: $error');
    }
  }

  Future<String?> applyCode(String raw, {required String source}) async {
    final code = ReferralLink.normalizeCode(raw);
    if (code == null) return 'Enter a valid code.';
    if (!UserDatabaseService.instance.isReady) {
      return 'Referral rewards need the Supabase database.';
    }
    try {
      final data = await UserDatabaseService.instance.applyReferralCode(
        code: code,
        installationId: await _installationId(),
      );
      await _log('referral_code_applied', {'source': source});
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingCodeKey);
      await refresh();
      return data?['message'] as String? ??
          'You and your friend will both get rewards after your first invoice.';
    } on PostgrestException catch (error) {
      return error.message;
    } catch (error) {
      debugPrint('applyReferralCode: $error');
      return 'Could not apply that code.';
    }
  }

  Future<void> qualifyIfNeeded() async {
    if (!RemoteConfigRepository.instance.referralEnabled) return;
    if (!UserDatabaseService.instance.isReady) return;
    try {
      final data = await UserDatabaseService.instance.qualifyReferral();
      if (data?['qualified'] == true) {
        await _log('referral_qualified', {});
      }
      await refresh();
    } catch (error) {
      debugPrint('qualifyReferral skipped: $error');
    }
  }

  Future<bool> spendTemplateToken(InvoiceTemplateId templateId) async {
    final provider = _provider;
    if (provider == null || provider.templateTokens <= 0) return false;
    try {
      if (!UserDatabaseService.instance.isReady) return false;
      await UserDatabaseService.instance.spendReferralTemplateToken(templateId.name);
      provider.unlockTemplateWithToken(templateId);
      await _log('referral_reward_granted', {'type': 'template_token', 'amount': 1});
      await refresh();
      return provider.canUseTemplate(templateId);
    } catch (error) {
      debugPrint('spendTemplateToken: $error');
      return false;
    }
  }

  Future<void> spendAiCredits(int credits) async {
    if (credits <= 0) return;
    try {
      if (!UserDatabaseService.instance.isReady) return;
      await UserDatabaseService.instance.spendReferralCredits(credits);
      await refresh();
    } catch (error) {
      debugPrint('spendAiCredits: $error');
    }
  }

  Future<ReferralRewardNotice?> takeNewRewardNotice() async {
    final provider = _provider;
    if (provider == null) return null;
    final total = provider.qualifiedReferrals + provider.templateTokens + (provider.referralProActive ? 1 : 0);
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getInt(_seenRewardsKey) ?? 0;
    if (total <= seen) return null;
    await prefs.setInt(_seenRewardsKey, total);
    if (seen == 0 && provider.qualifiedReferrals == 0 && provider.templateTokens == 0) return null;
    return ReferralRewardNotice(
      title: 'Reward added',
      body: provider.referralProActive && provider.referralProUntil != null
          ? 'Pro from referrals is active until ${_format(provider.referralProUntil!)}.'
          : 'Your referral reward is ready. AI credits and template tokens are on your account.',
    );
  }

  String shareMessage(String code) {
    return 'I use Invoice GO to make invoices in seconds. Install with my link and we both get free rewards: ${ReferralLink.shareUrl(code)}';
  }

  Future<void> logCopy() => _log('referral_code_copy', {});

  Future<void> logShare(String channel) => _log('referral_share_click', {'channel': channel});

  Future<void> logScreen() => _log('referral_screen_open', {});

  Future<void> _captureInstallReferrer() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_referrerReadKey) == true) return;
    await prefs.setBool(_referrerReadKey, true);
    try {
      final details = await PlayInstallReferrer.installReferrer;
      final code = ReferralLink.codeFromInstallReferrer(details.installReferrer);
      if (code != null) await prefs.setString(_pendingCodeKey, code);
    } catch (error) {
      debugPrint('Install referrer skipped: $error');
    }
  }

  Future<void> _applyPendingCode({required String source}) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(_pendingCodeKey);
    if (pending == null || pending.isEmpty) return;
    await applyCode(pending, source: source);
  }

  Future<String> _installationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installIdKey);
    if (existing != null && existing.length >= 8) return existing;
    final random = Random.secure();
    final id = List.generate(16, (_) => random.nextInt(36).toRadixString(36)).join();
    await prefs.setString(_installIdKey, id);
    return id;
  }

  Future<void> _log(String name, Map<String, Object> parameters) async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('Analytics $name skipped: $error');
    }
  }

  String _format(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
