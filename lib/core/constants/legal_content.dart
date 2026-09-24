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
      'Overview',
      'Invoice GO (Appomatrix) helps you create invoices, scan receipts, and export PDFs. '
          'This policy explains what we collect, why, and your choices.',
    ),
    LegalSection(
      'Data on your device',
      'Invoices, clients, catalog items, and OCR scans are stored locally on your phone unless you sign in '
          'and choose to sync profile fields to the cloud.',
    ),
    LegalSection(
      'Account & cloud sync',
      'If you sign in with Google, we store your account identifier, email, display name, business profile, '
          'language preference, subscription tier, and usage counters in Firebase (Firestore) to restore your '
          'experience across devices.',
    ),
    LegalSection(
      'Camera, gallery & OCR',
      'Camera and photo library access is used only when you scan or attach a document. Images are processed '
          'on-device for text recognition unless you explicitly share an export.',
    ),
    LegalSection(
      'Payments',
      'Subscriptions are billed by Google Play. We do not store your card number. Purchase tokens are validated '
          'through Google Play Billing; tier status may be mirrored in Firestore when you are signed in.',
    ),
    LegalSection(
      'Advertising & analytics',
      'Free plans may show Google AdMob ads. Ad partners may use device identifiers per their policies. '
          'Firebase Cloud Messaging may send optional service messages if you allow notifications.',
    ),
    LegalSection(
      'AI features',
      'Premium and Pro plans may send invoice text you enter to our AI provider to generate drafts. '
          'Do not submit secrets or unlawful content.',
    ),
    LegalSection(
      'Your rights',
      'You can delete local data by uninstalling the app. Signed-in users may request account deletion by '
          'contacting support. You may opt out of notifications in system settings.',
    ),
    LegalSection(
      'Contact',
      'Questions: support@appomatrix.com',
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
