import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/intent.dart';

/// Caches FAQ/intents locally for offline use. Sync when online.
class OfflineCacheService {
  static Future<void> cacheIntents(String companyId, List<ChatIntent> intents) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${AppConstants.cachedFaqKey}_$companyId';
    final list = intents.map((e) => e.toJson()).toList();
    await prefs.setString(key, jsonEncode(list));
    await prefs.setString(AppConstants.lastSyncKey, DateTime.now().toIso8601String());
  }

  static Future<List<ChatIntent>?> getCachedIntents(String companyId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${AppConstants.cachedFaqKey}_$companyId';
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ChatIntent.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> enqueueOfflineMessage(String companyId, String sessionId, String sender, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final key = AppConstants.offlineMessagesKey;
    final existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode({
      'company_id': companyId,
      'session_id': sessionId,
      'sender': sender,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(key, existing);
  }

  static Future<List<Map<String, dynamic>>> getOfflineMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.offlineMessagesKey) ?? [];
    final list = <Map<String, dynamic>>[];
    for (final s in raw) {
      try {
        list.add(Map<String, dynamic>.from(jsonDecode(s) as Map));
      } catch (_) {}
    }
    return list;
  }

  static Future<void> clearOfflineMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.offlineMessagesKey);
  }
}
