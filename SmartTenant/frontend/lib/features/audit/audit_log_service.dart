import '../../core/api/api_client.dart';

class AuditLogService {
  static Future<Map<String, dynamic>> getLogs({
    int page = 1,
    int limit = 25,
    String? action,
    String? resource,
    String? actorId,
  }) async {
    final query = <String>[
      'page=$page',
      'limit=$limit',
      if (action != null && action.trim().isNotEmpty)
        'action=${Uri.encodeComponent(action.trim())}',
      if (resource != null && resource.trim().isNotEmpty)
        'resource=${Uri.encodeComponent(resource.trim())}',
      if (actorId != null && actorId.trim().isNotEmpty)
        'actorId=${Uri.encodeComponent(actorId.trim())}',
    ].join('&');

    final res = await ApiClient.get('/audit-logs?$query');

    if (res is Map<String, dynamic>) {
      return res;
    }

    return {
      'items': [],
      'meta': {'page': page, 'limit': limit, 'total': 0, 'totalPages': 1},
    };
  }
}
