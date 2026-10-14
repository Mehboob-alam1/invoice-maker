import 'package:shared_preferences/shared_preferences.dart';

import '../core/remote_config/remote_config_repository.dart';
import '../providers/invoice_provider.dart';
import '../models/subscription_tier.dart';
import 'ad_consent.dart';
import 'ad_gate.dart';
import 'ad_placement.dart';

/// Decides whether a full-screen ad may show. [AdService] still loads the SDK.
class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  static const _dayKey = 'ad_full_screen_day';
  static const _interstitialDayCountKey = 'ad_interstitial_day_count';
  static const _appOpenDayCountKey = 'ad_app_open_day_count';
  static const _rewardedDayCountKey = 'ad_rewarded_day_count';

  bool Function() hasCreatedInvoice = () => false;

  int _interstitialSession = 0;
  int _interstitialToday = 0;
  int _appOpenToday = 0;
  int _rewardedToday = 0;
  final Set<String> _invoicesWithInterstitial = {};
  DateTime? lastInterstitialShown;
  DateTime? lastAppOpenShown;
  DateTime? _pausedAt;
  String _day = '';

  Future<void> loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    _rollDay(DateTime.now(), prefs);
    _interstitialToday = prefs.getInt(_interstitialDayCountKey) ?? 0;
    _appOpenToday = prefs.getInt(_appOpenDayCountKey) ?? 0;
    _rewardedToday = prefs.getInt(_rewardedDayCountKey) ?? 0;
  }

  void markInvoiceInterstitial(String invoiceId) {
    if (invoiceId.isEmpty) return;
    _invoicesWithInterstitial.add(invoiceId);
  }

  bool invoiceAlreadyShowedInterstitial(String invoiceId) =>
      _invoicesWithInterstitial.contains(invoiceId);

  bool canShowRewarded() => _rewardedToday < RemoteConfigRepository.instance.rewardedDailyCap;

  void notePaused() {
    _pausedAt = DateTime.now();
  }

  bool leftBackgroundLongEnough() {
    final paused = _pausedAt;
    if (paused == null) return false;
    final minSec = RemoteConfigRepository.instance.appOpenMinBackgroundSec;
    return DateTime.now().difference(paused).inSeconds >= minSec;
  }

  AdGateDecision decideInterstitial({
    AdPlacement? placement,
    required SubscriptionTier tier,
    bool ignoreInterval = false,
  }) {
    final config = RemoteConfigRepository.instance;
    return AdGate.fullScreen(
      adsEnabled: config.adsEnabled,
      placementEnabled: placement == null || config.placementEnabled(placement),
      consentReady: AdConsent.instance.canRequestAds,
      isPro: InvoiceProvider.adsHeldStatic || tier == SubscriptionTier.pro || !tier.showInterstitialAds,
      graceUntilFirstInvoice: config.adsGraceUntilFirstInvoice,
      hasCreatedInvoice: hasCreatedInvoice(),
      shownThisSession: _interstitialSession,
      maxPerSession: config.interstitialMaxPerSession,
      shownToday: _interstitialToday,
      maxPerDay: config.interstitialMaxPerDay,
      lastShown: lastInterstitialShown,
      now: DateTime.now(),
      minGap: Duration(seconds: config.interstitialMinIntervalSec),
      ignoreInterval: ignoreInterval,
    );
  }

  AdGateDecision decideAppOpen({
    required AdPlacement placement,
    required SubscriptionTier tier,
    bool ignoreInterval = false,
  }) {
    final config = RemoteConfigRepository.instance;
    final minMin = tier.reducedAppOpenAds
        ? config.appOpenMinIntervalMin < 15
            ? 15
            : config.appOpenMinIntervalMin
        : config.appOpenMinIntervalMin;
    return AdGate.fullScreen(
      adsEnabled: config.adsEnabled,
      placementEnabled: config.placementEnabled(placement),
      consentReady: AdConsent.instance.canRequestAds,
      isPro: InvoiceProvider.adsHeldStatic || tier == SubscriptionTier.pro || !tier.showAppOpenAds,
      graceUntilFirstInvoice: config.adsGraceUntilFirstInvoice,
      hasCreatedInvoice: hasCreatedInvoice(),
      shownThisSession: _appOpenToday,
      maxPerSession: config.appOpenMaxPerDay,
      shownToday: _appOpenToday,
      maxPerDay: config.appOpenMaxPerDay,
      lastShown: lastAppOpenShown,
      now: DateTime.now(),
      minGap: Duration(minutes: minMin),
      ignoreInterval: ignoreInterval,
    );
  }

  Future<void> recordInterstitialShown() async {
    lastInterstitialShown = DateTime.now();
    _interstitialSession++;
    _interstitialToday++;
    await _persist();
  }

  Future<void> recordAppOpenShown() async {
    lastAppOpenShown = DateTime.now();
    _appOpenToday++;
    await _persist();
  }

  Future<void> recordRewardedShown() async {
    _rewardedToday++;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    _rollDay(DateTime.now(), prefs);
    await prefs.setString(_dayKey, _day);
    await prefs.setInt(_interstitialDayCountKey, _interstitialToday);
    await prefs.setInt(_appOpenDayCountKey, _appOpenToday);
    await prefs.setInt(_rewardedDayCountKey, _rewardedToday);
  }

  void _rollDay(DateTime now, SharedPreferences prefs) {
    final day = '${now.year}-${now.month}-${now.day}';
    final stored = prefs.getString(_dayKey);
    if (stored == day) {
      _day = day;
      return;
    }
    _day = day;
    _interstitialToday = 0;
    _appOpenToday = 0;
    _rewardedToday = 0;
    prefs.setString(_dayKey, day);
    prefs.setInt(_interstitialDayCountKey, 0);
    prefs.setInt(_appOpenDayCountKey, 0);
    prefs.setInt(_rewardedDayCountKey, 0);
  }
}
