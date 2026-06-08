import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService notificationService;

  NotificationProvider({required this.notificationService});

  int _unreadCount = 0;
  List<AppNotification> _notifications = [];
  Timer? _timer;

  int get unreadCount => _unreadCount;
  List<AppNotification> get notifications => _notifications;

  void startPolling() {
    fetchCount();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchCount());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> fetchCount() async {
    try {
      _unreadCount = await notificationService.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchAll() async {
    try {
      _notifications = await notificationService.getAll();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(int id) async {
    await notificationService.markAsRead(id);
    await fetchCount();
  }

  Future<void> markAllAsRead() async {
    await notificationService.markAllAsRead();
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
