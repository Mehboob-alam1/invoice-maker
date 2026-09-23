import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/google_auth_config.dart';
import '../models/subscription_tier.dart';
import '../providers/invoice_provider.dart';
import 'subscription_service.dart';
import 'user_firestore_service.dart';
import 'user_profile_sync.dart';

class AuthService extends ChangeNotifier {
  AuthService({
    required InvoiceProvider invoiceProvider,
    required SubscriptionService subscriptionService,
  })  : _invoiceProvider = invoiceProvider,
        _subscriptionService = subscriptionService;

  final InvoiceProvider _invoiceProvider;
  final SubscriptionService _subscriptionService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: GoogleAuthConfig.serverClientId,
  );

  StreamSubscription<User?>? _authSub;
  bool signingIn = false;
  String? lastError;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<void> initialize() async {
    _authSub ??= _auth.authStateChanges().listen(_onAuthUserChanged);
  }

  Future<void> disposeService() async {
    await _authSub?.cancel();
    _authSub = null;
  }

  Future<void> _onAuthUserChanged(User? user) async {
    notifyListeners();
    if (user == null) return;

    await UserFirestoreService.instance.upsertGoogleAccount(user);
    final account = await UserFirestoreService.instance.fetchAccount(user.uid);
    if (account != null) {
      final b = account.business;
      if (b.hasAnyField) {
        _invoiceProvider.importFromCloudAccount(
          name: b.name,
          email: b.email,
          phone: b.phone,
          address: b.address,
          taxId: b.taxId,
          languageCode: account.languageCode,
        );
      }
      final remoteTier = account.subscription.tier;
      if (remoteTier.index > _invoiceProvider.subscriptionTier.index) {
        _invoiceProvider.setSubscriptionTier(remoteTier);
      }
    }
    await UserProfileSync.pushFromProvider(_invoiceProvider);
    if (_invoiceProvider.subscriptionTier != SubscriptionTier.free) {
      await _subscriptionService.syncTierToFirestoreIfNeeded();
    }
    await _subscriptionService.restorePurchases(silent: true);
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    signingIn = true;
    lastError = null;
    notifyListeners();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        signingIn = false;
        notifyListeners();
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      signingIn = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = e.message ?? e.code;
      signingIn = false;
      notifyListeners();
      return false;
    } catch (e) {
      lastError = e.toString();
      signingIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
  }
}
