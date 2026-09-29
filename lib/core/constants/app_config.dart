/// Store listing and support — update when Play Console app is live.
class AppConfig {
  AppConfig._();

  /// User-facing app name (home screen, splash, share text, store listing).
  static const appDisplayName = 'Invoice GO';

  static const androidPackageId = 'com.invoice.maker.estimate.billing.ocr.appomatrix';

  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  static const supportEmail = 'support@appomatrix.com';

  /// Account deletion requests (Play Console Data Safety / GDPR).
  static const accountDeletionEmail = 'appo.matrix01@gmail.com';

  /// Public account-deletion page (Netlify). Change if you use a different site name.
  static const accountDeletionWebUrl =
      'https://invoice-go-deletion.netlify.app/account-deletion.html';

  static const privacyLastUpdated = 'September 28, 2026';
  static const guidelinesLastUpdated = 'September 24, 2025';

  /// Data controller / publisher (Play Console & privacy policy).
  static const legalEntityName = 'Appomatrix';
}
