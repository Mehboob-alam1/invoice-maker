/// English legal copy (other locales fall back via [AppTexts.values]).
class LegalSection {
  const LegalSection(this.title, this.body);
  final String title;
  final String body;
}

class LegalContent {
  LegalContent._();

  static const privacy = [
    LegalSection(
      '1. Introduction',
      'This Privacy Policy describes how Appomatrix ("we", "us", "our") processes personal '
          'information when you use the Invoice GO mobile application ("App"). '
          'We act as the data controller for processing described here, unless stated otherwise. '
          'By using the App, you acknowledge this Policy. If you do not agree, please do not use the App.',
    ),
    LegalSection(
      '2. Scope & children',
      'This Policy applies to the App on Android and iOS. The App is intended for business users '
          'and is not directed at children under 16 (or the minimum age required in your country). '
          'We do not knowingly collect personal data from children.',
    ),
    LegalSection(
      '3. Information we collect',
      '• Account data (optional): If you sign in with Google, we receive your Google account '
          'identifier, email address, and display name.\n'
          '• Business profile: Business name, address, contact details, and tax identifiers you enter.\n'
          '• Invoice data: Clients, line items, amounts, notes, templates, and PDF exports you create.\n'
          '• Device and app data: Language, theme, subscription tier, usage counters, and FCM push token '
          '(if you allow notifications).\n'
          '• Purchase data: Subscription product ID and purchase validation tokens from Google Play '
          '(we do not receive full payment card numbers).\n'
          '• Advertising data (Free tier): Google AdMob may collect device advertising identifiers '
          'and interaction data per Google\'s policies.\n'
          '• AI input (Premium/Pro): Text you submit for AI invoice generation is sent to our AI service '
          'provider to produce a draft.',
    ),
    LegalSection(
      '4. Device permissions (why we request them)',
      'Android:\n'
          '• Internet — Sync account data, AI features, ads, Remote Config, and Firebase services.\n'
          '• Access network state — Check connectivity before network requests.\n'
          '• Camera — Capture receipts/invoices for on-device OCR scanning.\n'
          '• Post notifications — Optional service messages via Firebase Cloud Messaging.\n'
          '• Photos/media (gallery picker) — Used only when you choose an image for OCR; not accessed in the background.\n'
          '• Google Play Billing — Process Premium/Pro subscriptions (handled by Google Play).\n\n'
          'iOS:\n'
          '• Camera — Document scanning for OCR.\n'
          '• Photo Library (read) — Pick images for OCR when you choose from the library.\n'
          '• Photo Library (add) — Save a captured scan if you use that option.\n'
          '• Notifications — Optional; requested only if push is enabled in the App.',
    ),
    LegalSection(
      '5. How we use information',
      'We use data to: provide invoicing, OCR, PDF export, and AI features; maintain your subscription '
          'tier; restore your profile when signed in; show ads on the Free plan; send optional push '
          'notifications; prevent abuse; and improve reliability and security.',
    ),
    LegalSection(
      '6. Legal bases (EEA/UK users)',
      'Where GDPR applies, we rely on: Contract (providing the App and subscriptions); '
          'Legitimate interests (security, fraud prevention, product improvement); Consent '
          '(notifications, optional sign-in, ads where required); and Legal obligation where applicable.',
    ),
    LegalSection(
      '7. Storage & retention',
      'Invoice and client data are stored locally on your device by default. If you sign in, selected '
          'profile and subscription fields may be stored in Google Firebase (Firestore) in regions '
          'used by Google. We retain cloud data while your account is active and for a reasonable period '
          'after deletion requests. Local data is removed when you uninstall the App.',
    ),
    LegalSection(
      '8. Sharing & processors',
      'We share data only with service providers that help operate the App, including:\n'
          '• Google — Sign-In, Firebase (Auth, Firestore, Cloud Messaging, Remote Config), AdMob, Play Billing.\n'
          '• AI provider — Invoice text you submit for AI generation (Premium/Pro).\n'
          'We do not sell your personal information. Ad partners may use data for personalized ads per '
          'their policies and your device settings.',
    ),
    LegalSection(
      '9. International transfers',
      'If you are outside the country where our processors host data, your information may be transferred '
          'internationally. Google and other providers use appropriate safeguards (such as Standard '
          'Contractual Clauses) where required by law.',
    ),
    LegalSection(
      '10. Your rights',
      'Depending on your location, you may have rights to access, rectify, erase, restrict, '
          'object, portability, and withdraw consent. California residents may have additional '
          'rights under the CCPA/CPRA.\n\n'
          'Account deletion: Open Settings → Delete account in the App (when signed in with Google), '
          'or submit a request at https://invoice-go-deletion.netlify.app/account-deletion.html. '
          'Email appo.matrix01@gmail.com if you need help. You may also complain to your local data '
          'protection authority. You can disable notifications in system settings and limit ad tracking '
          'in device settings.',
    ),
    LegalSection(
      '11. Security',
      'We use industry-standard measures appropriate to the data we process. No method of transmission or '
          'storage is 100% secure; please protect your device and Google account credentials.',
    ),
    LegalSection(
      '12. Changes & contact',
      'We may update this Policy; the "Last updated" date in the App will change. Material changes may '
          'be communicated in-app where required.\n\n'
          'Contact: support@appomatrix.com\n'
          'App: Invoice GO — Appomatrix',
    ),
  ];

  static const community = [
    LegalSection(
      'Purpose',
      'Our community is built around honest business invoicing. Use the app to bill your own customers and '
          'keep accurate records.',
    ),
    LegalSection(
      'Respect & permission',
      'Do not scan, upload, or store another person’s documents without their consent. Do not impersonate '
          'businesses or clients.',
    ),
    LegalSection(
      'Lawful use',
      'Invoices must reflect real goods or services. Do not use the app for fraud, harassment, or illegal tax evasion.',
    ),
    LegalSection(
      'Content standards',
      'Feedback and support messages must be free of hate speech, threats, or spam. We may restrict access for abuse.',
    ),
    LegalSection(
      'Subscriptions',
      'Paid plans follow Google Play refund and cancellation rules. Sharing accounts to bypass limits is not allowed.',
    ),
    LegalSection(
      'Reporting',
      'To report misuse, email support@appomatrix.com with details. We may update these guidelines as the product evolves.',
    ),
  ];
}
