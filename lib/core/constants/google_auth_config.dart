/// Firebase Console → Project settings → Your apps → **Web client** OAuth 2.0 client ID.
/// Required on Android for Google Sign-In + Firebase Auth (id token).
/// After adding, paste the Web client ID here (ends with `.apps.googleusercontent.com`).
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String? serverClientId = null;
}
