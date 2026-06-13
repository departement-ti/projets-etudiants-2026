import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'auth_storage.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await ApiClient.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    });

    if (res is Map<String, dynamic>) {
      await AuthStorage.saveAuth(res);
      return res;
    }

    throw ApiException('Invalid login response from server.');
  }

  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    final res = await ApiClient.post('/auth/register', {
      'email': email.trim(),
      'password': password,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
    });

    if (res is Map<String, dynamic>) {
      await AuthStorage.saveAuth(res);
      return res;
    }

    throw ApiException('Invalid register response from server.');
  }

  static Future<void> logout() async {
    await AuthStorage.logout();
  }
}
