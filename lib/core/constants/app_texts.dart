import 'app_images.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.image,
  });

  final String title;
  final String subtitle;
  final String image;
}

/// English source copy. Other languages fall back to these values.
class AppTexts {
  AppTexts._();

  static const next = 'Next';
  static const getStarted = 'Get Started';
  static const continueLabel = 'Continue';
  static const save = 'Save';
  static const cancel = 'Cancel';
  static const ok = 'OK';
  static const close = 'Close';
  static const delete = 'Delete';
  static const send = 'Send';

  static const searchLanguage = 'Search language';
  static const selectLanguage = 'Choose your language';
  static const selectLanguageSubtitle = 'You can change this later in Settings.';

  static const businessNameTitle = "What's your\nbusiness name?";
  static const businessNameHint = 'Business Name';
  static const businessNameHelp = 'Or use your own name instead. You can change it later in Settings';
  static const defaultBusinessName = 'My Business';

  static const invoices = 'Invoices';
  static const unpaid = 'Unpaid';
  static const paid = 'Paid';
  static const overdue = 'Overdue';
  static const scanWithOcr = 'Scan with OCR';
  static const scanWithOcrSubtitle = 'Capture invoice details from camera and gallery';
  static const ocrScanner = 'OCR Scanner';
  static const startByCreatingInvoice = 'Start by creating an invoice';
  static const createInvoice = 'Create invoice';

  static const howCreateInvoice = 'How would you like to create\nyour invoice?';
  static const customInvoice = 'Custom Invoice';
  static const customInvoiceSubtitle = 'Create an invoice manually with full control';
  static const scanOcrOptionSubtitle = 'Open camera or gallery and extract invoice details';
  static const createWithAi = 'Create with AI';
  static const createWithAiSubtitle = 'Let AI generate an invoice for you in seconds';

  static const newInvoice = 'New Invoice';
  static const client = 'Client';
  static const items = 'Items';
  static const total = 'Total';
  static const addClient = 'Add Client';
  static const addItems = 'Add Items';
  static const addNewClient = 'Add new client';
  static const selectClient = 'Select client';
  static const fromSavedItems = 'From saved items';
  static const newItem = 'New Item';
  static const addClientAndItemFirst = 'Add a client and at least one item first.';
  static const startByAddingClient = 'Start by adding client';
  static const saveInvoice = 'Save Invoice';

  static const editClient = 'Edit Client';
  static const clientFormHelp = 'Enter the client details and tap Save.';
  static const name = 'Name';
  static const clientNameHint = "Client's name or business";
  static const enterName = 'Please enter a name';
  static const phoneNumber = 'Phone number';
  static const phoneHint = 'e.g. 0300 1234567';
  static const email = 'Email';
  static const emailHint = 'client@email.com';
  static const enterValidEmail = 'Enter a valid email';
  static const address = 'Address';
  static const addressHint = 'Street, city, country';

  static const editItem = 'Edit Item';
  static const itemName = 'New item';
  static const itemNameHint = 'e.g. Website design';
  static const enterItemName = 'Please enter an item name';
  static const notesOptional = 'Notes (optional)';
  static const notesHint = 'Add extra details for this item';
  static const quantity = 'Quantity';
  static const enterQuantity = 'Enter a quantity of 1 or more';
  static const price = 'Price';
  static const enterPrice = 'Please enter a price';
  static const enterValidPrice = 'Enter a valid price';

  static const aiIntro = "Enter a few details — we'll handle the rest.";
  static const clientNameOptional = "Client's Name (optional)";
  static const clientNameHintAi = "Enter the client's name or business";
  static const writeInvoiceDetail = 'Write your invoice in detail';
  static const invoiceThisMonthHint = 'Invoice for this month';
  static const generating = 'Generating…';
  static const generateInvoice = 'Generate Invoice';
  static const aiFillHint = '✨ AI will fill out invoice details automatically';
  static const newClientFallback = 'New Client';
  static const serviceThisMonth = 'Service for this month';

