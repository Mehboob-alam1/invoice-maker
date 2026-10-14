/// Pure rules for full-screen ads. Remote Config supplies the numbers.
class AdGateDecision {
  const AdGateDecision({required this.allow, required this.reason});

  final bool allow;
  final String reason;
}

class AdGate {
  const AdGate._();

  static AdGateDecision fullScreen({
    required bool adsEnabled,
    required bool placementEnabled,
    required bool consentReady,
    required bool isPro,
    required bool graceUntilFirstInvoice,
    required bool hasCreatedInvoice,
    required int shownThisSession,
    required int maxPerSession,
    required int shownToday,
    required int maxPerDay,
    required DateTime? lastShown,
    required DateTime now,
    required Duration minGap,
    required bool ignoreInterval,
  }) {
    if (!adsEnabled) {
      return const AdGateDecision(allow: false, reason: 'ads_disabled');
    }
    if (!placementEnabled) {
      return const AdGateDecision(allow: false, reason: 'placement_off');
    }
    if (!consentReady) {
      return const AdGateDecision(allow: false, reason: 'consent');
    }
    if (isPro) {
      return const AdGateDecision(allow: false, reason: 'pro');
    }
    if (graceUntilFirstInvoice && !hasCreatedInvoice) {
      return const AdGateDecision(allow: false, reason: 'grace');
    }
    if (maxPerSession >= 0 && shownThisSession >= maxPerSession) {
      return const AdGateDecision(allow: false, reason: 'session_cap');
    }
    if (maxPerDay >= 0 && shownToday >= maxPerDay) {
      return const AdGateDecision(allow: false, reason: 'day_cap');
    }
    if (!ignoreInterval &&
        lastShown != null &&
        now.difference(lastShown) < minGap) {
      return const AdGateDecision(allow: false, reason: 'cooldown');
    }
    return const AdGateDecision(allow: true, reason: 'ok');
  }
}
