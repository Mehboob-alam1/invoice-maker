import 'package:ai_invoice_maker_receipt_app/ads/ad_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  AdGateDecision decide({
    bool adsEnabled = true,
    bool placementEnabled = true,
    bool consentReady = true,
    bool isPro = false,
    bool grace = true,
    bool hasInvoice = true,
    int session = 0,
    int today = 0,
    DateTime? lastShown,
    bool ignoreInterval = false,
  }) {
    return AdGate.fullScreen(
      adsEnabled: adsEnabled,
      placementEnabled: placementEnabled,
      consentReady: consentReady,
      isPro: isPro,
      graceUntilFirstInvoice: grace,
      hasCreatedInvoice: hasInvoice,
      shownThisSession: session,
      maxPerSession: 4,
      shownToday: today,
      maxPerDay: 12,
      lastShown: lastShown,
      now: now,
      minGap: const Duration(seconds: 90),
      ignoreInterval: ignoreInterval,
    );
  }

  test('blocks full-screen ads during the first-invoice grace period', () {
    expect(decide(hasInvoice: false).reason, 'grace');
  });

  test('allows a full-screen ad after the first invoice', () {
    expect(decide().allow, isTrue);
  });

  test('pro, consent, and the master switch all block the ad', () {
    expect(decide(isPro: true).reason, 'pro');
    expect(decide(consentReady: false).reason, 'consent');
    expect(decide(adsEnabled: false).reason, 'ads_disabled');
  });

  test('session, day, and cooldown caps block the ad', () {
    expect(decide(session: 4).reason, 'session_cap');
    expect(decide(today: 12).reason, 'day_cap');
    expect(
      decide(lastShown: now.subtract(const Duration(seconds: 30))).reason,
      'cooldown',
    );
    expect(
      decide(
        lastShown: now.subtract(const Duration(seconds: 30)),
        ignoreInterval: true,
      ).allow,
      isTrue,
    );
  });
}
