/// Supabase project used for the app database (profile, subscription, usage, feedback).
///
/// Firebase Auth, Cloud Messaging, and Remote Config stay on Firebase.
/// In the Supabase dashboard, enable Authentication → Third-party → Firebase
/// and set the Firebase project ID to `aiinvoicemaker-3a0af`, then run
/// `supabase/schema.sql`.
///
/// Paste the project URL and anon key below, or pass them at build time:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _url,
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _anonKey,
  );

  static const String _url = '';
  static const String _anonKey = '';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
