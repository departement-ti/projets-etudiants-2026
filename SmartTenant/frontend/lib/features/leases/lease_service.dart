import '../../core/api/api_client.dart';

class LeaseService {
  // --------------------------------------------------
  // LEASES
  // --------------------------------------------------

  static Future<List<dynamic>> getAll() async {
    final res = await ApiClient.get('/leases');

    if (res is List) return res;
    throw Exception('Expected list of leases');
  }

  static Future<List<dynamic>> getLeases() async {
    return getAll();
  }

  static Future<Map<String, dynamic>> getOne(String leaseId) async {
    final res = await ApiClient.get('/leases/$leaseId');

    if (res is Map<String, dynamic>) return res;
    throw Exception('Expected lease object');
  }

  static Future<Map<String, dynamic>> getLease(String leaseId) async {
    return getOne(leaseId);
  }

  static Future<void> create({
    required String tenantId,
    required String unitId,
    required double rentAmount,
    required String startDate,
    required String endDate,
    required String frequency,
    double? depositAmount,
  }) async {
    await ApiClient.post('/leases', {
      'tenantId': tenantId,
      'unitId': unitId,
      'rentAmount': rentAmount,
      'startDate': startDate,
      'endDate': endDate,
      'frequency': frequency,
      if (depositAmount != null) 'depositAmount': depositAmount,
    });
  }

  static Future<void> createLease({
    required String tenantId,
    required String unitId,
    required double rentAmount,
    required String startDate,
    required String endDate,
    required String frequency,
    double? depositAmount,
  }) async {
    return create(
      tenantId: tenantId,
      unitId: unitId,
      rentAmount: rentAmount,
      startDate: startDate,
      endDate: endDate,
      frequency: frequency,
      depositAmount: depositAmount,
    );
  }

  static Future<void> terminate(String leaseId) async {
    await ApiClient.patch('/leases/$leaseId/terminate', {});
  }

  static Future<void> terminateLease(String leaseId) async {
    return terminate(leaseId);
  }

  // --------------------------------------------------
  // DATA FOR CREATE LEASE PAGE
  // --------------------------------------------------

  static Future<List<dynamic>> getTenants() async {
    final res = await ApiClient.get('/tenants');

    if (res is List) return res;
    throw Exception('Expected list of tenants');
  }

  static Future<List<dynamic>> getProperties() async {
    final res = await ApiClient.get('/properties');

    if (res is List) return res;
    throw Exception('Expected list of properties');
  }

  static Future<List<dynamic>> getUnitsByProperty(String propertyId) async {
    final res = await ApiClient.get('/units/property/$propertyId');

    if (res is List) return res;
    throw Exception('Expected list of units');
  }

  static Future<Map<String, dynamic>> getUnit(String unitId) async {
    final res = await ApiClient.get('/units/$unitId');

    if (res is Map<String, dynamic>) return res;
    throw Exception('Expected unit object');
  }
}
