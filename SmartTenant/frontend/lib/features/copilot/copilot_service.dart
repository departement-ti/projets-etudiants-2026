import '../../core/api/api_client.dart';

class CopilotService {
  static Future<Map<String, dynamic>> briefing() async {
    final res = await ApiClient.get('/copilot/briefing');

    if (res is Map<String, dynamic>) {
      return res;
    }

    return {};
  }
}
