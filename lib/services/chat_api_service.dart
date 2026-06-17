import '../models/chat_session.dart';
import '../models/message.dart';
import '../models/rating.dart';
import 'supabase_service.dart';

class ChatApiService {
  final _supabase = SupabaseService.instance.client;

  Future<ChatSession> createSession(String companyId, String userIdentifier) async {
    final res = await _supabase.from('chat_sessions').insert({
      'company_id': companyId,
      'user_identifier': userIdentifier,
    }).select().single();
    return ChatSession.fromJson(res as Map<String, dynamic>);
  }

  Future<void> endSession(String sessionId) async {
    await _supabase.from('chat_sessions').update({
      'end_time': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', sessionId);
  }

  Future<ChatMessage> insertMessage({
    required String sessionId,
    required String sender,
    required String message,
  }) async {
    final res = await _supabase.from('messages').insert({
      'session_id': sessionId,
      'sender': sender,
      'message': message,
    }).select().single();
    return ChatMessage.fromJson(res as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final res = await _supabase
        .from('messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
    return (res as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveUnknownQuestion(String companyId, String question) async {
    await _supabase.rpc('upsert_unknown_question', params: {
      'p_company_id': companyId,
      'p_question': question,
    });
  }

  Future<void> submitRating({
    required String sessionId,
    required int rating,
    String? feedback,
  }) async {
    await _supabase.from('ratings').insert({
      'session_id': sessionId,
      'rating': rating,
      'feedback': feedback,
    });
  }

  Future<SessionRating?> getRatingForSession(String sessionId) async {
    final res = await _supabase.from('ratings').select().eq('session_id', sessionId).maybeSingle();
    if (res == null) return null;
    return SessionRating.fromJson(res as Map<String, dynamic>);
  }
}
