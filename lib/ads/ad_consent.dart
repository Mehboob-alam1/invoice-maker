import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Google UMP consent. The Mobile Ads SDK is initialized only after this runs.
class AdConsent {
  AdConsent._();
  static final AdConsent instance = AdConsent._();

  bool canRequestAds = false;
  bool privacyOptionsRequired = false;

  Future<void> gather() async {
    if (!AdConfig.isSupported) return;
    final info = ConsentInformation.instance;
    final updated = Completer<void>();
    info.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!updated.isCompleted) updated.complete();
      },
      (error) {
        debugPrint('Consent info update failed: ${error.message}');
        if (!updated.isCompleted) updated.complete();
      },
    );
    try {
      await updated.future.timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('Consent info update timed out: $e');
    }
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
    } catch (e) {
      debugPrint('Consent form skipped: $e');
    }
    try {
      canRequestAds = await info.canRequestAds();
      final privacy = await info.getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired = privacy == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('Consent status unread: $e');
      canRequestAds = false;
    }
  }

  Future<void> showPrivacyOptions() async {
    if (!AdConfig.isSupported) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
      canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('Privacy options failed: $e');
    }
  }
}