  static const ocrMobileOnly = 'OCR works on Android and iOS devices.';
  static const scanInvoice = 'Scan invoice';
  static const scanInvoiceHelp = 'Take a photo or choose an image from your gallery.';
  static const openCamera = 'Open camera';
  static const chooseGallery = 'Choose from gallery';
  static const noTextFound = 'No text found. Try a clearer photo.';
  static const couldNotScan = 'Could not scan image: {error}';
  static const reviewScan = 'Review scan';
  static const clientName = 'Client name';
  static const showScannedText = 'Show scanned text';
  static const hideScannedText = 'Hide scanned text';
  static const scannedItem = 'Scanned item';
  static const scannedClient = 'Scanned client';
  static const noExtraText = 'No extra text';
  static const invoiceNumber = 'Invoice number';
  static const issueDate = 'Issue date';
  static const dueDate = 'Due date';
  static const taxId = 'Tax / VAT ID';
  static const taxIdHint = 'e.g. GB123456789';
  static const tax = 'Tax';
  static const taxRate = 'Tax rate (%)';
  static const subtotal = 'Subtotal';
  static const grandTotal = 'Grand total';
  static const paymentTerms = 'Payment terms';
  static const paymentTermsHint = 'Net 30, due on receipt…';
  static const poNumber = 'PO number';
  static const billFrom = 'Bill from';
  static const billTo = 'Bill to';
  static const description = 'Description';
  static const unitPrice = 'Unit price';
  static const lineTotal = 'Line total';
  static const invoiceTemplate = 'Invoice template';
  static const templateClassic = 'Classic';
  static const templateClassicDesc = 'Bordered layout with full line-item table';
  static const templateModern = 'Modern';
  static const templateModernDesc = 'Bold header bar and clean totals';
  static const templateMinimal = 'Minimal';
  static const templateMinimalDesc = 'Light typography, ideal for quick shares';
  static const templateAurora = 'Aurora';
  static const templateAuroraDesc = 'Violet–pink gradient with Poppins';
  static const templateSunset = 'Sunset';
  static const templateSunsetDesc = 'Warm orange–red gradient with Montserrat';
  static const templateOcean = 'Ocean';
  static const templateOceanDesc = 'Deep blue gradient with Raleway';
  static const templateEmerald = 'Emerald';
  static const templateEmeraldDesc = 'Green luxury gradient with Playfair';
  static const templateRoyal = 'Royal';
  static const templateRoyalDesc = 'Indigo and gold gradient with Merriweather';
  static const templateRose = 'Rose';
  static const templateRoseDesc = 'Pink coral gradient with Nunito';
  static const templateMidnight = 'Midnight';
  static const templateMidnightDesc = 'Dark slate gradient with Space Grotesk';
  static const templateRedModern = 'Red Modern';
  static const templateRedModernDesc = 'Cream paper, maroon fold, bold company invoice';
  static const templateBlueYellow = 'Blue & Yellow';
  static const templateBlueYellowDesc = 'Navy wave banner with gold diamond logo';
  static const templateBlueCorporate = 'Blue Corporate';
  static const templateBlueCorporateDesc = 'Navy-teal diagonal header with pinwheel mark';
  static const templateOrangeReceipt = 'Orange Receipt';
  static const templateOrangeReceiptDesc = 'Navy & orange waves — payment receipt layout';
  static const paymentReceiptTitle = 'PAYMENT RECEIPT';
  static const customerNameLabel = 'Customer Name:';
  static const paymentStatusLabel = 'Payment Status';
  static const totalPaymentLabel = 'Total Payment';
  static const receiptDefaultNotes = 'Thank you for your payment and trust in our company.';
  static const notesBoxTitle = 'NOTES';
  static const paymentInformation = 'Payment Information:';
  static const thankYou = 'Thank You!';
  static const termsAndConditionsLabel = 'Terms & Conditions';
  static const clientDetailLabel = 'Client detail';
  static const itemUnitLabel = 'Unit';
  static const defaultPaymentTermsHint = 'Payment due within the terms stated on this invoice.';
  static const currency = 'Currency';
  static const freeTemplatesHint = '3 free layouts for every invoice';
  static const browseAllTemplates = 'Browse all templates';
  static const chooseTemplate = 'Choose template';
  static const templatesSheetSubtitle = 'Preview any design free · Pro required to save with premium templates';
  static const previewAnyTemplateHint = 'Tap preview to see your invoice · Use Pro templates after subscribing';
  static const useThisTemplate = 'Use this template';
  static const previewTemplate = 'Preview: {name}';
  static const proTemplateRequired = 'Pro template';
  static const proTemplateRequiredBody =
      'Subscribe to save invoices with this premium gradient template. You can keep previewing all designs anytime.';
  static const preview = 'Preview';
  static const printPdf = 'Print PDF';
  static const sharePdf = 'Share PDF';
  static const premiumTemplates = 'Premium templates';
  static const premiumTemplatesHint = '11 premium designs — gradients & Canva-style layouts (Pro)';
  static const profile = 'Profile';
  static const accountNotSignedIn = 'Not signed in';
  static const signIn = 'Sign in';
  static const settingsBusinessNameLabel = 'Company / business name';
  static const googleAccountPhotoHint = 'Google photo — account only, not your invoice logo';
  static const companyLogoComingSoon =
      'Company logo on invoices will be available with Pro templates later. It is not your Google profile picture.';
  static const editProfileDetails = 'Email, phone, address & tax ID';
  static const previewInvoice = 'Preview';
  static const editInvoiceForPdf = 'Edit invoice (PDF)';
  static const invoiceCreatedBanner = 'Review below, tweak details, then open the full invoice or share PDF.';
  static const invoiceCreatedTitle = 'Invoice created';
  static const invoiceCreatedSnackbar = 'Invoice saved — preview opened';
  static const continueToInvoice = 'Open invoice';
  static const backToInvoices = 'Back to list';
  static const creatingInvoice = 'Creating…';
  static const saveChanges = 'Save changes';
  static const viewInvoice = 'View invoice';

