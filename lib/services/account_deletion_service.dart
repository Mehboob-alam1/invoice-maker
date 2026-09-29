import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/google_auth_config.dart';
import '../providers/invoice_provider.dart';
import 'user_firestore_service.dart';

/// Deletes Firebase Auth user, Firestore profile, and local app data.
class AccountDeletionService {
  AccountDeletionService._();
  static final AccountDeletionService instance = AccountDeletionService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: GoogleAuthConfig.webClientId,
  );

  /// In-app deletion when signed in with Google.
  Future<AccountDeletionResult> deleteSignedInAccount({
    required InvoiceProvider invoiceProvider,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return AccountDeletionResult.failure(
        'Sign in with Google first, or use the account deletion web form.',
      );
    }

    final uid = user.uid;
    try {
      await UserFirestoreService.instance.deleteAllUserData(uid);
    } catch (e) {
      debugPrint('AccountDeletionService Firestore: $e');
      return AccountDeletionResult.failure(
        'Could not remove cloud data. Check your connection and try again.',
      );
    }

    try {
      await _deleteAuthUser(user);
    } on FirebaseAuthException catch (e) {
      debugPrint('AccountDeletionService auth: ${e.code} ${e.message}');
      if (e.code == 'requires-recent-login') {
        return AccountDeletionResult.failure(
          'For security, sign in with Google again, then retry Delete account.',
        );
      }
      return AccountDeletionResult.failure(e.message ?? e.code);
    } catch (e) {
      debugPrint('AccountDeletionService: $e');
      return AccountDeletionResult.failure(e.toString());
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await invoiceProvider.wipeAllLocalDataAfterAccountDeletion();
    return AccountDeletionResult.success(uid);
  }

  Future<void> _deleteAuthUser(User user) async {
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      await _reauthenticateAndDelete(user);
    }
  }

  Future<void> _reauthenticateAndDelete(User user) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Google sign-in was cancelled.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Could not verify Google account.',
      );
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: idToken,
    );
    await user.reauthenticateWithCredential(credential);
    await user.delete();
  }
}

class AccountDeletionResult {
  const AccountDeletionResult._({required this.ok, this.uid, this.error});

  factory AccountDeletionResult.success(String uid) =>
      AccountDeletionResult._(ok: true, uid: uid);

  factory AccountDeletionResult.failure(String error) =>
      AccountDeletionResult._(ok: false, error: error);

  final bool ok;
  final String? uid;
  final String? error;
}
