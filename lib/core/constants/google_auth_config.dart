/// Google Sign-In + Firebase Auth OAuth client IDs (Firebase project `aiinvoicemaker-3a0af`).
///
/// **Android:** [webClientId] must be the **Web client** from Firebase Console (also in
/// `google-services.json` → `oauth_client` with `client_type: 3`). Without it you get
/// `PlatformException(sign_in_failed)`.
///
/// **Firebase Console:** Project settings → Your Android app → add **SHA-1** (debug +
/// release), then re-download `google-services.json`.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  /// Web client ID — pass as [GoogleSignIn.serverClientId] on Android (required for id token).
  static const String webClientId =
      '668634441558-45nkk47ik4of5g5rb8t9g33n4aq0e248.apps.googleusercontent.com';

  /// iOS client from `GoogleService-Info.plist` → `CLIENT_ID`.
  static const String iosClientId =
      '668634441558-6h68dgai9ggkatekj6m6cihe3lqhi6ed.apps.googleusercontent.com';
}