  static const invoice = 'Invoice';
  static const invoiceDeleted = 'This invoice was deleted.';
  static const deleteInvoice = 'Delete invoice?';
  static const cannotBeUndone = 'This cannot be undone.';
  static const markAsPaid = 'Mark as paid';
  static const markAsUnpaid = 'Mark as unpaid';
  static const date = 'Date';
  static const status = 'Status';
  static const invoiceShare = 'Invoice {number}';
  static const clientShare = 'Client: {name}';
  static const totalShare = 'Total: {amount}';
  static const statusShare = 'Status: {status}';

  static const settings = 'Settings';
  static const manageBusiness = 'Manage business';
  static const clients = 'Clients';
  static const catalogItems = 'Items';
  static const darkMode = 'Dark Mode';
  static const language = 'Language';
  static const rateUs = 'Rate Us';
  static const rateUsTitle = 'Rate Invoice Maker';
  static const rateUsBody = 'Thanks for using the app. If this were in a store, this would open the listing.';
  static const feedback = 'Feedback';
  static const feedbackHint = 'Tell us what to improve';
  static const thanksFeedback = 'Thanks — your feedback was saved on this device.';
  static const privacyPolicy = 'Privacy Policy';
  static const privacyBody =
      'Invoices, clients, and scans stay on this device. Camera and gallery access is used only when you scan a document. Nothing is uploaded unless you share it yourself.';
  static const restorePurchases = 'Restore Purchases';
  static const proAlreadyActive = 'Pro access is already active.';
  static const noPurchaseFound = 'No previous purchase found.';
  static const shareApp = 'Share App';
  static const shareAppText = 'Invoice Maker — create and scan invoices on your phone.';
  static const communityGuidelines = 'Community Guidelines';
  static const communityBody =
      'Use the app to create genuine invoices. Do not scan or store other people’s documents without permission.';
  static const goUnlimited = 'Go Unlimited';
  static const goUnlimitedBody =
      'Send beautiful invoices, look professional, and build strong relationships with clients';
  static const unlock = 'Unlock';
  static const proUnlocked = 'Pro is unlocked on this device.';

  static const getProAccess = 'Get Pro Access';
  static const professionalTemplates = '7 premium gradient templates';
  static const unlimitedInvoices = 'Unlimited Invoices';
  static const customizeTemplate = 'Customize your template';
  static const vipSupport = 'VIP Customer Support';
  static const removeAds = 'Remove Ads';
  static const trialEnabled = 'Trial Enabled';
  static const threeDayTrial = '3-Day Free Trial';
  static const thenWeekly = 'then Rs 3,350.00/week';
  static const trialDisabled = 'Trial disabled';
  static const free = 'FREE';
  static const yearly = 'Yearly';
  static const perYear = 'per year';
  static const continueForFree = 'CONTINUE FOR FREE';
  static const subscribeNow = 'Subscribe';
  static const subscriptionStoreUnavailable = 'Subscriptions are not available on this device.';
  static const subscriptionProductsLoading = 'Loading plans…';
  static const purchaseInProgress = 'Processing purchase…';
  static const restoreCompletePro = 'Pro subscription restored.';
  static const restoreCompleteNone = 'No active subscription found.';
  static const restoreFailed = 'Could not restore purchases. Try again later.';
  static const googleAccount = 'Google account';
  static const googleAccountHint =
      'Sign in to save your profile and Pro subscription to the cloud and restore them on a new device.';
  static const signInWithGoogle = 'Sign in with Google';
  static const signOut = 'Sign out';
  static const googleUser = 'Google user';
  static const signInToSyncSubscription =
      'You\'re Pro on this device. Sign in with Google in Settings to back up your subscription.';
  static const googleLoginTitle = 'Sign in with Google';
  static const googleLoginSubtitle =
      'Back up your business profile and Pro subscription. You can skip and sign in later in Settings.';
  static const skipGoogleLogin = 'Skip for now';
  static const googleSignInSuccess = 'Signed in successfully';

