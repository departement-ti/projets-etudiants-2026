import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

abstract class AuthService {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<Map<String, dynamic>> signup(
      String firstName, String lastName, String email, String username, String password);
  Future<void> saveToken(String token, String role);
  Future<String?> getToken();
  Future<String?> getRole();
  Future<void> logout();
}

class RealAuthService implements AuthService {
  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await ApiClient.instance.post('/auth/signin', data: {
      'username': username,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> signup(
      String firstName, String lastName, String email, String username, String password) async {
    final response = await ApiClient.instance.post('/auth/signup', data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'username': username,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> saveToken(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('user_role', role);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  @override
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
  }
}
