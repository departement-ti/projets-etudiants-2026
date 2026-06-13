import '../../core/api/api_client.dart';

class AiService {
  static Future<List<dynamic>> getTenants() async {
    final res = await ApiClient.get('/tenants');

    if (res is List) return res;

    throw Exception('Expected list of tenants');
  }

  static Future<Map<String, dynamic>> tenant360(String tenantId) async {
    final res = await ApiClient.get('/ai/tenant-360/$tenantId');

    if (res is Map<String, dynamic>) return res;

    throw Exception('Expected tenant 360 report');
  }

  static Future<void> sendTenant360Message({
    required String tenantId,
    required String message,
  }) async {
    await ApiClient.post('/ai/tenant-360/$tenantId/send-message', {
      'message': message.trim(),
    });
  }

  static Future<Map<String, dynamic>> predictRentDelay({
    required String tenantName,
    required double rentAmount,
    required int previousLatePayments,
    required int openTickets,
    required double unpaidAmount,
  }) async {
    final res = await ApiClient.post('/ai/predict/rent-delay', {
      'tenantName': tenantName,
      'rentAmount': rentAmount,
      'previousLatePayments': previousLatePayments,
      'openTickets': openTickets,
      'unpaidAmount': unpaidAmount,
    });

    if (res is Map<String, dynamic>) return res;

    return {'result': res};
  }

  static Future<Map<String, dynamic>> scoreTenantRisk({
    required String tenantName,
    required int latePayments,
    required double unpaidAmount,
    required int ticketsCount,
    required int leaseMonths,
  }) async {
    final res = await ApiClient.post('/ai/score/risk', {
      'tenantName': tenantName,
      'latePayments': latePayments,
      'unpaidAmount': unpaidAmount,
      'ticketsCount': ticketsCount,
      'leaseMonths': leaseMonths,
    });

    if (res is Map<String, dynamic>) return res;

    return {'result': res};
  }

  // Keep this because Ticket Details still uses it.
  static Future<Map<String, dynamic>> suggestReply({
    required String message,
    required String tone,
  }) async {
    final res = await ApiClient.post('/ai/suggest/reply', {
      'message': message,
      'tone': tone,
    });

    if (res is Map<String, dynamic>) return res;

    return {'result': res};
  }
}
