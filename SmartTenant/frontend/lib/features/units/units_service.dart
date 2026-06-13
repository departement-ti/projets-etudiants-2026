import '../../core/api/api_client.dart';

class UnitsService {
  static Future<List<dynamic>> getByProperty(String propertyId) async {
    final res = await ApiClient.get('/units/property/$propertyId');

    if (res is List) return res;
    throw Exception('Expected list of units');
  }

  static Future<Map<String, dynamic>> getOne(String unitId) async {
    final res = await ApiClient.get('/units/$unitId');

    if (res is Map<String, dynamic>) return res;
    throw Exception('Expected unit object');
  }

  static Future<void> create({
    required String propertyId,
    required String title,
    required double rentAmount,
    int? floor,
    int? bedrooms,
    int? bathrooms,
    String? number,
    double? sizeSqm,
    String? status,
  }) async {
    await ApiClient.post('/units/property/$propertyId', {
      'title': title.trim(),
      'rentAmount': rentAmount,
      if (floor != null) 'floor': floor,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (number != null && number.trim().isNotEmpty) 'number': number.trim(),
      if (sizeSqm != null) 'sizeSqm': sizeSqm,
      if (status != null) 'status': status,
    });
  }

  static Future<void> update(
    String unitId, {
    String? title,
    double? rentAmount,
    int? floor,
    int? bedrooms,
    int? bathrooms,
    String? number,
    double? sizeSqm,
    String? status,
  }) async {
    await ApiClient.put('/units/$unitId', {
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (rentAmount != null) 'rentAmount': rentAmount,
      if (floor != null) 'floor': floor,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (number != null) 'number': number.trim(),
      if (sizeSqm != null) 'sizeSqm': sizeSqm,
      if (status != null) 'status': status,
    });
  }

  static Future<void> delete(String unitId) async {
    await ApiClient.delete('/units/$unitId');
  }
}
