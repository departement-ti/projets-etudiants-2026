import '../../core/api/api_client.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getMine({
    int page = 1,
    int limit = 30,
  }) async {
    final res = await ApiClient.get('/notifications?page=$page&limit=$limit');

    if (res is Map<String, dynamic>) {
      return res;
    }

    return {
      'items': [],
      'meta': {
        'page': page,
        'limit': limit,
        'total': 0,
        'totalPages': 1,
        'unread': 0,
      },
    };
  }

  static Future<int> unreadCount() async {
    final res = await ApiClient.get('/notifications/unread-count');

    if (res is Map && res['count'] is int) {
      return res['count'];
    }

    return 0;
  }

  static Future<void> markAsRead(String id) async {
    await ApiClient.patch('/notifications/$id/read', {});
  }

  static Future<void> markAllAsRead() async {
    await ApiClient.patch('/notifications/read-all', {});
  }

  static Future<void> delete(String id) async {
    await ApiClient.delete('/notifications/$id');
  }
}
