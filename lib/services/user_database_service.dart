import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../core/constants/supabase_config.dart';
import '../models/subscription_tier.dart';
import '../models/user_account.dart';

/// Supabase tables for profile, subscription, feedback, and referrals.
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

  /// Removes the profile. Related rows cascade, including the backup snapshot.
  Future<void> deleteAllUserData(String uid) async {
    if (!_ready) return;
    try {
      await _db.from('app_feedback').delete().eq('uid', uid);
    } catch (e) {
      debugPrint('UserDatabaseService.deleteFeedback: $e');
    }
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

  bool get isReady => _ready;

  Future<void> saveBackup({
    required String uid,
    required String? email,
    required Map<String, dynamic> payload,
  }) async {
    if (!_ready) {
      throw StateError('Backup database is not ready.');
    }
    await _db.from('users').upsert(
      {
        'id': uid,
        if (email != null && email.isNotEmpty) 'email': email,
        'auth_provider': 'google',
        'last_sign_in_at': _now(),
      },
      onConflict: 'id',
    );
    await _db.from('user_backups').upsert(
      {
        'user_id': uid,
        'payload': payload,
        'updated_at': _now(),
      },
      onConflict: 'user_id',
    );
  }

  Future<Map<String, dynamic>?> fetchBackup(String uid) async {
    if (!_ready) {
      throw StateError('Backup database is not ready.');
    }
    final row = await _db.from('user_backups').select('payload').eq('user_id', uid).maybeSingle();
    final payload = row?['payload'];
    if (payload is Map) return Map<String, dynamic>.from(payload);
    if (payload is String && payload.isNotEmpty) {
      final decoded = jsonDecode(payload);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  Future<Map<String, dynamic>?> ensureReferralProfile({
    required String installationId,
    required String fcmToken,
  }) {
    return _referralRpc('ensure_referral_profile', {
      'p_installation_id': installationId,
      'p_fcm_token': fcmToken,
    });
  }

  Future<Map<String, dynamic>?> applyReferralCode({
    required String code,
    required String installationId,
  }) {
    return _referralRpc('apply_referral_code', {
      'p_code': code,
      'p_installation_id': installationId,
    });
  }

  Future<Map<String, dynamic>?> qualifyReferral() {
    return _referralRpc('qualify_referral', {});
  }

  Future<Map<String, dynamic>?> spendReferralCredits(int amount) {
    return _referralRpc('spend_ai_credits', {'p_amount': amount});
  }

  Future<Map<String, dynamic>?> spendReferralTemplateToken(String templateId) {
    return _referralRpc('spend_template_token', {'p_template_id': templateId});
  }

  Future<Map<String, dynamic>?> _referralRpc(String name, Map<String, dynamic> params) async {
    if (!_ready) return null;
    final raw = await _db.rpc(name, params: params);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}
