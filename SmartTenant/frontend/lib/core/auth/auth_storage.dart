import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _accessToken = 'accessToken';
  static const _refreshToken = 'refreshToken';

  static const _userId = 'userId';
  static const _userEmail = 'userEmail';
  static const _userRole = 'userRole';
  static const _firstName = 'firstName';
  static const _lastName = 'lastName';

  static Future<void> saveAuth(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final accessToken = data['accessToken']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    final user = data['user'];

    if (accessToken != null && accessToken.isNotEmpty) {
      await prefs.setString(_accessToken, accessToken);
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshToken, refreshToken);
    }

    if (user is Map<String, dynamic>) {
      await prefs.setString(_userId, user['id']?.toString() ?? '');
      await prefs.setString(_userEmail, user['email']?.toString() ?? '');
      await prefs.setString(_userRole, user['role']?.toString() ?? '');
      await prefs.setString(_firstName, user['firstName']?.toString() ?? '');
      await prefs.setString(_lastName, user['lastName']?.toString() ?? '');
    }
  }

  static Future<void> updateCachedUser({
    String? firstName,
    String? lastName,
    String? email,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (firstName != null) {
      await prefs.setString(_firstName, firstName);
    }

    if (lastName != null) {
      await prefs.setString(_lastName, lastName);
    }

    if (email != null) {
      await prefs.setString(_userEmail, email);
    }

    if (role != null) {
      await prefs.setString(_userRole, role);
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshToken);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userId);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmail);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRole);
  }

  static Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();

    final firstName = prefs.getString(_firstName) ?? '';
    final lastName = prefs.getString(_lastName) ?? '';
    final email = prefs.getString(_userEmail) ?? '';

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;

    return 'SmartTenant User';
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> isTenant() async {
    final role = await getUserRole();
    return role == 'TENANT';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
