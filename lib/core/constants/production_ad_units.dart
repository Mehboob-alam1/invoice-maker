/// Production AdMob ad unit IDs for app `ca-app-pub-3843970042444074~9694723819`.
///
/// Create Native, Interstitial, and App open units in AdMob, paste IDs here,
/// **or** set the same keys in Firebase Remote Config (recommended for updates without a release).
class ProductionAdUnits {
  ProductionAdUnits._();

  static const _placeholder = 'REPLACE_WITH_ADMOB_UNIT_ID';

  static const androidNative = 'ca-app-pub-3843970042444074/7828329563';
  static const androidInterstitial = 'ca-app-pub-3843970042444074/5132316791';
  static const androidAppOpen = 'ca-app-pub-3843970042444074/6773621390';
  static const androidBanner = 'ca-app-pub-3843970042444074/4156954508';
  static const androidRewarded = 'ca-app-pub-3843970042444074/3962705354';

  static bool isValidUnit(String id) =>
      id.isNotEmpty && id != _placeholder && !id.contains('REPLACE');

  static bool get isConfigured =>
      isValidUnit(androidNative) &&
      isValidUnit(androidInterstitial) &&
      isValidUnit(androidAppOpen);
}
