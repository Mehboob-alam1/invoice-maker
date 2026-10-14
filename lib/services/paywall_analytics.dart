import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Why the weekly paywall was opened. Monthly and yearly plans are not sold.
enum PaywallSource {
  onboarding,
  launch,
  settingsExit,
  aiCap,
  invoiceCap,
  template,
  crown,
  other;

  String get analyticsName => switch (this) {
        PaywallSource.settingsExit => 'settings_exit',
        PaywallSource.aiCap => 'ai_cap',
        PaywallSource.invoiceCap => 'invoice_cap',
        _ => name,
      };
}

class PaywallAnalytics {
  PaywallAnalytics._();

  static Future<void> log(
    String name, {
    required String variant,
    required PaywallSource source,
    String plan = 'weekly',
  }) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: {
          'variant': variant,
          'source': source.analyticsName,
          'plan': plan,
        },
      );
    } catch (error) {
      debugPrint('Paywall analytics $name skipped: $error');
    }
  }
}
