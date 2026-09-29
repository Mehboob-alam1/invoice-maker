import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: GoogleAuthConfig.webClientId,
    clientId: Platform.isIOS ? GoogleAuthConfig.iosClientId : null,
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
    }
    await _subscriptionService.refreshEntitlementsFromStore(silent: true);
    if (_invoiceProvider.subscriptionTier == SubscriptionTier.free && account != null) {
      final remoteTier = account.subscription.tier;
      if (remoteTier != SubscriptionTier.free && !_subscriptionService.storeAvailable) {
        _invoiceProvider.setSubscriptionTier(remoteTier);
      }
    }
    await UserProfileSync.pushFromProvider(_invoiceProvider);
    if (_invoiceProvider.subscriptionTier != SubscriptionTier.free) {
      await _subscriptionService.syncTierToFirestoreIfNeeded();
    }
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
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        lastError =
            'Google did not return a sign-in token. Check Firebase Web client ID and SHA-1 in Firebase Console.';
        signingIn = false;
        notifyListeners();
        return false;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: idToken,
      );
      await _auth.signInWithCredential(credential);
      signingIn = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = e.message ?? e.code;
      debugPrint('AuthService FirebaseAuthException: ${e.code} ${e.message}');
      signingIn = false;
      notifyListeners();
      return false;
    } on PlatformException catch (e) {
      lastError = _googleSignInErrorMessage(e);
      debugPrint('AuthService PlatformException: ${e.code} ${e.message} ${e.details}');
      signingIn = false;
      notifyListeners();
      return false;
    } catch (e, st) {
      lastError = e.toString();
      debugPrint('AuthService signInWithGoogle: $e\n$st');
      signingIn = false;
      notifyListeners();
      return false;
    }
  }

  static String _googleSignInErrorMessage(PlatformException e) {
    final code = e.code;
    final message = '${e.message ?? ''} ${e.details ?? ''}';
    if (message.contains('10') ||
        message.toLowerCase().contains('developer_error') ||
        code == 'sign_in_failed') {
      return 'Google Sign-In failed (app not registered). In Firebase Console, open Project '
          'settings → your Android app → add SHA-1 for your debug/release keystore, enable '
          'Google sign-in in Authentication, then download a fresh google-services.json.';
    }
    if (code == 'network_error') {
      return 'Network error during Google Sign-In. Check your connection and try again.';
    }
    return e.message ?? 'Google Sign-In failed ($code).';
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
  }
}
