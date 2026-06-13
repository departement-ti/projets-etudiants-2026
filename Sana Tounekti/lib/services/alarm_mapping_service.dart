import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmMappingService {
  static const String _key = 'alarm_mappings';

  static Future<void> saveMapping({
    required int alarmId,
    required String medDocId,
    required String logDocId,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    Map<String, dynamic> mappings = {};
    if (data != null) {
      mappings = Map<String, dynamic>.from(jsonDecode(data));
    }
    mappings[alarmId.toString()] = {
      'medDocId': medDocId,
      'logDocId': logDocId,
      'email': email,
    };
    await prefs.setString(_key, jsonEncode(mappings));
  }

  static Future<Map<String, dynamic>?> getMapping(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;
    final mappings = Map<String, dynamic>.from(jsonDecode(data));
    return mappings[alarmId.toString()] as Map<String, dynamic>?;
  }

  static Future<void> removeMapping(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return;
    final mappings = Map<String, dynamic>.from(jsonDecode(data));
    mappings.remove(alarmId.toString());
    await prefs.setString(_key, jsonEncode(mappings));
  }
}
