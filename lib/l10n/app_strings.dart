import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_images.dart';
import '../core/constants/app_texts.dart';
import '../providers/invoice_provider.dart';
import 'app_translations.dart';

extension AppL10n on BuildContext {
  /// Watches language during [build]; uses a non-listening read in callbacks.
  AppStrings get l10n {
    final element = this as Element;
    if (element.debugDoingBuild) {
      return AppStrings.of(this);
    }
    return AppStrings.read(this);
  }
}

class AppStrings {
  const AppStrings(this.code);

  final String code;

  static AppStrings of(BuildContext context) {
    return AppStrings(context.watch<InvoiceProvider>().languageCode);
  }

  static AppStrings read(BuildContext context) {
    return AppStrings(context.read<InvoiceProvider>().languageCode);
  }

  String t(String key, [Map<String, String> vars = const {}]) {
    var value = kAppTranslations[code]?[key] ?? AppTexts.values[key] ?? key;
    vars.forEach((k, v) => value = value.replaceAll('{$k}', v));
    return value;
  }

  String get next => t('next');
  String get getStarted => t('getStarted');
  String get continueLabel => t('continueLabel');
  String get save => t('save');
  String get cancel => t('cancel');
  String get ok => t('ok');
  String get close => t('close');
  String get delete => t('delete');
  String get send => t('send');
  String get searchLanguage => t('searchLanguage');
  String get selectLanguage => t('selectLanguage');
  String get selectLanguageSubtitle => t('selectLanguageSubtitle');
  String get businessNameTitle => t('businessNameTitle');
  String get businessNameHint => t('businessNameHint');
  String get businessNameHelp => t('businessNameHelp');
  String get defaultBusinessName => t('defaultBusinessName');
  String get invoices => t('invoices');
  String get unpaid => t('unpaid');
  String get paid => t('paid');
  String get overdue => t('overdue');
  String get scanWithOcr => t('scanWithOcr');
  String get scanWithOcrSubtitle => t('scanWithOcrSubtitle');
  String get ocrScanner => t('ocrScanner');
  String get startByCreatingInvoice => t('startByCreatingInvoice');
  String get createInvoice => t('createInvoice');
  String get howCreateInvoice => t('howCreateInvoice');
  String get customInvoice => t('customInvoice');
  String get customInvoiceSubtitle => t('customInvoiceSubtitle');
  String get scanOcrOptionSubtitle => t('scanOcrOptionSubtitle');
  String get createWithAi => t('createWithAi');
  String get createWithAiSubtitle => t('createWithAiSubtitle');
  String get newInvoice => t('newInvoice');
  String get client => t('client');
  String get items => t('items');
  String get total => t('total');
  String get addClient => t('addClient');
  String get addItems => t('addItems');
  String get addNewClient => t('addNewClient');
  String get selectClient => t('selectClient');
  String get fromSavedItems => t('fromSavedItems');
  String get newItem => t('newItem');
  String get addClientAndItemFirst => t('addClientAndItemFirst');
  String get startByAddingClient => t('startByAddingClient');
  String get saveInvoice => t('saveInvoice');
  String get editClient => t('editClient');
  String get clientFormHelp => t('clientFormHelp');
  String get name => t('name');
  String get clientNameHint => t('clientNameHint');
  String get enterName => t('enterName');
  String get phoneNumber => t('phoneNumber');
  String get phoneHint => t('phoneHint');
  String get email => t('email');
  String get emailHint => t('emailHint');
  String get enterValidEmail => t('enterValidEmail');
  String get address => t('address');
  String get addressHint => t('addressHint');
  String get editItem => t('editItem');
  String get itemName => t('itemName');
  String get itemNameHint => t('itemNameHint');
  String get enterItemName => t('enterItemName');
  String get notesOptional => t('notesOptional');
  String get notesHint => t('notesHint');
  String get quantity => t('quantity');
  String get enterQuantity => t('enterQuantity');
  String get price => t('price');
  String get enterPrice => t('enterPrice');
  String get enterValidPrice => t('enterValidPrice');
  String get aiIntro => t('aiIntro');
  String get clientNameOptional => t('clientNameOptional');
  String get clientNameHintAi => t('clientNameHintAi');
  String get writeInvoiceDetail => t('writeInvoiceDetail');
  String get invoiceThisMonthHint => t('invoiceThisMonthHint');
  String get generating => t('generating');
  String get generateInvoice => t('generateInvoice');
  String get aiFillHint => t('aiFillHint');
  String get newClientFallback => t('newClientFallback');
  String get serviceThisMonth => t('serviceThisMonth');
  String get ocrMobileOnly => t('ocrMobileOnly');
  String get scanInvoice => t('scanInvoice');
  String get scanInvoiceHelp => t('scanInvoiceHelp');
  String get openCamera => t('openCamera');
  String get chooseGallery => t('chooseGallery');
  String get noTextFound => t('noTextFound');
  String couldNotScan(String error) => t('couldNotScan', {'error': error});
  String get reviewScan => t('reviewScan');
  String get clientName => t('clientName');
  String get showScannedText => t('showScannedText');
  String get hideScannedText => t('hideScannedText');
  String get scannedItem => t('scannedItem');
  String get scannedClient => t('scannedClient');
  String get noExtraText => t('noExtraText');
  String get invoice => t('invoice');
  String get invoiceDeleted => t('invoiceDeleted');
  String get deleteInvoice => t('deleteInvoice');
  String get cannotBeUndone => t('cannotBeUndone');
  String get markAsPaid => t('markAsPaid');
  String get markAsUnpaid => t('markAsUnpaid');
  String get date => t('date');
  String get status => t('status');
  String invoiceShare(String number) => t('invoiceShare', {'number': number});
  String clientShare(String name) => t('clientShare', {'name': name});
  String totalShare(String amount) => t('totalShare', {'amount': amount});
  String statusShare(String status) => t('statusShare', {'status': status});
  String get settings => t('settings');
  String get manageBusiness => t('manageBusiness');
  String get clients => t('clients');
  String get catalogItems => t('catalogItems');
  String get darkMode => t('darkMode');
  String get language => t('language');
  String get rateUs => t('rateUs');
  String get rateUsTitle => t('rateUsTitle');
  String get rateUsBody => t('rateUsBody');
  String get feedback => t('feedback');
  String get feedbackHint => t('feedbackHint');
  String get thanksFeedback => t('thanksFeedback');
  String get privacyPolicy => t('privacyPolicy');
  String get privacyBody => t('privacyBody');
  String get restorePurchases => t('restorePurchases');
  String get proAlreadyActive => t('proAlreadyActive');
  String get noPurchaseFound => t('noPurchaseFound');
  String get shareApp => t('shareApp');
  String get shareAppText => t('shareAppText');
  String get communityGuidelines => t('communityGuidelines');
  String get communityBody => t('communityBody');
  String get goUnlimited => t('goUnlimited');
  String get goUnlimitedBody => t('goUnlimitedBody');
  String get unlock => t('unlock');
  String get proUnlocked => t('proUnlocked');
  String get getProAccess => t('getProAccess');
  String get professionalTemplates => t('professionalTemplates');
  String get unlimitedInvoices => t('unlimitedInvoices');
  String get customizeTemplate => t('customizeTemplate');
  String get vipSupport => t('vipSupport');
  String get removeAds => t('removeAds');
  String get trialEnabled => t('trialEnabled');
  String get threeDayTrial => t('threeDayTrial');
  String get thenWeekly => t('thenWeekly');
  String get trialDisabled => t('trialDisabled');
  String get free => t('free');
  String get yearly => t('yearly');
  String get perYear => t('perYear');
  String get continueForFree => t('continueForFree');
  String get trialDisclaimer => t('trialDisclaimer');
  String get noClientsYet => t('noClientsYet');
  String get noItemsYet => t('noItemsYet');
  String get businessEmail => t('businessEmail');
  String get businessPhone => t('businessPhone');
  String get businessAddress => t('businessAddress');
  String get switchToLight => t('switchToLight');
  String get switchToDark => t('switchToDark');
  String get adLabel => t('adLabel');
  String get growBusiness => t('growBusiness');
  String get sponsored => t('sponsored');
  String get open => t('open');
  String get onboardingTitle1 => t('onboardingTitle1');
  String get onboardingSubtitle1 => t('onboardingSubtitle1');
  String get onboardingTitle2 => t('onboardingTitle2');
  String get onboardingSubtitle2 => t('onboardingSubtitle2');
  String get onboardingTitle3 => t('onboardingTitle3');
  String get onboardingSubtitle3 => t('onboardingSubtitle3');
  String get onboardingTitle4 => t('onboardingTitle4');
  String get onboardingSubtitle4 => t('onboardingSubtitle4');

  List<OnboardingSlide> get onboardingSlides => [
        OnboardingSlide(title: onboardingTitle1, subtitle: onboardingSubtitle1, image: AppImages.onboarding1),
        OnboardingSlide(title: onboardingTitle2, subtitle: onboardingSubtitle2, image: AppImages.onboarding2),
        OnboardingSlide(title: onboardingTitle3, subtitle: onboardingSubtitle3, image: AppImages.onboarding3),
        OnboardingSlide(title: onboardingTitle4, subtitle: onboardingSubtitle4, image: AppImages.onboarding4),
      ];
}
