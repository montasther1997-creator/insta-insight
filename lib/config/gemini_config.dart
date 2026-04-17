import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiConfig {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String flashModel = 'gemini-1.5-flash';
  static const String proModel = 'gemini-1.5-pro';
}
