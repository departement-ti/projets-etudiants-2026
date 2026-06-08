import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  AuthProvider({required this.authService});

  bool _isAuthenticated = false;
  String? _role;
  String? _user;
  String? _errorMessage;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;
  String? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> data = await authService.login(username, password);
      final token = data['token'] as String;
      final roles = data['roles'] as List<dynamic>;
      final usernameStr = data['username'] as String;
      final role = roles.isNotEmpty ? roles.first as String : 'Visiteur';

      await authService.saveToken(token, role);
      _isAuthenticated = true;
      _role = role;
      _user = usernameStr;
      return true;
    } catch (e) {
      _errorMessage =
          'Identifiants incorrects. Vérifiez votre nom d\'utilisateur et mot de passe.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(
      String firstName, String lastName, String email, String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> data =
          await authService.signup(firstName, lastName, email, username, password);
      final token = data['token'] as String;
      final roles = data['roles'] as List<dynamic>;
      final usernameStr = data['username'] as String;
      final role = roles.isNotEmpty ? roles.first as String : 'ROLE_CLIENT';

      await authService.saveToken(token, role);
      _isAuthenticated = true;
      _role = role;
      _user = usernameStr;
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'inscription. Veuillez réessayer.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await authService.logout();
    _isAuthenticated = false;
    _role = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final token = await authService.getToken();
    _isAuthenticated = token != null;
    _role = await authService.getRole();
    notifyListeners();
  }
}