  static const subscriptionPlansTitle = 'Plans & billing';
  static const chooseBillingPeriod = 'Billing period';
  static const billingMonthly = 'Monthly';
  static const billingYearly = 'Yearly';
  static const yearlySaveHint = 'Yearly plans save about 33% vs paying monthly.';
  static const tierFreeName = 'Free';
  static const tierPremiumName = 'Premium';
  static const tierProName = 'Pro';
  static const tierFreePrice = '\$0 — always free';
  static const recommendedPlan = 'Popular';
  static const activePlanBadge = 'Current';
  static const currentPlanFree = 'Free plan — no purchase needed';
  static const planActivated = 'Your plan is active on this device.';
  static const viewPlans = 'View plans';
  static const pricingDisclaimer =
      'Prices shown from Google Play when available. Suggested: Premium \$4.99/mo or \$39.99/yr; Pro \$9.99/mo or \$79.99/yr.';
  static const playStoreManageHint =
      'Cancel or change plans anytime in Google Play → Payments & subscriptions.';
  static const unlimitedInvoicesToday = 'Unlimited invoices today on Pro.';
  static const dailyInvoiceLimitTitle = 'Daily invoice limit reached';
  static const dailyInvoiceLimitBody =
      'Your plan allows {limit} invoices per day. Upgrade for more, or try again tomorrow.';
  static const invoicesRemainingToday =
      '{remaining} of {limit} invoices left today ({created} created). Resets at midnight.';
  static const currentPlanLabel = 'Current plan: {plan}';
  static const pricePerMonthTemplate = '{price} / month';
  static const pricePerYearTemplate = '{price} / year';
  static const subscribeToTemplate = 'Subscribe to {plan}';
  static const suggestedPremiumMonthly = '\$4.99 / month (set in Play Console)';
  static const suggestedPremiumYearly = '\$39.99 / year — save ~33%';
  static const suggestedProMonthly = '\$9.99 / month (set in Play Console)';
  static const suggestedProYearly = '\$79.99 / year — save ~33%';
  static const tierFreeFeature1 = '3 invoices per day';
  static const tierFreeFeature2 = 'Ads on all screens';
  static const tierFreeFeature3 = '3 free invoice templates';
  static const tierPremiumFeature1 = '10 invoices per day';
  static const tierPremiumFeature2 = 'Fewer ads (no interstitials, less app-open)';
  static const tierPremiumFeature3 = 'All Pro gradient templates';
  static const tierPremiumFeature4 = 'AI invoices — 40,000 tokens / month';
  static const tierProFeature1 = 'Unlimited invoices';
  static const tierProFeature2 = 'No ads';
  static const tierProFeature3 = 'Pro templates + customize each template';
  static const tierProFeature4 = 'AI invoices — 150,000 tokens / month';
  static const tierProFeature5 = 'Priority customer support';
  static const aiPaidRequiredTitle = 'AI invoices — Premium or Pro';
  static const aiPaidRequiredBody =
      'Create with AI is included on Premium (40k tokens/month) and Pro (150k tokens/month). Upgrade to start generating.';
  static const aiPremiumPlanBadge = 'Premium & Pro';
  static const aiTokensRemainingHint = '{remaining} of {limit} AI tokens left this month';
  static const aiInputTooLongTitle = 'Description too long';
  static const aiInputTooLongBody =
      'Your plan allows up to {maxChars} characters (~{maxTokens} tokens) per AI request. Shorten the text and try again.';
  static const aiMonthlyLimitTitle = 'AI token limit reached';
  static const aiMonthlyLimitBody =
      'You have {remaining} tokens left this month (limit {limit}). This request needs about {needed} tokens. Upgrade to Pro for a higher monthly allowance, or wait until next month.';
  static const premiumTemplateRequired = 'Premium template';
  static const premiumTemplateRequiredBody =
      'Upgrade to Premium or Pro to use this template on your invoices.';
  static const customizeProOnly = 'Template customization is a Pro feature.';
  static const homeQuotaBanner = '{remaining}/{limit} invoices left today';
  static const premiumUpsellTitle = 'Unlock Premium';
  static const premiumUpsellSubtitle =
      'Create more invoices, use beautiful Pro templates, and see fewer ads.';
  static const premiumUpsellFeature1 = '10 invoices per day (vs 3 on Free)';
  static const premiumUpsellFeature2 = 'All premium invoice templates';
  static const premiumUpsellFeature3 = 'No interstitial ads + fewer app-open ads';
  static const premiumUpsellPriceHint = 'From about \$4.99/month — yearly saves ~33%.';
  static const premiumUpsellCta = 'See Premium plans';
  static const premiumUpsellDismiss = 'Maybe later';

