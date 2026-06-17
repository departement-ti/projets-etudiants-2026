import 'supabase_service.dart';

class AnalyticsService {
  final _supabase = SupabaseService.instance.client;

  Future<Map<String, dynamic>> getDashboardStats(String companyId) async {
    final sessionsRes = await _supabase
        .from('chat_sessions')
        .select('id, started_at, end_time')
        .eq('company_id', companyId);
    final sessions = sessionsRes as List;
    final totalSessions = sessions.length;

    int totalMessages = 0;
    int botMessages = 0;
    double totalDurationSec = 0;
    int withEndTime = 0;

    for (final s in sessions) {
      final map = s as Map<String, dynamic>;
      final start = map['started_at'] != null ? DateTime.parse(map['started_at'] as String) : map['start_time'] != null ? DateTime.parse(map['start_time'] as String) : null;
      final end = map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null;
      if (end != null && start != null) {
        totalDurationSec += end.difference(start).inSeconds;
        withEndTime++;
      }
      final msgRes = await _supabase.from('messages').select('sender').eq('session_id', map['id']);
      final msgs = msgRes as List;
      totalMessages += msgs.length;
      botMessages += msgs.where((m) => (m as Map)['sender'] == 'bot').length;
    }

    final sessionIds = sessions.map((s) => (s as Map)['id']).toList();
    final ratings = sessionIds.isEmpty
        ? <dynamic>[]
        : (await _supabase.from('ratings').select('rating').inFilter('session_id', sessionIds)) as List;
    final avgRating = ratings.isEmpty
        ? 0.0
        : (ratings.map((r) => (r as Map)['rating'] as num).reduce((a, b) => a + b) / ratings.length);

    final unknownRes = await _supabase
        .from('unknown_questions')
        .select('id')
        .eq('company_id', companyId)
        .eq('status', 'pending');
    final pendingUnknown = (unknownRes as List).length;

    final totalWithMessages = totalMessages;
    final unansweredPct = totalWithMessages > 0 && pendingUnknown > 0
        ? (pendingUnknown / totalSessions).clamp(0.0, 1.0) * 100
        : 0.0;

    return {
      'totalSessions': totalSessions,
      'totalMessages': totalMessages,
      'botMessages': botMessages,
      'avgConversationDurationSeconds': withEndTime > 0 ? totalDurationSec / withEndTime : 0,
      'averageRating': avgRating,
      'satisfactionRate': ratings.isNotEmpty ? (ratings.where((r) => ((r as Map)['rating'] as num) >= 4).length / ratings.length * 100) : 0.0,
      'totalRatings': ratings.length,
      'pendingUnknownQuestions': pendingUnknown,
      'unansweredPercentage': unansweredPct,
    };
  }

  Future<List<Map<String, dynamic>>> getMostAskedQuestions(String companyId, {int limit = 10}) async {
    final sessionsRes = await _supabase
        .from('chat_sessions')
        .select('id')
        .eq('company_id', companyId);
    final sessionIds = (sessionsRes as List).map((s) => (s as Map)['id'] as String).toList();
    if (sessionIds.isEmpty) return [];

    final res = await _supabase
        .from('messages')
        .select('message')
        .eq('sender', 'user')
        .inFilter('session_id', sessionIds);
    final list = res as List;
    final counts = <String, int>{};
    for (final m in list) {
      final text = ((m as Map)['message'] as String?)?.trim() ?? '';
      if (text.isNotEmpty) counts[text] = (counts[text] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => {'text': e.key, 'count': e.value}).toList();
  }
}
