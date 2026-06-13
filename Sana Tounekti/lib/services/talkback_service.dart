import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TalkbackService {
  static const String _prefKey = 'talkback_enabled';

  static final TalkbackService _instance = TalkbackService._();
  factory TalkbackService() => _instance;
  TalkbackService._();

  FlutterTts? _tts;
  bool _enabled = false;
  bool get isEnabled => _enabled;
  String _currentLang = 'fr';

  static const Map<String, String> _langMap = {
    'en': 'en-US',
    'fr': 'fr-FR',
    'ar': 'ar-SA',
  };

  Future<void> init() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? false;
    _tts = FlutterTts();
    await _tts!.setSpeechRate(0.45);
    await _tts!.setVolume(1.0);
  }

  Future<void> setLanguage(String langCode) async {
    if (_tts == null || kIsWeb) return;
    final fullLang = _langMap[langCode] ?? langCode;
    if (fullLang == _currentLang) return;
    _currentLang = fullLang;
    try {
      await _tts!.setLanguage(fullLang);
    } catch (e) {
      print('Talkback setLanguage($fullLang) error: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    if (!value && _tts != null) {
      await _tts!.stop();
    }
  }

  Future<void> speak(String text) async {
    if (!_enabled || kIsWeb || _tts == null || text.isEmpty) return;
    try {
      await _tts!.stop();
      final result = await _tts!.speak(text);
      if (result != 1) {
        print('Talkback speak returned: $result');
      }
    } catch (e) {
      print('Talkback error: $e');
    }
  }

  Future<void> stop() async {
    if (_tts == null || kIsWeb) return;
    try {
      await _tts!.stop();
    } catch (_) {}
  }
}
