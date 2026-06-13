import '../../core/api/api_client.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getStats() async {
    final res = await ApiClient.get('/dashboard');

    if (res is Map<String, dynamic>) {
      return res;
    }

    throw Exception('Invalid dashboard response');
  }
}
