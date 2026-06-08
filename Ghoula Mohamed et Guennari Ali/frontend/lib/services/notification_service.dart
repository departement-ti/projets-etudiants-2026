import 'api_client.dart';
import '../models/notification.dart';

abstract class NotificationService {
  Future<int> getUnreadCount();
  Future<List<AppNotification>> getAll();
  Future<void> markAsRead(int id);
  Future<void> markAllAsRead();
}

class RealNotificationService implements NotificationService {
  @override
  Future<int> getUnreadCount() async {
    final res = await ApiClient.instance.get('/notifications/unread-count');
    return (res.data['count'] ?? 0) as int;
  }

  @override
  Future<List<AppNotification>> getAll() async {
    final res = await ApiClient.instance.get('/notifications');
    return (res.data as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  @override
  Future<void> markAsRead(int id) async {
    await ApiClient.instance.put('/notifications/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await ApiClient.instance.put('/notifications/read-all');
  }
}
