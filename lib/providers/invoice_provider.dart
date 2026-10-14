import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/invoice_template.dart';
import '../core/remote_config/invoice_limits_remote_config.dart';
import '../core/remote_config/remote_config_repository.dart';
import '../models/subscription_tier.dart';
import '../core/utils/currency_format.dart';
import '../services/home_widget_bridge.dart';
import '../services/invoice_reminder_service.dart';

class InvoiceProvider extends ChangeNotifier {
  static const _storageKey = 'invoice_app_state';
  static const _createDraftKey = 'invoice_create_draft_v1';
  static const _estimateDraftKey = 'estimate_create_draft_v1';

  String businessName = '';
  String businessEmail = '';
  String businessPhone = '';
  String businessAddress = '';
  String businessTaxId = '';
  String bankName = '';
  String accountHolder = '';
  String iban = '';
  String wallet = '';
  String paymentLink = '';
  String paymentNote = '';
  String defaultCurrency = 'USD';
  String defaultTaxLabel = 'VAT';
  double defaultTaxRate = 0;
  bool defaultTaxInclusive = false;
  String businessLogoPath = '';
  String signaturePath = '';
  String stampPath = '';
  String languageCode = 'en';
  SubscriptionTier subscriptionTier = SubscriptionTier.free;
  DateTime? _firstLaunchAt;
  bool _adsHeld = false;

  /// Pending payment or a Play grace period. Full-screen and banner ads stay off.
  static bool adsHeldStatic = false;
  bool get adsHeld => _adsHeld;
  bool onboardingLanguageDone = false;

  String _invoiceQuotaDayKey = '';
  int _invoicesCreatedOnQuotaDay = 0;

  String _aiQuotaMonthKey = '';
  int _aiTokensUsedThisMonth = 0;
  int _bonusAiTokens = 0;

  /// Paid plan from the store. Referral Pro does not change this.
  bool get hasPaidPro => subscriptionTier == SubscriptionTier.pro;

  DateTime? referralProUntil;
  int _serverClockOffsetMs = 0;
  int _serverBonusCredits = 0;
  int templateTokens = 0;
  String referralCode = '';
  int qualifiedReferrals = 0;
  int pendingReferrals = 0;
  final Set<String> tokenUnlockedTemplateIds = {};

  /// Account deletion clears engagement prefs without this provider importing that service.
  static Future<void> Function()? onLocalDataWiped;

  /// Called once when the first invoice is saved.
  void Function()? onFirstInvoiceCreated;

  /// Spends referral AI credits on the server. The amount is a whole credit.
  void Function(int credits)? onSpendServerCredits;

  bool get referralProActive {
    final until = referralProUntil;
    if (until == null) return false;
    final now = DateTime.now().add(Duration(milliseconds: _serverClockOffsetMs));
    return until.isAfter(now);
  }

  /// Store plan, or Pro while a referral reward is still active.
  SubscriptionTier get featureTier {
    if (subscriptionTier != SubscriptionTier.free) return subscriptionTier;
    if (referralProActive) return SubscriptionTier.pro;
    return SubscriptionTier.free;
  }

  bool get isPro => featureTier == SubscriptionTier.pro;

  bool get isPremiumOrAbove => featureTier != SubscriptionTier.free;
  bool onboardingCarouselDone = false;
  bool onboardingGoogleStepDone = false;

  /// True after the first invoice is saved. Deleting invoices does not clear it.
  bool hasCreatedFirstInvoice = false;
  bool hasSharedInvoice = false;
  bool hasInvitedFriend = false;
  bool checklistRewardGranted = false;
  bool milestonesSeeded = false;
  final Set<String> watermarkRemovedIds = {};
  final Set<int> grantedMilestones = {};
  int sharesThisWeek = 0;
  String shareWeekKey = '';

  /// Premium templates unlocked with a rewarded ad. Cleared when the app process ends.
  final Set<String> unlockedTemplateIds = {};

  final List<Client> clients = [];
  final List<Invoice> invoices = [];
  final List<InvoiceItem> catalogItems = [];
  final Map<String, Map<String, dynamic>> clientMemory = {};

  bool get hasCompletedOnboarding => businessName.isNotEmpty;

  /// Called after local profile changes to mirror data in Supabase (set from bootstrap).
  Future<void> Function()? onCloudSyncRequested;
  void Function()? onLanguageChanged;

  bool _importingFromCloud = false;

