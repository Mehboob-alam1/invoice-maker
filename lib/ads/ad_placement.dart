/// One Remote Config switch per ad. The key names the ad type and the screen.
enum AdPlacement {
  appOpenSplash('ad_app_open_splash'),
  bannerSplash('ad_banner_splash'),
  nativeLanguage('ad_native_language'),
  nativeHtu('ad_native_htu'),
  bannerBusinessName('ad_banner_business_name'),
  bannerMain('ad_banner_main'),
  interstitialMain('ad_interstitial_main'),
  bannerCreateInvoice('ad_banner_create_invoice'),
  interstitialUseTemplate('ad_interstitial_use_template'),
  interstitialOpenInvoice('ad_interstitial_open_invoice'),
  interstitialSharePdf('ad_interstitial_share_pdf'),
  interstitialPrint('ad_interstitial_print'),
  interstitialPdf('ad_interstitial_pdf'),
  interstitialCustomInvoice('ad_interstitial_custom_invoice'),
  interstitialGenerateAi('ad_interstitial_generate_ai'),
  interstitialOcrCreate('ad_interstitial_ocr_create'),
  appOpenForeground('ad_app_open_foreground'),
  appOpenMediaReturn('ad_app_open_media_return'),
  bannerSettings('ad_banner_settings'),
  nativeSettings('ad_native_settings'),
  rewardedTemplate('ad_rewarded_template'),
  nativeSplash('ad_native_splash'),
  bannerScreen('ad_banner_screen');

  const AdPlacement(this.remoteKey);

  final String remoteKey;

  static const List<AdPlacement> all = AdPlacement.values;
}
