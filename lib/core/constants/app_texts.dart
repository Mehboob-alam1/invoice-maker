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
  static const professionalTemplates = 'Professional Templates';
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
    'trialDisclaimer': trialDisclaimer,
    'noClientsYet': noClientsYet,
    'noItemsYet': noItemsYet,
    'businessEmail': businessEmail,
    'businessPhone': businessPhone,
    'businessAddress': businessAddress,
    'switchToLight': switchToLight,
    'switchToDark': switchToDark,
    'adLabel': adLabel,
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