  String get invoiceQuotaDayKeyForSync {
    _normalizeQuotaDay();
    return _invoiceQuotaDayKey;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void importFromCloudAccount({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String taxId,
    String? languageCode,
  }) {
    _importingFromCloud = true;
    if (name.isNotEmpty) businessName = name;
    if (email.isNotEmpty) businessEmail = email;
    if (phone.isNotEmpty) businessPhone = phone;
    if (address.isNotEmpty) businessAddress = address;
    if (taxId.isNotEmpty) businessTaxId = taxId;
    if (languageCode != null && languageCode.isNotEmpty) this.languageCode = languageCode;
    _importingFromCloud = false;
    notifyListeners();
    _save();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _firstLaunchAt ??= DateTime.now();
      milestonesSeeded = true;
      await _save();
      return;
    }
    var persistLaunch = false;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      businessName = json['businessName'] as String? ?? '';
      businessEmail = json['businessEmail'] as String? ?? '';
      businessPhone = json['businessPhone'] as String? ?? '';
      businessAddress = json['businessAddress'] as String? ?? '';
      businessTaxId = json['businessTaxId'] as String? ?? '';
      bankName = json['bankName'] as String? ?? '';
      accountHolder = json['accountHolder'] as String? ?? '';
      iban = json['iban'] as String? ?? '';
      wallet = json['wallet'] as String? ?? '';
      paymentLink = json['paymentLink'] as String? ?? '';
      paymentNote = json['paymentNote'] as String? ?? '';
      defaultCurrency = json['defaultCurrency'] as String? ?? 'USD';
      defaultTaxLabel = json['defaultTaxLabel'] as String? ?? 'VAT';
      defaultTaxRate = (json['defaultTaxRate'] as num?)?.toDouble() ?? 0;
      defaultTaxInclusive = json['defaultTaxInclusive'] as bool? ?? false;
      businessLogoPath = json['businessLogoPath'] as String? ?? '';
      signaturePath = json['signaturePath'] as String? ?? '';
      stampPath = json['stampPath'] as String? ?? '';
      languageCode = json['languageCode'] as String? ?? 'en';
      final launchRaw = json['firstLaunchAt'] as String?;
      persistLaunch = launchRaw == null || launchRaw.isEmpty;
      _firstLaunchAt = DateTime.tryParse(launchRaw ?? '') ?? DateTime.now();
      final tierRaw = json['subscriptionTier'] as String?;
      if (tierRaw != null) {
        subscriptionTier = SubscriptionTier.fromStorage(tierRaw);
      } else if (json['isPro'] as bool? ?? false) {
        subscriptionTier = SubscriptionTier.pro;
      }
      _invoiceQuotaDayKey = json['invoiceQuotaDayKey'] as String? ?? '';
      _invoicesCreatedOnQuotaDay = json['invoicesCreatedOnQuotaDay'] as int? ?? 0;
      _aiQuotaMonthKey = json['aiQuotaMonthKey'] as String? ?? '';
      _aiTokensUsedThisMonth = json['aiTokensUsedThisMonth'] as int? ?? 0;
      _bonusAiTokens = json['bonusAiTokens'] as int? ?? 0;
      _serverBonusCredits = json['serverBonusCredits'] as int? ?? 0;
      templateTokens = json['templateTokens'] as int? ?? 0;
      referralProUntil = json['referralProUntil'] != null
          ? DateTime.tryParse(json['referralProUntil'] as String)
          : null;
      tokenUnlockedTemplateIds
        ..clear()
        ..addAll(
          (json['tokenUnlockedTemplateIds'] as List? ?? []).map((e) => e.toString()),
        );
      _normalizeQuotaDay();
      _normalizeAiQuotaMonth();
      onboardingLanguageDone = json['onboardingLanguageDone'] as bool? ?? false;
      onboardingCarouselDone = json['onboardingCarouselDone'] as bool? ?? false;
      onboardingGoogleStepDone = json['onboardingGoogleStepDone'] as bool? ?? false;
      hasCreatedFirstInvoice = json['hasCreatedFirstInvoice'] as bool? ?? false;
      hasSharedInvoice = json['hasSharedInvoice'] as bool? ?? false;
      hasInvitedFriend = json['hasInvitedFriend'] as bool? ?? false;
      checklistRewardGranted = json['checklistRewardGranted'] as bool? ?? false;
      milestonesSeeded = json['milestonesSeeded'] as bool? ?? false;
      watermarkRemovedIds
        ..clear()
        ..addAll((json['watermarkRemovedIds'] as List? ?? []).map((e) => e.toString()));
      grantedMilestones
        ..clear()
        ..addAll((json['grantedMilestones'] as List? ?? []).map((e) => (e as num).toInt()));
      sharesThisWeek = json['sharesThisWeek'] as int? ?? 0;
      shareWeekKey = json['shareWeekKey'] as String? ?? '';
      clients
        ..clear()
        ..addAll(
          (json['clients'] as List? ?? []).map(
            (e) => Client.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        );
      invoices
        ..clear()
        ..addAll(
          (json['invoices'] as List? ?? []).map(
            (e) => Invoice.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        );
      if (!hasCreatedFirstInvoice && invoices.isNotEmpty) {
        hasCreatedFirstInvoice = true;
      }
      catalogItems
        ..clear()
        ..addAll(
          (json['catalogItems'] as List? ?? []).map(
            (e) => InvoiceItem.fromJson(Map<String, dynamic>.from(e as Map)),
          ),
        );
      clientMemory.clear();
      final memoryRaw = json['clientMemory'];
      if (memoryRaw is Map) {
        for (final entry in memoryRaw.entries) {
          if (entry.value is Map) {
            clientMemory[entry.key.toString()] = Map<String, dynamic>.from(entry.value as Map);
          }
        }
      }
      notifyListeners();
      seedMilestonesIfNeeded();
      if (persistLaunch) await _save();
    } catch (_) {
      // Ignore corrupt storage and start fresh.
    }
  }

  /// Current invoices, clients, and business details, ready to store as a backup.
  Map<String, dynamic> backupSnapshot() => {
        'businessName': businessName,
        'businessEmail': businessEmail,
        'businessPhone': businessPhone,
        'businessAddress': businessAddress,
        'businessTaxId': businessTaxId,
        'bankName': bankName,
        'accountHolder': accountHolder,
        'iban': iban,
        'wallet': wallet,
        'paymentLink': paymentLink,
        'paymentNote': paymentNote,
        'defaultCurrency': defaultCurrency,
        'defaultTaxLabel': defaultTaxLabel,
        'defaultTaxRate': defaultTaxRate,
        'defaultTaxInclusive': defaultTaxInclusive,
        'businessLogoPath': businessLogoPath,
        'signaturePath': signaturePath,
        'stampPath': stampPath,
        'languageCode': languageCode,
        'firstLaunchAt': (_firstLaunchAt ?? DateTime.now()).toIso8601String(),
        'subscriptionTier': subscriptionTier.storageKey,
        'isPro': subscriptionTier == SubscriptionTier.pro,
        'referralProUntil': referralProUntil?.toIso8601String(),
        'serverBonusCredits': _serverBonusCredits,
        'templateTokens': templateTokens,
        'tokenUnlockedTemplateIds': tokenUnlockedTemplateIds.toList(),
        'invoiceQuotaDayKey': _invoiceQuotaDayKey,
        'invoicesCreatedOnQuotaDay': _invoicesCreatedOnQuotaDay,
        'aiQuotaMonthKey': _aiQuotaMonthKey,
        'aiTokensUsedThisMonth': _aiTokensUsedThisMonth,
        'bonusAiTokens': _bonusAiTokens,
        'onboardingLanguageDone': onboardingLanguageDone,
        'onboardingCarouselDone': onboardingCarouselDone,
        'onboardingGoogleStepDone': onboardingGoogleStepDone,
        'hasCreatedFirstInvoice': hasCreatedFirstInvoice,
        'hasSharedInvoice': hasSharedInvoice,
        'hasInvitedFriend': hasInvitedFriend,
        'checklistRewardGranted': checklistRewardGranted,
        'milestonesSeeded': milestonesSeeded,
        'watermarkRemovedIds': watermarkRemovedIds.toList(),
        'grantedMilestones': grantedMilestones.toList(),
        'sharesThisWeek': sharesThisWeek,
        'shareWeekKey': shareWeekKey,
        'clients': clients.map((e) => e.toJson()).toList(),
        'invoices': invoices.map((e) => e.toJson()).toList(),
        'catalogItems': catalogItems.map((e) => e.toJson()).toList(),
        'clientMemory': clientMemory,
      };

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(backupSnapshot()));
    await InvoiceReminderService.instance.sync(invoices, pro: isPro);
    await HomeWidgetBridge.publish(_widgetLabel());
  }

  String _widgetLabel() {
    final unpaid = unpaidInvoices;
    if (unpaid.isEmpty) return '0';
    final currency = unpaid.first.currency;
    final total = unpaid
        .where((invoice) => invoice.currency == currency)
        .fold<double>(0, (sum, invoice) => sum + (invoice.balanceDue > 0.009 ? invoice.balanceDue : invoice.total));
    return '${unpaid.length} · ${CurrencyFormat.format(currency, total)}';
  }

  Future<void> restoreBackupPayload(Map<String, dynamic> payload) async {
    payload['subscriptionTier'] = subscriptionTier.storageKey;
    payload['isPro'] = subscriptionTier == SubscriptionTier.pro;
    payload['referralProUntil'] = referralProUntil?.toIso8601String();
    payload['referralCode'] = referralCode;
    payload['templateTokens'] = templateTokens;
    payload['serverBonusCredits'] = _serverBonusCredits;
    payload['tokenUnlockedTemplateIds'] = tokenUnlockedTemplateIds.toList();
    payload['qualifiedReferrals'] = qualifiedReferrals;
    payload['pendingReferrals'] = pendingReferrals;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(payload));
    await load();
  }

  void setBusinessProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
    String? bankName,
    String? accountHolder,
    String? iban,
    String? wallet,
    String? paymentLink,
    String? paymentNote,
    String? defaultCurrency,
    String? defaultTaxLabel,
    double? defaultTaxRate,
    bool? defaultTaxInclusive,
    String? businessLogoPath,
    String? signaturePath,
    String? stampPath,
  }) {
    if (name != null) businessName = name.trim();
    if (email != null) businessEmail = email.trim();
    if (phone != null) businessPhone = phone.trim();
    if (address != null) businessAddress = address.trim();
    if (taxId != null) businessTaxId = taxId.trim();
    if (bankName != null) this.bankName = bankName.trim();
    if (accountHolder != null) this.accountHolder = accountHolder.trim();
    if (iban != null) this.iban = iban.trim();
    if (wallet != null) this.wallet = wallet.trim();
    if (paymentLink != null) this.paymentLink = paymentLink.trim();
    if (defaultCurrency != null && defaultCurrency.trim().isNotEmpty) {
      this.defaultCurrency = defaultCurrency.trim().toUpperCase();
    }
    if (defaultTaxLabel != null && defaultTaxLabel.trim().isNotEmpty) {
      this.defaultTaxLabel = defaultTaxLabel.trim();
    }
    if (defaultTaxRate != null) this.defaultTaxRate = defaultTaxRate;
    if (defaultTaxInclusive != null) this.defaultTaxInclusive = defaultTaxInclusive;
    if (businessLogoPath != null) this.businessLogoPath = businessLogoPath;
    if (signaturePath != null) this.signaturePath = signaturePath;
    if (stampPath != null) this.stampPath = stampPath;
    if (paymentNote != null) this.paymentNote = paymentNote.trim();
    notifyListeners();
    _save();
    _requestCloudSync();
  }

  void setBusinessName(String name) => setBusinessProfile(name: name);

  /// In-progress blank invoice or estimate. Survives leaving the create screen.
  Future<void> saveNewInvoiceDraft(Map<String, dynamic> json, {bool estimate = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(estimate ? _estimateDraftKey : _createDraftKey, jsonEncode(json));
  }

  Future<Map<String, dynamic>?> loadNewInvoiceDraft({bool estimate = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(estimate ? _estimateDraftKey : _createDraftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearNewInvoiceDraft({bool estimate = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(estimate ? _estimateDraftKey : _createDraftKey);
  }

  Future<bool> hasOpenInvoiceDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_createDraftKey);
    return raw != null && raw.trim().isNotEmpty;
  }

  int get activeRecurringCount => invoices
      .where((invoice) => invoice.kind == DocumentKind.invoice && invoice.recurrenceActive)
      .length;

  bool canAddRecurring({required bool pro}) => pro || activeRecurringCount < 1;

  void setLanguage(String code) {
    languageCode = code;
    notifyListeners();
    _save();
    _requestCloudSync();
    onLanguageChanged?.call();
  }

  void _requestCloudSync() {
    if (_importingFromCloud) return;
    final sync = onCloudSyncRequested;
    if (sync != null) sync();
  }

  void completeOnboardingLanguageStep() {
    onboardingLanguageDone = true;
    notifyListeners();
    _save();
  }

  void completeOnboardingCarouselStep() {
    onboardingCarouselDone = true;
    notifyListeners();
    _save();
  }

  void completeOnboardingGoogleStep() {
    onboardingGoogleStepDone = true;
    notifyListeners();
    _save();
  }

  bool canUseTemplate(InvoiceTemplateId id) {
    if (!InvoiceTemplateInfo.requiresPro(id)) return true;
    if (featureTier.canUsePremiumTemplates) return true;
    if (tokenUnlockedTemplateIds.contains(id.name)) return true;
    return unlockedTemplateIds.contains(id.name);
  }

  void unlockTemplateWithToken(InvoiceTemplateId id) {
    if (!tokenUnlockedTemplateIds.add(id.name)) return;
    if (templateTokens > 0) templateTokens -= 1;
    notifyListeners();
    _save();
  }

  void applyReferralProfile({
    required String code,
    required int bonusCredits,
    required int tokens,
    required int qualified,
    required int pending,
    DateTime? proUntil,
    DateTime? serverNow,
    List<String> unlockedTemplates = const [],
  }) {
    referralCode = code;
    qualifiedReferrals = qualified;
    pendingReferrals = pending;
    templateTokens = tokens;
    _serverBonusCredits = bonusCredits < 0 ? 0 : bonusCredits;
    referralProUntil = proUntil;
    tokenUnlockedTemplateIds.addAll(unlockedTemplates);
    if (serverNow != null) {
      _serverClockOffsetMs = serverNow.difference(DateTime.now()).inMilliseconds;
    }
    notifyListeners();
    _save();
  }

  void unlockTemplate(InvoiceTemplateId id) {
    if (!unlockedTemplateIds.add(id.name)) return;
    notifyListeners();
  }

  /// Updated from verified store purchases ([SubscriptionService]) or the cloud account.
  void setAdsHeld(bool value) {
    if (_adsHeld == value && adsHeldStatic == value) return;
    _adsHeld = value;
    adsHeldStatic = value;
    notifyListeners();
  }

  DateTime? get firstLaunchAt => _firstLaunchAt;

  bool get inNewUserBoost {
    if (featureTier != SubscriptionTier.free) return false;
    final days = RemoteConfigRepository.instance.newUserBoostDays;
    if (days <= 0) return false;
    final start = _firstLaunchAt ?? DateTime.now();
    return DateTime.now().difference(start).inDays < days;
  }

  void setSubscriptionTier(SubscriptionTier tier) {
    if (subscriptionTier == tier) return;
    subscriptionTier = tier;
    notifyListeners();
    _save();
    _requestCloudSync();
  }

  /// @deprecated Use [setSubscriptionTier]. Kept for migration paths.
  void setPro(bool value) {
    setSubscriptionTier(value ? SubscriptionTier.pro : SubscriptionTier.free);
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _normalizeQuotaDay() {
    final today = _todayKey();
    if (_invoiceQuotaDayKey != today) {
      _invoiceQuotaDayKey = today;
      _invoicesCreatedOnQuotaDay = 0;
    }
  }

  int get dailyInvoiceLimit {
    if (featureTier != SubscriptionTier.free) {
      return InvoiceLimitsRemoteConfig.instance.limitForTier(featureTier);
    }
    final configured = RemoteConfigRepository.instance.number(
      'free_invoices_per_day',
      fallback: InvoiceLimitsRemoteConfig.instance.freeDailyLimit,
    );
    if (!inNewUserBoost) return configured;
    final boost = RemoteConfigRepository.instance.newUserBoostPerDay;
    if (boost < 0) return -1;
    return boost > configured ? boost : configured;
  }

  /// Call after Firebase Remote Config refresh so quota UI picks up new limits.
  void applyRemoteInvoiceLimits() => notifyListeners();

  int get invoicesCreatedToday {
    _normalizeQuotaDay();
    return _invoicesCreatedOnQuotaDay;
  }

  /// `null` when unlimited (Pro).
  int? get invoicesRemainingToday {
    final limit = dailyInvoiceLimit;
    if (limit < 0) return null;
    _normalizeQuotaDay();
    return (limit - _invoicesCreatedOnQuotaDay).clamp(0, limit);
  }

  bool get canCreateInvoiceToday {
    final limit = dailyInvoiceLimit;
    if (limit < 0) return true;
    _normalizeQuotaDay();
    return _invoicesCreatedOnQuotaDay < limit;
  }

  void _recordInvoiceCreatedForQuota() {
    _normalizeQuotaDay();
    _invoicesCreatedOnQuotaDay++;
    _save();
    _requestCloudSync();
  }

  static String _monthKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  void _normalizeAiQuotaMonth() {
    final month = _monthKey();
    if (_aiQuotaMonthKey != month) {
      _aiQuotaMonthKey = month;
      _aiTokensUsedThisMonth = 0;
    }
  }

  int get monthlyAiTokenLimit => featureTier.monthlyAiTokenLimit;

  int get maxAiTokensPerRequest => featureTier.maxAiTokensPerRequest;

  int get maxAiInputCharacters => featureTier.maxAiInputCharacters;

  int get aiTokensUsedThisMonth {
    _normalizeAiQuotaMonth();
    return _aiTokensUsedThisMonth;
  }

  int get aiTokensRemainingThisMonth {
    final limit = monthlyAiTokenLimit;
    _normalizeAiQuotaMonth();
    final monthlyLeft = limit <= 0 ? 0 : (limit - _aiTokensUsedThisMonth).clamp(0, limit);
    return monthlyLeft + _bonusAiTokens + _serverBonusCredits * SubscriptionTier.tokensPerAiCredit;
  }

  /// Fixed overhead + input text (~4 characters per token).
  static int estimateAiTokensForInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 280;
    final inputTokens = (trimmed.length / 4).ceil();
    return inputTokens + 250;
  }

  /// User can open Create with AI (has monthly allowance and tokens left).
  bool get canOpenCreateWithAi {
    if (monthlyAiTokenLimit <= 0 && _bonusAiTokens <= 0 && _serverBonusCredits <= 0) return false;
    return aiTokensRemainingThisMonth > 0;
  }

  /// AI credits left this month (Free-friendly; ~600 tokens per credit).
  int get aiCreditsRemaining {
    final perCredit = SubscriptionTier.tokensPerAiCredit;
    if (perCredit <= 0) return 0;
    return (aiTokensRemainingThisMonth / perCredit).ceil();
  }

  int get monthlyAiCredits => featureTier.monthlyAiCredits;

  bool canAffordAiGeneration(int estimatedTokens) {
    if (estimatedTokens > maxAiTokensPerRequest) return false;
    if (monthlyAiTokenLimit <= 0 && _bonusAiTokens <= 0 && _serverBonusCredits <= 0) return false;
    _normalizeAiQuotaMonth();
    return aiTokensRemainingThisMonth >= estimatedTokens;
  }

  void recordAiTokenUsage(int tokens) {
    if (tokens <= 0) return;
    _normalizeAiQuotaMonth();
    final limit = monthlyAiTokenLimit;
    final monthlyLeft = limit <= 0 ? 0 : (limit - _aiTokensUsedThisMonth).clamp(0, limit);
    final fromMonthly = tokens < monthlyLeft ? tokens : monthlyLeft;
    _aiTokensUsedThisMonth += fromMonthly;
    var rest = tokens - fromMonthly;
    if (rest > 0 && _bonusAiTokens > 0) {
      final fromBonus = rest < _bonusAiTokens ? rest : _bonusAiTokens;
      _bonusAiTokens -= fromBonus;
      rest -= fromBonus;
    }
    if (rest > 0 && _serverBonusCredits > 0) {
      final per = SubscriptionTier.tokensPerAiCredit;
      final needed = (rest / per).ceil();
      final use = needed < _serverBonusCredits ? needed : _serverBonusCredits;
      _serverBonusCredits -= use;
      onSpendServerCredits?.call(use);
    }
    notifyListeners();
    _save();
    _requestCloudSync();
  }

  void grantBonusAiCredit() {
    grantBonusAiCredits(1);
  }

  void grantBonusAiCredits(int credits) {
    if (credits <= 0) return;
    _bonusAiTokens += credits * SubscriptionTier.tokensPerAiCredit;
    notifyListeners();
    _save();
  }

  bool get hasPaymentDetails =>
      bankName.trim().isNotEmpty ||
      iban.trim().isNotEmpty ||
      wallet.trim().isNotEmpty ||
      paymentLink.trim().isNotEmpty;

  bool get checklistComplete =>
      businessLogoPath.isNotEmpty &&
      hasPaymentDetails &&
      hasCreatedFirstInvoice &&
      hasSharedInvoice &&
      hasInvitedFriend;

  static String _weekKey(DateTime date) {
    final start = DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
    return '${start.year}-${start.month}-${start.day}';
  }

  int get sharesThisWeekCount {
    if (shareWeekKey != _weekKey(DateTime.now())) return 0;
    return sharesThisWeek;
  }

  void markInvoiceShared() {
    hasSharedInvoice = true;
    final key = _weekKey(DateTime.now());
    if (shareWeekKey != key) {
      shareWeekKey = key;
      sharesThisWeek = 0;
    }
    sharesThisWeek++;
    notifyListeners();
    _save();
  }

  void markInvited() {
    if (hasInvitedFriend) return;
    hasInvitedFriend = true;
    notifyListeners();
    _save();
  }

  void removeWatermark(String invoiceId) {
    if (!watermarkRemovedIds.add(invoiceId)) return;
    notifyListeners();
    _save();
  }

  /// Marks milestones the user already passed before this feature, without paying credits.
  void seedMilestonesIfNeeded() {
    if (milestonesSeeded) return;
    milestonesSeeded = true;
    final count = invoices.where((invoice) => !invoice.isEstimate).length;
    for (final mark in const [1, 10, 50, 100]) {
      if (count >= mark) grantedMilestones.add(mark);
    }
    _save();
  }

  /// Returns a newly reached invoice count, and grants one AI credit once.
  int? claimNewMilestone() {
    if (!milestonesSeeded) {
      seedMilestonesIfNeeded();
      return null;
    }
    int? reached;
    final count = invoices.where((invoice) => !invoice.isEstimate).length;
    for (final mark in const [1, 10, 50, 100]) {
      if (count >= mark && grantedMilestones.add(mark)) {
        _bonusAiTokens += SubscriptionTier.tokensPerAiCredit;
        reached = mark;
      }
    }
    if (reached == null) return null;
    notifyListeners();
    _save();
    return reached;
  }

  bool claimChecklistReward() {
    if (checklistRewardGranted || !checklistComplete) return false;
    checklistRewardGranted = true;
    _bonusAiTokens += 2 * SubscriptionTier.tokensPerAiCredit;
    notifyListeners();
    _save();
    return true;
  }

  void grantExtraInvoiceToday() {
    _normalizeQuotaDay();
    if (_invoicesCreatedOnQuotaDay > 0) {
      _invoicesCreatedOnQuotaDay--;
    }
    notifyListeners();
    _save();
  }

  Client addClient({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
  }) {
    final client = Client(
      id: _newId(),
      name: name,
      email: email,
      phone: phone,
      address: address,
      taxId: taxId,
    );
    clients.insert(0, client);
    notifyListeners();
    _save();
    return client;
  }

  Client findOrCreateClient({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
  }) {
    for (final client in clients) {
      if (client.name.toLowerCase() == name.toLowerCase()) {
        final merged = client.copyWith(
          email: email ?? client.email,
          phone: phone ?? client.phone,
          address: address ?? client.address,
          taxId: taxId ?? client.taxId,
        );
        updateClient(merged);
        return merged;
      }
    }
    return addClient(name: name, email: email, phone: phone, address: address, taxId: taxId);
  }

  void updateClient(Client updated) {
    final index = clients.indexWhere((c) => c.id == updated.id);
    if (index >= 0) clients[index] = updated;
    for (var i = 0; i < invoices.length; i++) {
      if (invoices[i].client.id == updated.id) {
        invoices[i] = invoices[i].copyWith(client: updated);
      }
    }
    notifyListeners();
    _save();
  }

  void deleteClient(String id) {
    clients.removeWhere((c) => c.id == id);
    notifyListeners();
    _save();
  }

  InvoiceItem addCatalogItem({
    required String description,
    required double unitCost,
    int quantity = 1,
    String? notes,
  }) {
    final item = InvoiceItem(
      id: _newId(),
      description: description,
      notes: notes,
      unitCost: unitCost,
      quantity: quantity,
    );
    catalogItems.insert(0, item);
    notifyListeners();
    _save();
    return item;
  }

  void updateCatalogItem(InvoiceItem updated) {
    final index = catalogItems.indexWhere((i) => i.id == updated.id);
    if (index >= 0) catalogItems[index] = updated;
    notifyListeners();
    _save();
  }

  void deleteCatalogItem(String id) {
    catalogItems.removeWhere((i) => i.id == id);
    notifyListeners();
    _save();
  }

  String nextDocumentNumber(DocumentKind kind) {
    if (kind == DocumentKind.estimate) {
      final count = invoices.where((invoice) => invoice.isEstimate).length + 1;
      return 'EST-${count.toString().padLeft(4, '0')}';
    }
    final count = invoices.where((invoice) => !invoice.isEstimate).length + 1;
    return '#INV.${count.toString().padLeft(3, '0')}';
  }

  Future<Invoice> createInvoice({
    required Client client,
    required List<InvoiceItem> items,
    String currency = 'USD',
    String? number,
    DateTime? date,
    DateTime? dueDate,
    double taxRate = 0,
    String? paymentTerms,
    String? poNumber,
    String? notes,
    String templateId = 'classic',
    DocumentKind kind = DocumentKind.invoice,
    EstimateStatus estimateStatus = EstimateStatus.draft,
    double discountValue = 0,
    bool discountIsPercent = true,
    double shipping = 0,
    double deposit = 0,
    bool taxInclusive = false,
    Recurrence recurrence = Recurrence.none,
    int recurrenceEveryDays = 30,
    DateTime? recurrenceStart,
    DateTime? recurrenceEnd,
    DateTime? nextOccurrence,
    bool recurrenceActive = false,
    DateTime? serviceStart,
    DateTime? serviceEnd,
    bool countTowardQuota = true,
    bool countAsFirstInvoice = true,
  }) async {
    final issued = date ?? DateTime.now();
    final invoice = Invoice(
      id: _newId(),
      number: number?.trim().isNotEmpty == true ? number!.trim() : nextDocumentNumber(kind),
      client: Client(
        id: client.id,
        name: client.name,
        email: client.email,
        phone: client.phone,
        address: client.address,
        taxId: client.taxId,
      ),
      items: items
          .map(
            (e) => InvoiceItem(
              id: e.id,
              description: e.description,
              notes: e.notes,
              unitCost: e.unitCost,
              quantity: e.quantity,
              taxRate: e.taxRate,
            ),
          )
          .toList(),
      date: issued,
      dueDate: dueDate ?? issued.add(const Duration(days: 7)),
      currency: currency,
      taxRate: taxRate,
      paymentTerms: paymentTerms,
      poNumber: poNumber,
      notes: notes,
      templateId: templateId,
      kind: kind,
      estimateStatus: estimateStatus,
      discountValue: discountValue,
      discountIsPercent: discountIsPercent,
      shipping: shipping,
      deposit: deposit,
      taxInclusive: taxInclusive,
      recurrence: recurrence,
      recurrenceEveryDays: recurrenceEveryDays,
      recurrenceStart: recurrenceStart,
      recurrenceEnd: recurrenceEnd,
      nextOccurrence: nextOccurrence,
      recurrenceActive: recurrenceActive,
      serviceStart: serviceStart,
      serviceEnd: serviceEnd,
    );
    final firstInvoice = countAsFirstInvoice && !hasCreatedFirstInvoice;
    invoices.insert(0, invoice);
    if (countAsFirstInvoice) hasCreatedFirstInvoice = true;
    if (firstInvoice) onFirstInvoiceCreated?.call();
    if (countTowardQuota && kind == DocumentKind.invoice) _recordInvoiceCreatedForQuota();
    _rememberClient(invoice);
    notifyListeners();
    await _save();
    return invoice;
  }

  Future<Invoice> duplicateInvoice(Invoice source) {
    return createInvoice(
      client: source.client,
      items: source.items.map((item) => item.copyWith(id: _newId())).toList(),
      currency: source.currency,
      dueDate: DateTime.now().add(Duration(days: _dueDays(source))),
      taxRate: source.taxRate,
      paymentTerms: source.paymentTerms,
      poNumber: source.poNumber,
      notes: source.notes,
      templateId: source.templateId,
      kind: source.kind,
      discountValue: source.discountValue,
      discountIsPercent: source.discountIsPercent,
      shipping: source.shipping,
      deposit: source.deposit,
      taxInclusive: source.taxInclusive,
      countAsFirstInvoice: false,
    );
  }

  List<InvoiceItem> itemSuggestions(String query) {
    final counts = <String, int>{};
    for (final invoice in invoices) {
      for (final item in invoice.items) {
        final key = item.description.trim().toLowerCase();
        if (key.isEmpty) continue;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final ranked = catalogItems.toList()
      ..sort((a, b) {
        final byCount = (counts[b.description.trim().toLowerCase()] ?? 0)
            .compareTo(counts[a.description.trim().toLowerCase()] ?? 0);
        if (byCount != 0) return byCount;
        return a.description.toLowerCase().compareTo(b.description.toLowerCase());
      });
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? ranked
        : ranked.where((item) => item.description.toLowerCase().contains(q));
    return filtered.take(5).toList();
  }

  ({double taxRate, int dueDays, String notes, bool taxInclusive})? memoryForClient(String id) {
    final raw = clientMemory[id];
    if (raw == null) return null;
    return (
      taxRate: (raw['taxRate'] as num?)?.toDouble() ?? 0,
      dueDays: (raw['dueDays'] as num?)?.toInt() ?? 7,
      notes: raw['notes']?.toString() ?? '',
      taxInclusive: raw['taxInclusive'] as bool? ?? false,
    );
  }

  void _rememberClient(Invoice invoice) {
    clientMemory[invoice.client.id] = {
      'taxRate': invoice.taxRate,
      'dueDays': _dueDays(invoice),
      'notes': invoice.notes ?? '',
      'taxInclusive': invoice.taxInclusive,
    };
  }

  int _dueDays(Invoice invoice) {
    final due = invoice.dueDate;
    if (due == null) return 7;
    final issued = DateTime(invoice.date.year, invoice.date.month, invoice.date.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    return dueDay.difference(issued).inDays.clamp(0, 365);
  }

  Future<Invoice?> convertEstimate(String id) async {
    final estimate = invoiceById(id);
    if (estimate == null || !estimate.isEstimate) return null;
    final invoice = await createInvoice(
      client: estimate.client,
      items: estimate.items,
      currency: estimate.currency,
      dueDate: DateTime.now().add(const Duration(days: 7)),
      taxRate: estimate.taxRate,
      paymentTerms: estimate.paymentTerms,
      poNumber: estimate.poNumber,
      notes: estimate.notes,
      templateId: estimate.templateId,
      discountValue: estimate.discountValue,
      discountIsPercent: estimate.discountIsPercent,
      shipping: estimate.shipping,
      deposit: estimate.deposit,
      taxInclusive: estimate.taxInclusive,
    );
    updateInvoice(estimate.copyWith(estimateStatus: EstimateStatus.accepted));
    return invoice;
  }

  /// Creates the scheduled copy and moves the source forward. Does not use the daily cap.
  Future<Invoice?> spawnRecurringCopy(Invoice source) async {
    final when = source.nextOccurrence;
    if (when == null || !source.recurrenceActive) return null;
    final month = _monthName(when);
    final notes = (source.notes ?? '').replaceAll('{month}', month);
    DateTime? shift(DateTime? value) {
      if (value == null) return null;
      return Invoice.advance(source.recurrence, value, source.recurrenceEveryDays);
    }

    final copy = await createInvoice(
      client: source.client,
      items: source.items,
      currency: source.currency,
      date: when,
      dueDate: when.add(const Duration(days: 7)),
      taxRate: source.taxRate,
      paymentTerms: source.paymentTerms,
      poNumber: source.poNumber,
      notes: notes.isEmpty ? null : notes,
      templateId: source.templateId,
      discountValue: source.discountValue,
      discountIsPercent: source.discountIsPercent,
      shipping: source.shipping,
      deposit: 0,
      taxInclusive: source.taxInclusive,
      serviceStart: source.serviceStart,
      serviceEnd: source.serviceEnd,
      countTowardQuota: false,
      countAsFirstInvoice: false,
    );
    final advanced = Invoice.advance(source.recurrence, when, source.recurrenceEveryDays);
    final ended = source.recurrenceEnd != null &&
        DateTime(advanced.year, advanced.month, advanced.day)
            .isAfter(DateTime(source.recurrenceEnd!.year, source.recurrenceEnd!.month, source.recurrenceEnd!.day));
    updateInvoice(
      source.copyWith(
        nextOccurrence: advanced,
        recurrenceActive: !ended,
        serviceStart: shift(source.serviceStart),
        serviceEnd: shift(source.serviceEnd),
      ),
    );
    return copy;
  }

  String _monthName(DateTime date) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[date.month - 1];
  }

  void updateInvoice(Invoice updated) {
    final index = invoices.indexWhere((i) => i.id == updated.id);
    if (index < 0) return;
    invoices[index] = updated;
    _rememberClient(updated);
    notifyListeners();
    _save();
  }

  List<Invoice> get estimates => invoices.where((invoice) => invoice.isEstimate).toList();

  List<Invoice> get unpaidInvoices {
    final list = invoices.where((i) => !i.isEstimate && i.displayStatus != InvoiceStatus.paid).toList();
    list.sort((a, b) {
      final aOverdue = a.displayStatus == InvoiceStatus.overdue ? 0 : 1;
      final bOverdue = b.displayStatus == InvoiceStatus.overdue ? 0 : 1;
      if (aOverdue != bOverdue) return aOverdue.compareTo(bOverdue);
      final aDue = a.dueDate ?? a.date;
      final bDue = b.dueDate ?? b.date;
      return aDue.compareTo(bDue);
    });
    return list;
  }

  List<Invoice> get paidInvoices =>
      invoices.where((i) => !i.isEstimate && i.displayStatus == InvoiceStatus.paid).toList();

  void recordPayment(
    String id, {
    required double amount,
    String? method,
    DateTime? paidOn,
  }) {
    final invoice = invoiceById(id);
    if (invoice == null || amount <= 0) return;
    final nextPaid = invoice.amountPaid + amount;
    final fully = invoice.total <= 0 || nextPaid + 0.009 >= invoice.total;
    updateInvoice(
      invoice.copyWith(
        amountPaid: fully ? invoice.total : nextPaid,
        status: fully ? InvoiceStatus.paid : InvoiceStatus.partiallyPaid,
        paymentMethod: method,
        paidAt: paidOn ?? DateTime.now(),
      ),
    );
  }

  void markPaid(Invoice invoice, {String? method, DateTime? paidOn}) {
    updateInvoice(
      invoice.copyWith(
        status: InvoiceStatus.paid,
        amountPaid: invoice.total,
        paymentMethod: method ?? invoice.paymentMethod,
        paidAt: paidOn ?? DateTime.now(),
      ),
    );
  }

  Invoice? invoiceById(String id) {
    try {
      return invoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  void setInvoiceStatus(String id, InvoiceStatus status) {
    final index = invoices.indexWhere((i) => i.id == id);
    if (index < 0) return;
    final current = invoices[index];
    if (status == InvoiceStatus.unpaid) {
      invoices[index] = current.copyWith(
        status: InvoiceStatus.unpaid,
        amountPaid: 0,
      );
    } else if (status == InvoiceStatus.paid) {
      invoices[index] = current.copyWith(
        status: InvoiceStatus.paid,
        amountPaid: current.total,
        paidAt: current.paidAt ?? DateTime.now(),
      );
    } else {
      invoices[index] = current.copyWith(status: status);
    }
    notifyListeners();
    _save();
  }

  void deleteInvoice(String id) {
    invoices.removeWhere((i) => i.id == id);
    notifyListeners();
    _save();
  }

  /// After account deletion — clear invoices, profile, and onboarding flags on device.
  Future<void> wipeAllLocalDataAfterAccountDeletion() async {
    businessName = '';
    businessEmail = '';
    businessPhone = '';
    businessAddress = '';
    businessTaxId = '';
    bankName = '';
    accountHolder = '';
    iban = '';
    wallet = '';
    paymentLink = '';
    paymentNote = '';
    defaultCurrency = 'USD';
    defaultTaxLabel = 'VAT';
    defaultTaxRate = 0;
    defaultTaxInclusive = false;
    businessLogoPath = '';
    signaturePath = '';
    stampPath = '';
    languageCode = 'en';
    _firstLaunchAt = DateTime.now();
    subscriptionTier = SubscriptionTier.free;
    _invoiceQuotaDayKey = '';
    _invoicesCreatedOnQuotaDay = 0;
    _aiQuotaMonthKey = '';
    _aiTokensUsedThisMonth = 0;
    _bonusAiTokens = 0;
    onboardingLanguageDone = false;
    onboardingCarouselDone = false;
    onboardingGoogleStepDone = false;
    hasCreatedFirstInvoice = false;
    referralCode = '';
    referralProUntil = null;
    templateTokens = 0;
    _serverBonusCredits = 0;
    qualifiedReferrals = 0;
    pendingReferrals = 0;
    tokenUnlockedTemplateIds.clear();
    hasSharedInvoice = false;
    hasInvitedFriend = false;
    checklistRewardGranted = false;
    milestonesSeeded = true;
    watermarkRemovedIds.clear();
    grantedMilestones.clear();
    sharesThisWeek = 0;
    shareWeekKey = '';
    unlockedTemplateIds.clear();
    clients.clear();
    invoices.clear();
    catalogItems.clear();
    clientMemory.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await onLocalDataWiped?.call();
    await InvoiceReminderService.instance.sync(const [], pro: false);
  }
}
