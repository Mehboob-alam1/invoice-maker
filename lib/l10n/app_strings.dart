import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_images.dart';
import '../core/constants/app_texts.dart';
import '../models/subscription_tier.dart';
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
  String get invoiceNumber => t('invoiceNumber');
  String get issueDate => t('issueDate');
  String get dueDate => t('dueDate');
  String get taxId => t('taxId');
  String get taxIdHint => t('taxIdHint');
  String get tax => t('tax');
  String get taxRate => t('taxRate');
  String get subtotal => t('subtotal');
  String get grandTotal => t('grandTotal');
  String get paymentTerms => t('paymentTerms');
  String get paymentTermsHint => t('paymentTermsHint');
  String get paymentInformation => t('paymentInformation');
  String get thankYou => t('thankYou');
  String get termsAndConditionsLabel => t('termsAndConditionsLabel');
  String get clientDetailLabel => t('clientDetailLabel');
  String get itemUnitLabel => t('itemUnitLabel');
  String get defaultPaymentTermsHint => t('defaultPaymentTermsHint');
  String get currency => t('currency');
  String get templateBlueYellow => t('templateBlueYellow');
  String get templateBlueYellowDesc => t('templateBlueYellowDesc');
  String get templateBlueCorporate => t('templateBlueCorporate');
  String get templateBlueCorporateDesc => t('templateBlueCorporateDesc');
  String get templateOrangeReceipt => t('templateOrangeReceipt');
  String get templateOrangeReceiptDesc => t('templateOrangeReceiptDesc');
  String get paymentReceiptTitle => t('paymentReceiptTitle');
  String get customerNameLabel => t('customerNameLabel');
  String get paymentStatusLabel => t('paymentStatusLabel');
  String get totalPaymentLabel => t('totalPaymentLabel');
  String get receiptDefaultNotes => t('receiptDefaultNotes');
  String get notesBoxTitle => t('notesBoxTitle');
  String get poNumber => t('poNumber');
  String get billFrom => t('billFrom');
  String get billTo => t('billTo');
  String get description => t('description');
  String get unitPrice => t('unitPrice');
  String get lineTotal => t('lineTotal');
  String get invoiceTemplate => t('invoiceTemplate');
  String get previewInvoice => t('previewInvoice');
  String get editInvoiceForPdf => t('editInvoiceForPdf');
  String get invoiceCreatedBanner => t('invoiceCreatedBanner');
  String get invoiceCreatedTitle => t('invoiceCreatedTitle');
  String get invoiceCreatedSnackbar => t('invoiceCreatedSnackbar');
  String get continueToInvoice => t('continueToInvoice');
  String get backToInvoices => t('backToInvoices');
  String get creatingInvoice => t('creatingInvoice');
  String get saveChanges => t('saveChanges');
  String get viewInvoice => t('viewInvoice');
  String get freeTemplatesHint => t('freeTemplatesHint');
  String get browseAllTemplates => t('browseAllTemplates');
  String get chooseTemplate => t('chooseTemplate');
  String get templatesSheetSubtitle => t('templatesSheetSubtitle');
  String get previewAnyTemplateHint => t('previewAnyTemplateHint');
  String get useThisTemplate => t('useThisTemplate');
  String previewTemplate(String name) => t('previewTemplate', {'name': name});
  String get proTemplateRequired => t('proTemplateRequired');
  String get proTemplateRequiredBody => t('proTemplateRequiredBody');
  String get preview => t('preview');
  String get printPdf => t('printPdf');
  String get sharePdf => t('sharePdf');
  String get premiumTemplates => t('premiumTemplates');
  String get premiumTemplatesHint => t('premiumTemplatesHint');
  String get profile => t('profile');
  String get accountNotSignedIn => t('accountNotSignedIn');
  String get signIn => t('signIn');
  String get settingsBusinessNameLabel => t('settingsBusinessNameLabel');
  String get googleAccountPhotoHint => t('googleAccountPhotoHint');
  String get companyLogoComingSoon => t('companyLogoComingSoon');
  String get editProfileDetails => t('editProfileDetails');
  String get invoice => t('invoice');
  String get invoiceDeleted => t('invoiceDeleted');
  String get deleteInvoice => t('deleteInvoice');
  String get cannotBeUndone => t('cannotBeUndone');
  String get markAsPaid => t('markAsPaid');
  String get markAsUnpaid => t('markAsUnpaid');
  String get partiallyPaid => t('partiallyPaid');
  String get overdueOnly => t('overdueOnly');
  String get createEstimate => t('createEstimate');
  String get estimateSubtitle => t('estimateSubtitle');
  String get estimates => t('estimates');
  String get estimateDraft => t('estimateDraft');
  String get estimateSent => t('estimateSent');
  String get estimateAccepted => t('estimateAccepted');
  String get estimateDeclined => t('estimateDeclined');
  String get convertToInvoice => t('convertToInvoice');
  String get newEstimate => t('newEstimate');
  String get saveEstimate => t('saveEstimate');
  String get noEstimatesYet => t('noEstimatesYet');
  String get discount => t('discount');
  String get shipping => t('shipping');
  String get deposit => t('deposit');
  String get taxInclusive => t('taxInclusive');
  String get taxName => t('taxName');
  String get defaultCurrency => t('defaultCurrency');
  String get itemTax => t('itemTax');
  String get percent => t('percent');
  String get amount => t('amount');
  String get notes => t('notes');
  String get monthTokenHint => t('monthTokenHint');
  String get repeatInvoice => t('repeatInvoice');
  String get repeatWeekly => t('repeatWeekly');
  String get repeatMonthly => t('repeatMonthly');
  String get repeatCustom => t('repeatCustom');
  String get repeatEveryDays => t('repeatEveryDays');
  String get repeatUntil => t('repeatUntil');
  String get repeatStart => t('repeatStart');
  String get serviceFrom => t('serviceFrom');
  String get serviceTo => t('serviceTo');
  String get recurringLimit => t('recurringLimit');
  String get recurringReady => t('recurringReady');
  String get unpaidTotal => t('unpaidTotal');
  String get overdueAmount => t('overdueAmount');
  String get paidThisMonth => t('paidThisMonth');
  String get topClients => t('topClients');
  String get exportCsv => t('exportCsv');
  String get thisMonth => t('thisMonth');
  String get allTime => t('allTime');
  String get logo => t('logo');
  String get signature => t('signature');
  String get stamp => t('stamp');
  String get stampPro => t('stampPro');
  String get clearSignature => t('clearSignature');
  String get usePhoto => t('usePhoto');
  String get cropLogo => t('cropLogo');
  String get recordPayment => t('recordPayment');
  String get amountPaid => t('amountPaid');
  String get balanceDue => t('balanceDue');
  String get paymentMethod => t('paymentMethod');
  String get paymentAmount => t('paymentAmount');
  String get howToPay => t('howToPay');
  String get bankName => t('bankName');
  String get accountHolder => t('accountHolder');
  String get ibanOrAccount => t('ibanOrAccount');
  String get mobileWallet => t('mobileWallet');
  String get paymentLink => t('paymentLink');
  String get paymentNote => t('paymentNote');
  String get sendWhatsApp => t('sendWhatsApp');
  String get sendEmail => t('sendEmail');
  String get sendSms => t('sendSms');
  String get pdfExportFailed => t('pdfExportFailed');
  String get inviteFriends => t('inviteFriends');
  String get referralHeadline => t('referralHeadline');
  String get copyCode => t('copyCode');
  String get codeCopied => t('codeCopied');
  String get shareInvite => t('shareInvite');
  String get haveACode => t('haveACode');
  String get referralCode => t('referralCode');
  String referralProgress(int qualified, int pending) => t('referralProgress', {
        'qualified': '$qualified',
        'pending': '$pending',
      });
  String referralNextMilestone(int count) => t('referralNextMilestone', {'count': '$count'});
  String get referralMilestonesDone => t('referralMilestonesDone');
  String get referralRewardsList => t('referralRewardsList');
  String get referralTerms => t('referralTerms');
  String referralProUntil(String date) => t('referralProUntil', {'date': date});
  String get useTemplateToken => t('useTemplateToken');
  String get referralCodeSaved => t('referralCodeSaved');
  String get paymentReminders => t('paymentReminders');
  String get reminderTime => t('reminderTime');
  String get reminderMessage => t('reminderMessage');
  String get reminderFreeHint => t('reminderFreeHint');
  String get reminderProHint => t('reminderProHint');
  String invoiceReminderBody({
    required String client,
    required String number,
    required String amount,
    required String due,
    required String pay,
  }) =>
      t('invoiceReminderBody', {
        'client': client,
        'number': number,
        'amount': amount,
        'due': due,
        'pay': pay,
      });
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
  String get notifications => t('notifications');
  String get notificationsOn => t('notificationsOn');
  String get notificationsOff => t('notificationsOff');
  String get notificationsEnabledSnack => t('notificationsEnabledSnack');
  String get notificationsOpenSettingsSnack => t('notificationsOpenSettingsSnack');
  String get rateUs => t('rateUs');
  String get rateUsTitle => t('rateUsTitle');
  String get rateUsBody => t('rateUsBody');
  String get rateUsCombinedSubtitle => t('rateUsCombinedSubtitle');
  String get feedbackOptionalLabel => t('feedbackOptionalLabel');
  String get submitRating => t('submitRating');
  String get notNow => t('notNow');
  String lastUpdated(String date) => t('lastUpdated', {'date': date});
  String get subscriptionExpiredTitle => t('subscriptionExpiredTitle');
  String get subscriptionExpiredBody => t('subscriptionExpiredBody');
  String get playStoreSubscriptionHint => t('playStoreSubscriptionHint');
  String get feedback => t('feedback');
  String get feedbackHint => t('feedbackHint');
  String get thanksFeedback => t('thanksFeedback');
  String get privacyPolicy => t('privacyPolicy');
  String get privacyOptions => t('privacyOptions');
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
  String get subscribeNow => t('subscribeNow');
  String get subscriptionStoreUnavailable => t('subscriptionStoreUnavailable');
  String get subscriptionProductsLoading => t('subscriptionProductsLoading');
  String get purchaseInProgress => t('purchaseInProgress');
  String get restoreCompletePro => t('restoreCompletePro');
  String get restoreCompleteNone => t('restoreCompleteNone');
  String get restoreFailed => t('restoreFailed');
  String get googleAccount => t('googleAccount');
  String get googleAccountHint => t('googleAccountHint');
  String get signInWithGoogle => t('signInWithGoogle');
  String get signOut => t('signOut');
  String get deleteAccount => t('deleteAccount');
  String get deleteAccountWeb => t('deleteAccountWeb');
  String get deleteAccountTitle => t('deleteAccountTitle');
  String get deleteAccountBody => t('deleteAccountBody');
  String get deleteAccountConfirm => t('deleteAccountConfirm');
  String get deleteAccountSuccess => t('deleteAccountSuccess');
  String get deleteAccountSignInRequired => t('deleteAccountSignInRequired');
  String deleteAccountUidHint(String uid) => t('deleteAccountUidHint', {'uid': uid});
  String get googleUser => t('googleUser');
  String get signInToSyncSubscription => t('signInToSyncSubscription');
  String get googleLoginTitle => t('googleLoginTitle');
  String get googleLoginSubtitle => t('googleLoginSubtitle');
  String get skipGoogleLogin => t('skipGoogleLogin');
  String get googleSignInSuccess => t('googleSignInSuccess');
  String get subscriptionPlansTitle => t('subscriptionPlansTitle');
  String get chooseBillingPeriod => t('chooseBillingPeriod');
  String get billingMonthly => t('billingMonthly');
  String get billingYearly => t('billingYearly');
  String get yearlySaveHint => t('yearlySaveHint');
  String get tierFreeName => t('tierFreeName');
  String get tierPremiumName => t('tierPremiumName');
  String get tierProName => t('tierProName');
  String get tierFreePrice => t('tierFreePrice');
  String get recommendedPlan => t('recommendedPlan');
  String get activePlanBadge => t('activePlanBadge');
  String get currentPlanFree => t('currentPlanFree');
  String get planActivated => t('planActivated');
  String get viewPlans => t('viewPlans');
  String get pricingDisclaimer => t('pricingDisclaimer');
  String get playStoreManageHint => t('playStoreManageHint');
  String get unlimitedInvoicesToday => t('unlimitedInvoicesToday');
  String get dailyInvoiceLimitTitle => t('dailyInvoiceLimitTitle');
  String get premiumTemplateRequired => t('premiumTemplateRequired');
  String get premiumTemplateRequiredBody => t('premiumTemplateRequiredBody');
  String get customizeProOnly => t('customizeProOnly');
  String get trialDisclaimer => t('trialDisclaimer');

  String dailyInvoiceLimitBody(int limit) => t('dailyInvoiceLimitBody', {'limit': '$limit'});
  String get watchAdForInvoice => t('watchAdForInvoice');
  String get watchAdForAiCredit => t('watchAdForAiCredit');
  String get goPro => t('goPro');

  String invoicesRemainingToday(int remaining, int limit, int created) => t(
        'invoicesRemainingToday',
        {'remaining': '$remaining', 'limit': '$limit', 'created': '$created'},
      );

  String currentPlanLabel(String plan) => t('currentPlanLabel', {'plan': plan});

  String pricePerMonth(String price) => t('pricePerMonthTemplate', {'price': price});

  String pricePerYear(String price) => t('pricePerYearTemplate', {'price': price});

  String subscribeTo(String plan) => t('subscribeToTemplate', {'plan': plan});

  String homeQuotaBanner(int remaining, int limit) =>
      t('homeQuotaBanner', {'remaining': '$remaining', 'limit': '$limit'});
  String get premiumUpsellTitle => t('premiumUpsellTitle');
  String get premiumUpsellSubtitle => t('premiumUpsellSubtitle');
  String get premiumUpsellFeature1 => t('premiumUpsellFeature1');
  String get premiumUpsellFeature2 => t('premiumUpsellFeature2');
  String get premiumUpsellFeature3 => t('premiumUpsellFeature3');
  String get premiumUpsellPriceHint => t('premiumUpsellPriceHint');
  String get premiumUpsellCta => t('premiumUpsellCta');
  String get premiumUpsellDismiss => t('premiumUpsellDismiss');

  String tierDisplayName(SubscriptionTier tier) => switch (tier) {
        SubscriptionTier.free => tierFreeName,
        SubscriptionTier.premium => tierPremiumName,
        SubscriptionTier.pro => tierProName,
      };

  String suggestedMonthlyPrice(SubscriptionTier tier) => switch (tier) {
        SubscriptionTier.premium => t('suggestedPremiumMonthly'),
        SubscriptionTier.pro => t('suggestedProMonthly'),
        SubscriptionTier.free => tierFreePrice,
      };

  String suggestedYearlyPrice(SubscriptionTier tier) => switch (tier) {
        SubscriptionTier.premium => t('suggestedPremiumYearly'),
        SubscriptionTier.pro => t('suggestedProYearly'),
        SubscriptionTier.free => tierFreePrice,
      };

  List<String> get tierFreeFeatures => [
        t('tierFreeFeature1'),
        t('tierFreeFeature2'),
        t('tierFreeFeature3'),
        t('tierFreeFeature4'),
      ];

  List<String> get tierPremiumFeatures => [
        t('tierPremiumFeature1'),
        t('tierPremiumFeature2'),
        t('tierPremiumFeature3'),
        t('tierPremiumFeature4'),
      ];

  List<String> get tierProFeatures => [
        t('tierProFeature1'),
        t('tierProFeature2'),
        t('tierProFeature3'),
        t('tierProFeature4'),
        t('tierProFeature5'),
      ];

  String get aiPaidRequiredTitle => t('aiPaidRequiredTitle');
  String get aiPaidRequiredBody => t('aiPaidRequiredBody');
  String get aiPremiumPlanBadge => t('aiPremiumPlanBadge');
  String get aiInputTooLongTitle => t('aiInputTooLongTitle');
  String aiInputTooLongBody(int maxChars, int maxTokens) =>
      t('aiInputTooLongBody', {'maxChars': '$maxChars', 'maxTokens': '$maxTokens'});
  String get aiMonthlyLimitTitle => t('aiMonthlyLimitTitle');
  String aiMonthlyLimitBody(int remaining, int limit, int needed) => t('aiMonthlyLimitBody', {
        'remaining': '$remaining',
        'limit': '$limit',
        'needed': '$needed',
      });
  String aiTokensRemainingHint(int remaining, int limit) =>
      t('aiTokensRemainingHint', {'remaining': '$remaining', 'limit': '$limit'});
  String aiFreeCreditsRemainingHint(int remaining, int limit) =>
      t('aiFreeCreditsRemainingHint', {'remaining': '$remaining', 'limit': '$limit'});
  String aiFreeCreditsUsedBody(int limit) =>
      t('aiFreeCreditsUsedBody', {'limit': '$limit'});
  String get aiNoCreditsBadge => t('aiNoCreditsBadge');
  String get noClientsYet => t('noClientsYet');
  String get noItemsYet => t('noItemsYet');
  String get businessEmail => t('businessEmail');
  String get businessPhone => t('businessPhone');
  String get businessAddress => t('businessAddress');
  String get switchToLight => t('switchToLight');
  String get switchToDark => t('switchToDark');
  String get adLabel => t('adLabel');
  String get loadingAd => t('loadingAd');
  String get growBusiness => t('growBusiness');
  String get sponsored => t('sponsored');
  String get open => t('open');
  String get updateReadyTitle => t('updateReadyTitle');
  String get updateReadyBody => t('updateReadyBody');
  String get restartApp => t('restartApp');
  String get checkForUpdates => t('checkForUpdates');
  String get updateAvailableTitle => t('updateAvailableTitle');
  String get updateAvailableBody => t('updateAvailableBody');
  String get updateNow => t('updateNow');
  String get upToDateTitle => t('upToDateTitle');
  String get upToDateBody => t('upToDateBody');
  String get updateCheckFailedTitle => t('updateCheckFailedTitle');
  String get updateCheckFailedBody => t('updateCheckFailedBody');
  String get checklistTitle => t('checklistTitle');
  String get checklistLogo => t('checklistLogo');
  String get checklistPayment => t('checklistPayment');
  String get checklistInvoice => t('checklistInvoice');
  String get checklistShare => t('checklistShare');
  String get checklistInvite => t('checklistInvite');
  String get checklistReward => t('checklistReward');
  String streakSent(int count) => t('streakSent', {'count': '$count'});
  String milestoneToast(int count) => t('milestoneToast', {'count': '$count'});
  String get shareInviteSnack => t('shareInviteSnack');
  String get watermarkFooter => t('watermarkFooter');
  String get removeWatermark => t('removeWatermark');
  String get watermarkRemoved => t('watermarkRemoved');
  String get channelReminders => t('channelReminders');
  String get channelAccount => t('channelAccount');
  String get channelTips => t('channelTips');
  String get channelPromos => t('channelPromos');
  String get notificationChannelsHint => t('notificationChannelsHint');
  String get winBackGranted => t('winBackGranted');
  String get announcementDismiss => t('announcementDismiss');
  String get backupTitle => t('backupTitle');
  String get backupNow => t('backupNow');
  String get backupRestore => t('backupRestore');
  String backupLast(String when) => t('backupLast', {'when': when});
  String get backupNever => t('backupNever');
  String get backupDone => t('backupDone');
  String get backupRestored => t('backupRestored');
  String get backupFreeHint => t('backupFreeHint');
  String get backupProHint => t('backupProHint');
  String get backupSignInTitle => t('backupSignInTitle');
  String get backupSignInBody => t('backupSignInBody');
  String get backupSaving => t('backupSaving');
  String get backupRestoring => t('backupRestoring');
  String get backupEmpty => t('backupEmpty');
  String get backupOffline => t('backupOffline');
  String get backupFailed => t('backupFailed');
  String get backupSignInAgain => t('backupSignInAgain');
  String get backupSignInCancelled => t('backupSignInCancelled');
  String get backupNone => t('backupNone');
  String get backupDamaged => t('backupDamaged');
  String get backupRestoreTitle => t('backupRestoreTitle');
  String get backupRestoreBody => t('backupRestoreBody');
  String get backupRestoreFailed => t('backupRestoreFailed');
  String get backupImagesSkipped => t('backupImagesSkipped');
  String get backupTooLarge => t('backupTooLarge');
  String get duplicateInvoice => t('duplicateInvoice');
  String get createAgain => t('createAgain');
  String get shareImage => t('shareImage');
  String get writeReminder => t('writeReminder');
  String politeReminder({
    required String client,
    required String number,
    required String amount,
    required String due,
  }) =>
      t('politeReminder', {'client': client, 'number': number, 'amount': amount, 'due': due});
  String get improveDescription => t('improveDescription');
  String get suggestDueNotes => t('suggestDueNotes');
  String get suggestedNotes => t('suggestedNotes');
  String get voiceInvoice => t('voiceInvoice');
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