  static const trialDisclaimer =
      'After 3 day free trial then Rs 3,350.00 will start. Cancel anytime 24 hour before renewal.';

  static const noClientsYet = 'No clients yet. Tap + to add one.';
  static const noItemsYet = 'No saved items yet. Tap + to add one.';
  static const businessEmail = 'Email';
  static const businessPhone = 'Phone';
  static const businessAddress = 'Address';
  static const switchToLight = 'Switch to light mode';
  static const switchToDark = 'Switch to dark mode';
  static const adLabel = 'Ad';
  static const loadingAd = 'Loading ad…';
  static const growBusiness = 'Grow your business faster';
  static const sponsored = 'Sponsored · Invoice Maker';
  static const open = 'Open';

  static const onboardingTitle1 = 'Create Accurate Invoices\nIn Just a Few Clicks';
  static const onboardingSubtitle1 =
      'Manage your business from anywhere — no professional experience required';
  static const onboardingTitle2 = 'Customize Your Template\nAny Way You Like';
  static const onboardingSubtitle2 = 'Choose a template that fits your style and make it truly yours.';
  static const onboardingTitle3 = 'Create Unlimited Invoices\nand Estimates';
  static const onboardingSubtitle3 =
      'Generate professional invoices & estimates anytime, as often as you like';
  static const onboardingTitle4 = 'Share Instantly With\nYour Customers';
  static const onboardingSubtitle4 =
      'Easily share important details with your clients anytime, anywhere';

  static const List<OnboardingSlide> onboarding = [
    OnboardingSlide(title: onboardingTitle1, subtitle: onboardingSubtitle1, image: AppImages.onboarding1),
    OnboardingSlide(title: onboardingTitle2, subtitle: onboardingSubtitle2, image: AppImages.onboarding2),
    OnboardingSlide(title: onboardingTitle3, subtitle: onboardingSubtitle3, image: AppImages.onboarding3),
    OnboardingSlide(title: onboardingTitle4, subtitle: onboardingSubtitle4, image: AppImages.onboarding4),
  ];

