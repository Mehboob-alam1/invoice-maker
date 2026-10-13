import 'package:firebase_auth/firebase_auth.dart';

import '../providers/invoice_provider.dart';
import 'user_database_service.dart';

/// Pushes local profile / preferences / usage to Supabase when the user is signed in.
class UserProfileSync {
  UserProfileSync._();

  static Future<void> pushFromProvider(InvoiceProvider provider) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await UserDatabaseService.instance.syncBusinessProfile(
      uid: uid,
      name: provider.businessName,
      email: provider.businessEmail,
      phone: provider.businessPhone,
      address: provider.businessAddress,
      taxId: provider.businessTaxId,
    );
    await UserDatabaseService.instance.syncPreferences(
      uid: uid,
      languageCode: provider.languageCode,
    );
    await UserDatabaseService.instance.recordDailyInvoiceUsage(
      uid: uid,
      dayKey: provider.invoiceQuotaDayKeyForSync,
      count: provider.invoicesCreatedToday,
      limit: provider.dailyInvoiceLimit,
    );
  }
}
