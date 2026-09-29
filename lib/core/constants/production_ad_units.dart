/// Production AdMob ad unit IDs for app `ca-app-pub-3843970042444074~9694723819`.
///
/// Create Native, Interstitial, and App open units in AdMob, paste IDs here,
/// **or** set the same keys in Firebase Remote Config (recommended for updates without a release).
class ProductionAdUnits {
  ProductionAdUnits._();

  static const _placeholder = 'REPLACE_WITH_ADMOB_UNIT_ID';

  static const androidNative = _placeholder;
  static const androidInterstitial = _placeholder;
  static const androidAppOpen = _placeholder;

  static const iosNative = _placeholder;
  static const iosInterstitial = _placeholder;
  static const iosAppOpen = _placeholder;

  static bool isValidUnit(String id) =>
      id.isNotEmpty && id != _placeholder && !id.contains('REPLACE');

  static bool get isConfigured =>
      isValidUnit(androidNative) &&
      isValidUnit(androidInterstitial) &&
      isValidUnit(androidAppOpen);
}