  static const Map<String, String> values = {
    'next': next,
    'getStarted': getStarted,
    'continueLabel': continueLabel,
    'save': save,
    'cancel': cancel,
    'ok': ok,
    'close': close,
    'delete': delete,
    'send': send,
    'searchLanguage': searchLanguage,
    'selectLanguage': selectLanguage,
    'selectLanguageSubtitle': selectLanguageSubtitle,
    'businessNameTitle': businessNameTitle,
    'businessNameHint': businessNameHint,
    'businessNameHelp': businessNameHelp,
    'defaultBusinessName': defaultBusinessName,
    'invoices': invoices,
    'unpaid': unpaid,
    'paid': paid,
    'overdue': overdue,
    'scanWithOcr': scanWithOcr,
    'scanWithOcrSubtitle': scanWithOcrSubtitle,
    'ocrScanner': ocrScanner,
    'startByCreatingInvoice': startByCreatingInvoice,
    'createInvoice': createInvoice,
    'howCreateInvoice': howCreateInvoice,
    'customInvoice': customInvoice,
    'customInvoiceSubtitle': customInvoiceSubtitle,
    'scanOcrOptionSubtitle': scanOcrOptionSubtitle,
    'createWithAi': createWithAi,
    'createWithAiSubtitle': createWithAiSubtitle,
    'newInvoice': newInvoice,
    'client': client,
    'items': items,
    'total': total,
    'addClient': addClient,
    'addItems': addItems,
    'addNewClient': addNewClient,
    'selectClient': selectClient,
    'fromSavedItems': fromSavedItems,
    'newItem': newItem,
    'addClientAndItemFirst': addClientAndItemFirst,
    'startByAddingClient': startByAddingClient,
    'saveInvoice': saveInvoice,
    'editClient': editClient,
    'clientFormHelp': clientFormHelp,
    'name': name,
    'clientNameHint': clientNameHint,
    'enterName': enterName,
    'phoneNumber': phoneNumber,
    'phoneHint': phoneHint,
    'email': email,
    'emailHint': emailHint,
    'enterValidEmail': enterValidEmail,
    'address': address,
    'addressHint': addressHint,
    'editItem': editItem,
    'itemName': itemName,
    'itemNameHint': itemNameHint,
    'enterItemName': enterItemName,
    'notesOptional': notesOptional,
    'notesHint': notesHint,
    'quantity': quantity,
    'enterQuantity': enterQuantity,
    'price': price,
    'enterPrice': enterPrice,
    'enterValidPrice': enterValidPrice,
    'aiIntro': aiIntro,
    'clientNameOptional': clientNameOptional,
    'clientNameHintAi': clientNameHintAi,
    'writeInvoiceDetail': writeInvoiceDetail,
    'invoiceThisMonthHint': invoiceThisMonthHint,
    'generating': generating,
    'generateInvoice': generateInvoice,
    'aiFillHint': aiFillHint,
    'newClientFallback': newClientFallback,
    'serviceThisMonth': serviceThisMonth,
    'ocrMobileOnly': ocrMobileOnly,
    'scanInvoice': scanInvoice,
    'scanInvoiceHelp': scanInvoiceHelp,
    'openCamera': openCamera,
    'chooseGallery': chooseGallery,
    'noTextFound': noTextFound,
    'couldNotScan': couldNotScan,
    'reviewScan': reviewScan,
    'clientName': clientName,
    'showScannedText': showScannedText,
    'hideScannedText': hideScannedText,
    'scannedItem': scannedItem,
    'scannedClient': scannedClient,
    'noExtraText': noExtraText,
    'invoiceNumber': invoiceNumber,
    'issueDate': issueDate,
    'dueDate': dueDate,
    'taxId': taxId,
    'taxIdHint': taxIdHint,
    'tax': tax,
    'taxRate': taxRate,
    'subtotal': subtotal,
    'grandTotal': grandTotal,
    'paymentTerms': paymentTerms,
    'paymentTermsHint': paymentTermsHint,
    'poNumber': poNumber,
    'billFrom': billFrom,
    'billTo': billTo,
    'description': description,
    'unitPrice': unitPrice,
    'lineTotal': lineTotal,
    'invoiceTemplate': invoiceTemplate,
    'templateClassic': templateClassic,
    'templateClassicDesc': templateClassicDesc,
    'templateModern': templateModern,
    'templateModernDesc': templateModernDesc,
    'templateMinimal': templateMinimal,
    'templateMinimalDesc': templateMinimalDesc,
    'templateAurora': templateAurora,
    'templateAuroraDesc': templateAuroraDesc,
    'templateSunset': templateSunset,
    'templateSunsetDesc': templateSunsetDesc,
    'templateOcean': templateOcean,
    'templateOceanDesc': templateOceanDesc,
    'templateEmerald': templateEmerald,
    'templateEmeraldDesc': templateEmeraldDesc,
    'templateRoyal': templateRoyal,
    'templateRoyalDesc': templateRoyalDesc,
    'templateRose': templateRose,
    'templateRoseDesc': templateRoseDesc,
    'templateMidnight': templateMidnight,
    'templateMidnightDesc': templateMidnightDesc,
    'templateRedModern': templateRedModern,
    'templateRedModernDesc': templateRedModernDesc,
    'templateBlueYellow': templateBlueYellow,
    'templateBlueYellowDesc': templateBlueYellowDesc,
    'templateBlueCorporate': templateBlueCorporate,
    'templateBlueCorporateDesc': templateBlueCorporateDesc,
    'templateOrangeReceipt': templateOrangeReceipt,
    'templateOrangeReceiptDesc': templateOrangeReceiptDesc,
    'paymentReceiptTitle': paymentReceiptTitle,
    'customerNameLabel': customerNameLabel,
    'paymentStatusLabel': paymentStatusLabel,
    'totalPaymentLabel': totalPaymentLabel,
    'receiptDefaultNotes': receiptDefaultNotes,
    'notesBoxTitle': notesBoxTitle,
    'paymentInformation': paymentInformation,
    'thankYou': thankYou,
    'termsAndConditionsLabel': termsAndConditionsLabel,
    'clientDetailLabel': clientDetailLabel,
    'itemUnitLabel': itemUnitLabel,
    'defaultPaymentTermsHint': defaultPaymentTermsHint,
    'currency': currency,
    'freeTemplatesHint': freeTemplatesHint,
    'browseAllTemplates': browseAllTemplates,
    'chooseTemplate': chooseTemplate,
    'templatesSheetSubtitle': templatesSheetSubtitle,
    'previewAnyTemplateHint': previewAnyTemplateHint,
    'useThisTemplate': useThisTemplate,
    'previewTemplate': previewTemplate,
    'proTemplateRequired': proTemplateRequired,
    'proTemplateRequiredBody': proTemplateRequiredBody,
    'preview': preview,
    'printPdf': printPdf,
    'sharePdf': sharePdf,
    'premiumTemplates': premiumTemplates,
    'premiumTemplatesHint': premiumTemplatesHint,
    'profile': profile,
    'accountNotSignedIn': accountNotSignedIn,
    'signIn': signIn,
    'settingsBusinessNameLabel': settingsBusinessNameLabel,
    'googleAccountPhotoHint': googleAccountPhotoHint,
    'companyLogoComingSoon': companyLogoComingSoon,
    'editProfileDetails': editProfileDetails,
    'previewInvoice': previewInvoice,
    'editInvoiceForPdf': editInvoiceForPdf,
    'invoiceCreatedBanner': invoiceCreatedBanner,
    'invoiceCreatedTitle': invoiceCreatedTitle,
    'invoiceCreatedSnackbar': invoiceCreatedSnackbar,
    'continueToInvoice': continueToInvoice,
    'backToInvoices': backToInvoices,
    'creatingInvoice': creatingInvoice,
    'saveChanges': saveChanges,
    'viewInvoice': viewInvoice,
    'invoice': invoice,
    'invoiceDeleted': invoiceDeleted,
    'deleteInvoice': deleteInvoice,
    'cannotBeUndone': cannotBeUndone,
    'markAsPaid': markAsPaid,
    'markAsUnpaid': markAsUnpaid,
    'date': date,
    'status': status,
    'invoiceShare': invoiceShare,
    'clientShare': clientShare,
    'totalShare': totalShare,
    'statusShare': statusShare,
    'settings': settings,
    'manageBusiness': manageBusiness,
    'clients': clients,
    'catalogItems': catalogItems,
    'darkMode': darkMode,
    'language': language,
    'rateUs': rateUs,
    'rateUsTitle': rateUsTitle,
    'rateUsBody': rateUsBody,
    'feedback': feedback,
    'feedbackHint': feedbackHint,
    'thanksFeedback': thanksFeedback,
    'privacyPolicy': privacyPolicy,
    'privacyBody': privacyBody,
    'restorePurchases': restorePurchases,
    'proAlreadyActive': proAlreadyActive,
    'noPurchaseFound': noPurchaseFound,
    'shareApp': shareApp,
    'shareAppText': shareAppText,
    'communityGuidelines': communityGuidelines,
    'communityBody': communityBody,
    'goUnlimited': goUnlimited,
    'goUnlimitedBody': goUnlimitedBody,
    'unlock': unlock,
    'proUnlocked': proUnlocked,
    'getProAccess': getProAccess,
    'professionalTemplates': professionalTemplates,
    'unlimitedInvoices': unlimitedInvoices,
    'customizeTemplate': customizeTemplate,
    'vipSupport': vipSupport,
    'removeAds': removeAds,
    'trialEnabled': trialEnabled,
    'threeDayTrial': threeDayTrial,
    'thenWeekly': thenWeekly,
    'trialDisabled': trialDisabled,
    'free': free,
    'yearly': yearly,
    'perYear': perYear,
    'continueForFree': continueForFree,
    'subscribeNow': subscribeNow,
    'subscriptionStoreUnavailable': subscriptionStoreUnavailable,
    'subscriptionProductsLoading': subscriptionProductsLoading,
    'purchaseInProgress': purchaseInProgress,
    'restoreCompletePro': restoreCompletePro,
    'restoreCompleteNone': restoreCompleteNone,
    'restoreFailed': restoreFailed,
    'googleAccount': googleAccount,
    'googleAccountHint': googleAccountHint,
    'signInWithGoogle': signInWithGoogle,
    'signOut': signOut,
    'googleUser': googleUser,
    'signInToSyncSubscription': signInToSyncSubscription,
    'googleLoginTitle': googleLoginTitle,
    'googleLoginSubtitle': googleLoginSubtitle,
    'skipGoogleLogin': skipGoogleLogin,
    'googleSignInSuccess': googleSignInSuccess,
    'subscriptionPlansTitle': subscriptionPlansTitle,
    'chooseBillingPeriod': chooseBillingPeriod,
    'billingMonthly': billingMonthly,
    'billingYearly': billingYearly,
    'yearlySaveHint': yearlySaveHint,
    'tierFreeName': tierFreeName,
    'tierPremiumName': tierPremiumName,
    'tierProName': tierProName,
    'tierFreePrice': tierFreePrice,
    'recommendedPlan': recommendedPlan,
    'activePlanBadge': activePlanBadge,
    'currentPlanFree': currentPlanFree,
    'planActivated': planActivated,
    'viewPlans': viewPlans,
    'pricingDisclaimer': pricingDisclaimer,
    'playStoreManageHint': playStoreManageHint,
    'unlimitedInvoicesToday': unlimitedInvoicesToday,
    'dailyInvoiceLimitTitle': dailyInvoiceLimitTitle,
    'dailyInvoiceLimitBody': dailyInvoiceLimitBody,
    'invoicesRemainingToday': invoicesRemainingToday,
    'currentPlanLabel': currentPlanLabel,
    'pricePerMonthTemplate': pricePerMonthTemplate,
    'pricePerYearTemplate': pricePerYearTemplate,
    'subscribeToTemplate': subscribeToTemplate,
    'suggestedPremiumMonthly': suggestedPremiumMonthly,
    'suggestedPremiumYearly': suggestedPremiumYearly,
    'suggestedProMonthly': suggestedProMonthly,
    'suggestedProYearly': suggestedProYearly,
    'tierFreeFeature1': tierFreeFeature1,
    'tierFreeFeature2': tierFreeFeature2,
    'tierFreeFeature3': tierFreeFeature3,
    'tierPremiumFeature1': tierPremiumFeature1,
    'tierPremiumFeature2': tierPremiumFeature2,
    'tierPremiumFeature3': tierPremiumFeature3,
    'tierPremiumFeature4': tierPremiumFeature4,
    'tierProFeature1': tierProFeature1,
    'tierProFeature2': tierProFeature2,
    'tierProFeature3': tierProFeature3,
    'tierProFeature4': tierProFeature4,
    'tierProFeature5': tierProFeature5,
    'aiPaidRequiredTitle': aiPaidRequiredTitle,
    'aiPaidRequiredBody': aiPaidRequiredBody,
    'aiPremiumPlanBadge': aiPremiumPlanBadge,
    'aiTokensRemainingHint': aiTokensRemainingHint,
    'aiInputTooLongTitle': aiInputTooLongTitle,
    'aiInputTooLongBody': aiInputTooLongBody,
    'aiMonthlyLimitTitle': aiMonthlyLimitTitle,
    'aiMonthlyLimitBody': aiMonthlyLimitBody,
    'premiumTemplateRequired': premiumTemplateRequired,
    'premiumTemplateRequiredBody': premiumTemplateRequiredBody,
    'customizeProOnly': customizeProOnly,
    'homeQuotaBanner': homeQuotaBanner,
    'premiumUpsellTitle': premiumUpsellTitle,
    'premiumUpsellSubtitle': premiumUpsellSubtitle,
    'premiumUpsellFeature1': premiumUpsellFeature1,
    'premiumUpsellFeature2': premiumUpsellFeature2,
    'premiumUpsellFeature3': premiumUpsellFeature3,
    'premiumUpsellPriceHint': premiumUpsellPriceHint,
    'premiumUpsellCta': premiumUpsellCta,
    'premiumUpsellDismiss': premiumUpsellDismiss,
    'trialDisclaimer': trialDisclaimer,
    'noClientsYet': noClientsYet,
    'noItemsYet': noItemsYet,
    'businessEmail': businessEmail,
    'businessPhone': businessPhone,
    'businessAddress': businessAddress,
    'switchToLight': switchToLight,
    'switchToDark': switchToDark,
    'adLabel': adLabel,
    'loadingAd': loadingAd,
    'growBusiness': growBusiness,
    'sponsored': sponsored,
    'open': open,
    'onboardingTitle1': onboardingTitle1,
    'onboardingSubtitle1': onboardingSubtitle1,
    'onboardingTitle2': onboardingTitle2,
    'onboardingSubtitle2': onboardingSubtitle2,
    'onboardingTitle3': onboardingTitle3,
    'onboardingSubtitle3': onboardingSubtitle3,
    'onboardingTitle4': onboardingTitle4,
    'onboardingSubtitle4': onboardingSubtitle4,
  };
}
