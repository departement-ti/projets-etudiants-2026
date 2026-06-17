/// Application-wide constants for Smart Support AI.
class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Support AI';
  static const String supabaseUrlKey = 'SUPABASE_URL';
  static const String supabaseAnonKey = 'SUPABASE_ANON_KEY';

  // Storage keys
  static const String cachedFaqKey = 'cached_faq';
  static const String offlineMessagesKey = 'offline_messages';
  static const String lastSyncKey = 'last_sync';

  // Chat
  static const int maxFailuresBeforeHandoff = 2;
  static const int minPhraseMatchLength = 2;
}
