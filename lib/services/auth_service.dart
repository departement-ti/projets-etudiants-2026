import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/company.dart';
import 'supabase_service.dart';

class AuthService {
  final _supabase = SupabaseService.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return _supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<AppUser?> getAppUser(String uid) async {
    final res = await _supabase.from('users').select().eq('id', uid).maybeSingle();
    if (res == null) return null;
    return AppUser.fromJson(res as Map<String, dynamic>);
  }

  Future<Company?> getCompany(String companyId) async {
    final res = await _supabase.from('companies').select().eq('id', companyId).maybeSingle();
    if (res == null) return null;
    return Company.fromJson(res as Map<String, dynamic>);
  }

  Future<Company> createCompany({
    required String name,
    String? logoUrl,
    String? primaryColor,
    String? welcomeMessage,
  }) async {
    final insert = await _supabase.from('companies').insert({
      'name': name,
      'logo_url': logoUrl,
      'primary_color': primaryColor ?? '#6366F1',
      'welcome_message': welcomeMessage ?? 'Hello! How can I help you today?',
    }).select().single();
    return Company.fromJson(insert as Map<String, dynamic>);
  }

  Future<AppUser> createAppUser({
    required String uid,
    required String companyId,
    required String email,
    String role = 'admin',
  }) async {
    final insert = await _supabase.from('users').insert({
      'id': uid,
      'company_id': companyId,
      'email': email,
      'role': role,
    }).select().single();
    return AppUser.fromJson(insert as Map<String, dynamic>);
  }

  Future<void> updateCompany(String companyId, Map<String, dynamic> data) async {
    await _supabase.from('companies').update(data).eq('id', companyId);
  }
}
