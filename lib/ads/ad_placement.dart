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
  nativeOnboarding('ad_native_onboarding'),
  nativeGoogle('ad_native_google'),
  nativeBusinessName('ad_native_business_name'),
  bannerScreen('ad_banner_screen'),
  interstitialSaveInvoice('ad_interstitial_save_invoice'),
  interstitialPreviewBack('ad_interstitial_preview_back'),
  rewardedAiCredit('ad_rewarded_ai_credit'),
  rewardedExtraInvoice('ad_rewarded_extra_invoice'),
  rewardedWatermark('ad_rewarded_watermark'),
  nativeHomeList('ad_native_home_list');

  const AdPlacement(this.remoteKey);

  final String remoteKey;

  /// In-app default before Remote Config arrives. Google sign-in and business
  /// name stay off because those steps lose the most people.
  bool get defaultEnabled => switch (this) {
        AdPlacement.nativeGoogle || AdPlacement.nativeBusinessName => false,
        _ => true,
      };

  bool get isFullScreen =>
      name.startsWith('appOpen') || name.startsWith('interstitial');

  static const List<AdPlacement> all = AdPlacement.values;
}
