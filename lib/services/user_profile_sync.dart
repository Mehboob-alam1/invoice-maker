import 'package:firebase_auth/firebase_auth.dart';

import '../providers/invoice_provider.dart';
import 'user_firestore_service.dart';

/// Pushes local profile / preferences / usage to Firestore when the user is signed in.
class UserProfileSync {
  UserProfileSync._();

  static Future<void> pushFromProvider(InvoiceProvider provider) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await UserFirestoreService.instance.syncBusinessProfile(
      uid: uid,
      name: provider.businessName,
      email: provider.businessEmail,
      phone: provider.businessPhone,
      address: provider.businessAddress,
      taxId: provider.businessTaxId,
    );
    await UserFirestoreService.instance.syncPreferences(
      uid: uid,
      languageCode: provider.languageCode,
    );
    await UserFirestoreService.instance.recordDailyInvoiceUsage(
      uid: uid,
      dayKey: provider.invoiceQuotaDayKeyForSync,
      count: provider.invoicesCreatedToday,
      limit: provider.dailyInvoiceLimit,
    );
  }
}
