import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../core/constants/supabase_config.dart';
import '../models/subscription_tier.dart';
import '../models/user_account.dart';

/// Supabase tables `users`, `subscription_events`, and `app_feedback`.
///
/// Sign-in stays on Firebase Auth. Each request sends the Firebase ID token,
/// and row access is limited to that Firebase uid.
class UserDatabaseService {
  UserDatabaseService._();
  static final UserDatabaseService instance = UserDatabaseService._();

  static bool _ready = false;
  static bool _missingConfigLogged = false;

  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      if (!_missingConfigLogged) {
        _missingConfigLogged = true;
        debugPrint(
          'UserDatabaseService: set SupabaseConfig url and anonKey to enable the cloud database.',
        );
      }
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      accessToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        return user.getIdToken();
      },
    );
    _ready = true;
  }

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> upsertGoogleAccount(User user) async {
    if (!_ready) return;
    await _db.from('users').upsert(
      {
        'id': user.uid,
        'email': user.email,
        'display_name': user.displayName,
        'google_photo_url': user.photoURL,
        'photo_url': user.photoURL,
        'auth_provider': 'google',
        'last_sign_in_at': _now(),
      },
      onConflict: 'id',
    );
  }

  Future<UserAccountSnapshot?> fetchAccount(String uid) async {
    if (!_ready) return null;
    try {
      final row = await _db.from('users').select().eq('id', uid).maybeSingle();
      if (row == null) return null;
      return UserAccountSnapshot.fromDatabaseRow(row);
    } catch (e) {
      debugPrint('UserDatabaseService.fetchAccount: $e');
      return null;
    }
  }

  Future<void> recordSubscription({
    required String uid,
    required SubscriptionTier tier,
    required String productId,
    String? purchaseId,
  }) async {
    if (!_ready) return;
    final isPro = tier == SubscriptionTier.pro;
    await _db.from('users').upsert(
      {
        'id': uid,
        'subscription_tier': tier.storageKey,
        'is_pro': isPro,
        'subscription_product_id': productId,
        'subscription_platform': 'google_play',
        'subscription_purchase_id': purchaseId,
        'subscription_updated_at': _now(),
      },
      onConflict: 'id',
    );
    await _db.from('subscription_events').insert({
      'user_id': uid,
      'tier': tier.storageKey,
      'is_pro': isPro,
      'product_id': productId,
      'platform': 'google_play',
      'purchase_id': purchaseId,
    });
  }

  Future<void> syncLocalSubscription({
    required String uid,
    required SubscriptionTier tier,
    String? productId,
  }) async {
    await recordSubscription(
      uid: uid,
      tier: tier,
      productId: productId ?? tier.storageKey,
    );
  }

  Future<void> syncBusinessProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String taxId,
  }) async {
    if (!_ready) return;
    await _db.from('users').upsert(
      {
        'id': uid,
        'business_name': name,
        'business_email': email,
        'business_phone': phone,
        'business_address': address,
        'business_tax_id': taxId,
        'business_updated_at': _now(),
      },
      onConflict: 'id',
    );
  }

  Future<void> syncPreferences({
    required String uid,
    required String languageCode,
  }) async {
    if (!_ready) return;
    await _db.from('users').upsert(
      {
        'id': uid,
        'language_code': languageCode,
        'preferences_updated_at': _now(),
      },
      onConflict: 'id',
    );
  }

  /// Stores the FCM token so a server can target this user. Delivery stays on Firebase Cloud Messaging.
  Future<void> saveFcmToken({required String uid, required String token}) async {
    if (!_ready) return;
    await _db.from('users').upsert(
      {
        'id': uid,
        'fcm_token': token,
        'fcm_updated_at': _now(),
      },
      onConflict: 'id',
    );
  }

  Future<void> submitAppFeedback({
    required int stars,
    required String comment,
    required String? uid,
    required String packageId,
  }) async {
    if (!_ready) return;
    await _db.from('app_feedback').insert({
      'stars': stars,
      'comment': comment,
      'uid': uid,
      'platform': 'android',
      'package_id': packageId,
    });
  }

  /// Removes the user row. Subscription events cascade with it.
  Future<void> deleteAllUserData(String uid) async {
    if (!_ready) return;
    await _db.from('users').delete().eq('id', uid);
  }

  Future<void> recordDailyInvoiceUsage({
    required String uid,
    required String dayKey,
    required int count,
    required int limit,
  }) async {
    if (!_ready) return;
    await _db.from('users').upsert(
      {
        'id': uid,
        'invoice_day_key': dayKey,
        'invoices_created_today': count,
        'daily_limit': limit,
        'usage_updated_at': _now(),
      },
      onConflict: 'id',
    );
  }

  String _now() => DateTime.now().toUtc().toIso8601String();
}
