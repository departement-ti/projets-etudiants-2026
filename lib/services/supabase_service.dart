import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase client and initialization.
class SupabaseService {
  SupabaseService._();
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  bool get isAuthenticated => auth.currentUser != null;
  User? get currentUser => auth.currentUser;
  String? get currentUserId => currentUser?.id;
}
