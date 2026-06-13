import '../../core/api/api_client.dart';

class TenantService {
  static Future<List<dynamic>> getTenants() async {
    final res = await ApiClient.get('/tenants');

    if (res is List) return res;

    throw Exception('Expected list of tenants');
  }

  static Future<List<dynamic>> getAvailableTenantUsers() async {
    final res = await ApiClient.get('/tenants/available-users');

    if (res is List) return res;

    throw Exception('Expected list of available tenant users');
  }

  static Future<Map<String, dynamic>> createTenantProfile({
    required String userId,
    String? nationalId,
  }) async {
    final body = <String, dynamic>{
      'userId': userId,
      'nationalId': nationalId?.trim(),
    };

    body.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await ApiClient.post('/tenants', body);

    if (res is Map<String, dynamic>) return res;

    throw Exception('Expected created tenant profile');
  }

  static Future<Map<String, dynamic>> createTenantAccountAndProfile({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? nationalId,
  }) async {
    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'firstName': firstName?.trim(),
      'lastName': lastName?.trim(),
      'phone': phone?.trim(),
      'nationalId': nationalId?.trim(),
    };

    body.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await ApiClient.post('/tenants/account', body);

    if (res is Map<String, dynamic>) return res;

    throw Exception('Expected created tenant account and profile');
  }

  static Future<Map<String, dynamic>> getTenant(String tenantId) async {
    final res = await ApiClient.get('/tenants/$tenantId');

    if (res is Map<String, dynamic>) return res;

    throw Exception('Expected tenant object');
  }

  static Future<void> deleteTenant(String tenantId) async {
    await ApiClient.delete('/tenants/$tenantId');
  }
}
