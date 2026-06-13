import '../../core/api/api_client.dart';

class TicketService {
  static Future<List<dynamic>> getAll() async {
    final res = await ApiClient.get('/tickets');

    if (res is List) return res;
    throw Exception('Expected list of tickets');
  }

  static Future<List<dynamic>> getMyTickets() async {
    final res = await ApiClient.get('/tickets/me');

    if (res is List) return res;
    throw Exception('Expected list of my tickets');
  }

  static Future<Map<String, dynamic>> getOne(String ticketId) async {
    final res = await ApiClient.get('/tickets/$ticketId');

    if (res is Map<String, dynamic>) return res;
    throw Exception('Expected ticket object');
  }

  static Future<void> create({
    required String title,
    String? description,
    String? propertyId,
    String? unitId,
    String? priority,
  }) async {
    await ApiClient.post('/tickets', {
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (propertyId != null && propertyId.isNotEmpty) 'propertyId': propertyId,
      if (unitId != null && unitId.isNotEmpty) 'unitId': unitId,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
    });
  }

  static Future<void> addMessage({
    required String ticketId,
    required String body,
  }) async {
    await ApiClient.post('/tickets/$ticketId/messages', {'body': body.trim()});
  }

  static Future<void> updateStatus({
    required String ticketId,
    required String status,
  }) async {
    await ApiClient.patch('/tickets/$ticketId', {'status': status});
  }

  static Future<void> updateTicket({
    required String ticketId,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? propertyId,
    String? unitId,
    String? assignedToId,
  }) async {
    await ApiClient.patch('/tickets/$ticketId', {
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (description != null) 'description': description.trim(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
      if (propertyId != null && propertyId.isNotEmpty) 'propertyId': propertyId,
      if (unitId != null && unitId.isNotEmpty) 'unitId': unitId,
      if (assignedToId != null && assignedToId.isNotEmpty)
        'assignedToId': assignedToId,
    });
  }

  static Future<void> assign({
    required String ticketId,
    required String userId,
  }) async {
    await ApiClient.patch('/tickets/$ticketId/assign/$userId', {});
  }

  static Future<List<dynamic>> getAgents() async {
    final res = await ApiClient.get('/users/agents');

    if (res is List) return res;
    throw Exception('Expected list of agents');
  }

  static Future<void> delete(String ticketId) async {
    await ApiClient.delete('/tickets/$ticketId');
  }
}
