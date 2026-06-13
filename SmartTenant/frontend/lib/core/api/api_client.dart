import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../auth/auth_storage.dart';
import 'api_exception.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.0.25:4000/api';

  static Future<dynamic> get(String path) async {
    final token = await AuthStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw ApiException('You are not authenticated. Please log in again.');
    }

    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    return _handleResponse(res);
  }

  static Future<Uint8List> getBytes(String path) async {
    final token = await AuthStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw ApiException('You are not authenticated. Please log in again.');
    }

    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/pdf, application/octet-stream, */*',
      },
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes;
    }

    throw ApiException.fromResponse(statusCode: res.statusCode, body: res.body);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final token = await AuthStorage.getAccessToken();

    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    return _handleResponse(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final token = await AuthStorage.getAccessToken();

    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    return _handleResponse(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final token = await AuthStorage.getAccessToken();

    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    return _handleResponse(res);
  }

  static Future<dynamic> delete(String path) async {
    final token = await AuthStorage.getAccessToken();

    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
    );

    return _handleResponse(res);
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _handleResponse(http.Response res) {
    final statusCode = res.statusCode;
    final body = res.body.trim();

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;

      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

    throw ApiException.fromResponse(statusCode: statusCode, body: body);
  }
}
