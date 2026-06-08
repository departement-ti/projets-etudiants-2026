import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService userService;

  UserProvider({required this.userService});

  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await userService.fetchAll();
    } catch (_) {
      _error = 'Impossible de charger les utilisateurs.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> create(Map<String, dynamic> data) async {
    try {
      final created = await userService.create(data);
      _users.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Erreur lors de la création.';
      notifyListeners();
      return null;
    }
  }

  Future<User?> update(int id, Map<String, dynamic> data) async {
    try {
      final updated = await userService.update(id, data);
      final idx = _users.indexWhere((u) => u.id == id);
      if (idx != -1) _users[idx] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> setPassword(int id, String password) async {
    try {
      await userService.setPassword(id, password);
      return true;
    } catch (e) {
      _error = 'Erreur lors de la réinitialisation du mot de passe.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> disable(int id) async {
    try {
      await userService.disable(id);
      final idx = _users.indexWhere((u) => u.id == id);
      if (idx != -1) {
        final old = _users[idx];
        _users[idx] = User(
          id: old.id,
          username: old.username,
          email: old.email,
          firstName: old.firstName,
          lastName: old.lastName,
          enabled: false,
          roles: old.roles,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la désactivation.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> enable(int id) async {
    try {
      await userService.enable(id);
      final idx = _users.indexWhere((u) => u.id == id);
      if (idx != -1) {
        final old = _users[idx];
        _users[idx] = User(
          id: old.id,
          username: old.username,
          email: old.email,
          firstName: old.firstName,
          lastName: old.lastName,
          enabled: true,
          roles: old.roles,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'activation.';
      notifyListeners();
      return false;
    }
  }
}
