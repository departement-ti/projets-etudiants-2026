import '../models/intent.dart';
import 'offline_cache_service.dart';
import 'supabase_service.dart';

class IntentService {
  final _supabase = SupabaseService.instance.client;

  Future<List<ChatIntent>> getIntents(String companyId) async {
    try {
      final res = await _supabase.from('intents').select().eq('company_id', companyId).order('created_at');
      final list = (res as List).map((e) => ChatIntent.fromJson(e as Map<String, dynamic>)).toList();
      await OfflineCacheService.cacheIntents(companyId, list);
      return list;
    } catch (_) {
      final cached = await OfflineCacheService.getCachedIntents(companyId);
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<ChatIntent> createIntent({
    required String companyId,
    required String intentName,
    required List<String> trainingPhrases,
    required String responseText,
  }) async {
    final res = await _supabase.from('intents').insert({
      'company_id': companyId,
      'intent_name': intentName,
      'training_phrases': trainingPhrases,
      'response_text': responseText,
    }).select().single();
    return ChatIntent.fromJson(res as Map<String, dynamic>);
  }

  Future<void> updateIntent(String id, {
    String? intentName,
    List<String>? trainingPhrases,
    String? responseText,
  }) async {
    final map = <String, dynamic>{};
    if (intentName != null) map['intent_name'] = intentName;
    if (trainingPhrases != null) map['training_phrases'] = trainingPhrases;
    if (responseText != null) map['response_text'] = responseText;
    if (map.isEmpty) return;
    await _supabase.from('intents').update(map).eq('id', id);
  }

  Future<void> deleteIntent(String id) async {
    await _supabase.from('intents').delete().eq('id', id);
  }
}
