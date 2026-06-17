import '../models/unknown_question.dart';
import 'supabase_service.dart';

class UnknownQuestionsService {
  final _supabase = SupabaseService.instance.client;

  Future<List<UnknownQuestion>> getPending(String companyId) async {
    final res = await _supabase
        .from('unknown_questions')
        .select()
        .eq('company_id', companyId)
        .eq('status', 'pending')
        .order('frequency', ascending: false);
    return (res as List).map((e) => UnknownQuestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> approve(String id) async {
    await _supabase.from('unknown_questions').update({'status': 'approved'}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _supabase.from('unknown_questions').delete().eq('id', id);
  }
}
