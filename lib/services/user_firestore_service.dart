import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/subscription_tier.dart';
import '../models/user_account.dart';

/// Firestore: `users/{uid}` profile + nested `subscription` + event log subcollection.
class UserFirestoreService {
  UserFirestoreService._();
  static final UserFirestoreService instance = UserFirestoreService._();

  static const _users = 'users';
  static const _subscriptionEvents = 'subscription_events';

  Future<void> upsertGoogleAccount(User user) async {
    final ref = FirebaseFirestore.instance.collection(_users).doc(user.uid);
    await ref.set(
      {
        'email': user.email,
        'displayName': user.displayName,
        'googlePhotoUrl': user.photoURL,
        'photoUrl': user.photoURL,
        'authProvider': 'google',
        'lastSignInAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<UserAccountSnapshot?> fetchAccount(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection(_users).doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserAccountSnapshot.fromFirestore(uid, doc.data()!);
    } catch (e) {
      debugPrint('UserFirestoreService.fetchAccount: $e');
      return null;
    }
  }

  Future<void> recordSubscription({
    required String uid,
    required SubscriptionTier tier,
    required String productId,
    String? purchaseId,
  }) async {
    final ref = FirebaseFirestore.instance.collection(_users).doc(uid);
    final isPro = tier == SubscriptionTier.pro;
    final payload = {
      'subscriptionTier': tier.storageKey,
      'isPro': isPro,
      'subscription': {
        'tier': tier.storageKey,
        'isPro': isPro,
        'productId': productId,
        'platform': 'google_play',
        'purchaseId': purchaseId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    };
    await ref.set(payload, SetOptions(merge: true));
    await ref.collection(_subscriptionEvents).add({
      'tier': tier.storageKey,
      'isPro': isPro,
      'productId': productId,
      'platform': 'google_play',
      'purchaseId': purchaseId,
      'createdAt': FieldValue.serverTimestamp(),
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
    final ref = FirebaseFirestore.instance.collection(_users).doc(uid);
    await ref.set(
      {
        'business': {
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'taxId': taxId,
          'logoUrl': null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
  }

  Future<void> syncPreferences({
    required String uid,
    required String languageCode,
  }) async {
    final ref = FirebaseFirestore.instance.collection(_users).doc(uid);
    await ref.set(
      {
        'preferences': {
          'languageCode': languageCode,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveFcmToken({required String uid, required String token}) async {
    final ref = FirebaseFirestore.instance.collection(_users).doc(uid);
    await ref.set(
      {
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> recordDailyInvoiceUsage({
    required String uid,
    required String dayKey,
    required int count,
    required int limit,
  }) async {
    final ref = FirebaseFirestore.instance.collection(_users).doc(uid);
    await ref.set(
      {
        'usage': {
          'invoiceDayKey': dayKey,
          'invoicesCreatedToday': count,
          'dailyLimit': limit,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
  }
}
