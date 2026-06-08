import 'package:flutter/material.dart';

class NotificationsProvider extends ChangeNotifier {
  int? _notificationCount;
  bool _isLoading = false;
  String? _error;

  int? get notificationCount => _notificationCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 900)); //simulation
      _notificationCount = 10;
    } catch (_) {
      _error = 'Impossible de charger les données. Vérifiez la connexion.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
