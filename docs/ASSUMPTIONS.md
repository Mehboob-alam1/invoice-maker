# Assumptions

Package: `com.invoice.maker.estimate.billing.ocr.appomatrix`. Display name: Invoice GO. Weekly product: `invoice_maker_weekly`. Monthly and yearly product IDs are not in the app yet.

Phase 1 only. Referral, extra plans, and the new invoice features are not built.

Template unlock stays for the current app session. A rewarded ad does not unlock a template forever.

The settings list does not get its banner back. The screen-level bottom banner stays.

Debug builds request Google test ad units. Release builds use Remote Config unit IDs. The production IDs already in the project stay as the offline fallback so a failed fetch does not blank out ads. Do not click live ads.

If the consent info request fails, `canRequestAds()` from the UMP SDK decides. Ads stay off until that call returns true.

Google sign-in and business-name natives default to off. A value already published in Firebase still wins after fetch until this template is published.

`paywall_after_settings_mode` defaults to once per day and is applied when a Free user leaves Settings.

App-open ads now wait 4 hours by default, and interstitials and app-open ads wait until the first saved invoice.
