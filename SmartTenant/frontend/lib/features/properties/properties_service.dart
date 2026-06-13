import '../../core/api/api_client.dart';

class PropertiesService {
  static Future<List<dynamic>> getAll() async {
    final res = await ApiClient.get('/properties');

    if (res is List) {
      return res;
    }

    throw Exception('Expected list of properties');
  }

  static Future<Map<String, dynamic>> getOne(String id) async {
    final res = await ApiClient.get('/properties/$id');

    if (res is Map<String, dynamic>) {
      return res;
    }

    throw Exception('Expected property object');
  }

  static Future<void> create({
    required String title,
    required String address,
    String? city,
    String? country,
  }) async {
    await ApiClient.post('/properties', {
      'title': title,
      'name': title, // backend/schema requires name
      'address': address,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (country != null && country.trim().isNotEmpty)
        'country': country.trim(),
    });
  }

  static Future<void> update(
    String id, {
    String? title,
    String? address,
    String? city,
    String? country,
  }) async {
    await ApiClient.patch('/properties/$id', {
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (title != null && title.trim().isNotEmpty) 'name': title.trim(),
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (city != null) 'city': city.trim().isEmpty ? null : city.trim(),
      if (country != null)
        'country': country.trim().isEmpty ? null : country.trim(),
    });
  }

  static Future<void> delete(String id) async {
    await ApiClient.delete('/properties/$id');
  }
}
