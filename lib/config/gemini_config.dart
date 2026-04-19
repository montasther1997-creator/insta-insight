import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiConfig {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static bool get hasApiKey => apiKey.isNotEmpty;
  static const String flashModel = 'gemini-2.5-flash';
  static const String proModel = 'gemini-2.5-pro';
}

class ClaudeConfig {
  static String get apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  static bool get hasApiKey => apiKey.isNotEmpty;
  static const String endpoint = 'https://api.anthropic.com/v1/messages';
  static const String version = '2023-06-01';
  static const String model = 'claude-sonnet-4-6';
  static const String fastModel = 'claude-haiku-4-5-20251001';
}
