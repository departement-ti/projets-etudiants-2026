import '../../core/api/api_client.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getMe() async {
    final res = await ApiClient.get('/users/me');

    if (res is Map<String, dynamic>) {
      return res;
    }

    throw Exception('Expected profile object');
  }

  static Future<Map<String, dynamic>> updateMe({
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final res = await ApiClient.patch('/users/me', {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      if (phone != null) 'phone': phone.trim(),
    });

    if (res is Map<String, dynamic>) {
      return res;
    }

    throw Exception('Expected updated profile object');
  }

  static Future<Map<String, dynamic>> getTenantProfile() async {
    final res = await ApiClient.get('/tenants/me/profile');

    if (res is Map<String, dynamic>) {
      return res;
    }

    throw Exception('Expected tenant profile object');
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.patch('/users/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
