import '../../core/api/api_client.dart';

class OrganizationService {
  static Future<List<dynamic>> getAll() async {
    final res = await ApiClient.get('/organizations');

    if (res is List) {
      return res;
    }

    throw Exception('Expected list of organizations');
  }

  static Future<Map<String, dynamic>> create({
    required String name,
    required String slug,
  }) async {
    final res = await ApiClient.post('/organizations', {
      'name': name.trim(),
      'slug': slug.trim().toLowerCase(),
    });

    if (res is Map<String, dynamic>) {
      return res;
    }

    throw Exception('Expected organization object');
  }

  static Future<Map<String, dynamic>> update({
    required String id,
    String? name,
    String? slug,
    bool? isActive,
  }) async {
    final res = await ApiClient.patch('/organizations/$id', {
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (slug != null && slug.trim().isNotEmpty)
        'slug': slug.trim().toLowerCase(),
      if (isActive != null) 'isActive': isActive,
    });

    if (res is Map<String, dynamic>) {
      return res;
    }

    throw Exception('Expected organization object');
  }

  static Future<void> deactivate(String id) async {
    await ApiClient.delete('/organizations/$id');
  }

  static Future<void> reactivate(String id) async {
    await update(id: id, isActive: true);
  }
}
