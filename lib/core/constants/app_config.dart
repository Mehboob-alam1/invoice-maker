/// Store listing and support — update when Play Console app is live.
class AppConfig {
  AppConfig._();

  /// User-facing app name (home screen, splash, share text, store listing).
  static const appDisplayName = 'Invoice GO';

  static const androidPackageId = 'com.invoice.maker.estimate.billing.ocr.appomatrix';

  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  static const supportEmail = 'support@appomatrix.com';

  static const privacyLastUpdated = 'September 24, 2025';
  static const guidelinesLastUpdated = 'September 24, 2025';
}
