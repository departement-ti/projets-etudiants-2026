import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get openRouterApiKey =>
      dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static const String openRouterBaseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
}
