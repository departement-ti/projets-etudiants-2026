import '../../core/api/api_client.dart';

class UserManagementService {
  static Future<List<dynamic>> getUsers() async {
    final res = await ApiClient.get('/users');

    if (res is List) return res;

    throw Exception('Expected list of users');
  }

  static Future<List<dynamic>> getOrganizations() async {
    final res = await ApiClient.get('/organizations');

    if (res is List) return res;

    throw Exception('Expected list of organizations');
  }

  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
    String? phone,
    String? organizationId,
  }) async {
    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'role': role,
      'firstName': firstName?.trim(),
      'lastName': lastName?.trim(),
      'phone': phone?.trim(),
      'organizationId': organizationId,
    };

    body.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await ApiClient.post('/users', body);

    if (res is Map<String, dynamic>) return res;

    throw Exception('Expected created user object');
  }

  static Future<void> changeRole({
    required String userId,
    required String role,
  }) async {
    await ApiClient.patch('/users/$userId/role', {'role': role});
  }

  static Future<void> assignOrganization({
    required String userId,
    required String organizationId,
  }) async {
    await ApiClient.post('/organizations/$organizationId/assign/$userId', {});
  }

  static Future<void> deleteUser(String userId) async {
    await ApiClient.delete('/users/$userId');
  }
}
