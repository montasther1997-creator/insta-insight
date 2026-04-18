import 'package:flutter_dotenv/flutter_dotenv.dart';

class InstagramConfig {
  static String get appId => dotenv.env['INSTAGRAM_APP_ID'] ?? '';
  static String get appSecret => dotenv.env['INSTAGRAM_APP_SECRET'] ?? '';
  static String get redirectUri => dotenv.env['INSTAGRAM_REDIRECT_URI'] ?? '';

  /// Test token for development — skips OAuth when present
  static String get testToken => dotenv.env['INSTAGRAM_TEST_TOKEN'] ?? '';
  static bool get hasTestToken => testToken.isNotEmpty;

  /// Facebook Login OAuth (required for Instagram Graph API)
  static const String authUrl = 'https://www.facebook.com/v21.0/dialog/oauth';
  static const String tokenUrl = 'https://graph.facebook.com/v21.0/oauth/access_token';
  static const String graphUrl = 'https://graph.facebook.com/v21.0';

  static const List<String> scopes = [
    'instagram_basic',
    'instagram_manage_insights',
    'pages_show_list',
    'pages_read_engagement',
  ];

  static String get authorizationUrl {
    final scope = scopes.join(',');
    return '$authUrl?client_id=$appId&redirect_uri=$redirectUri&scope=$scope&response_type=code';
  }
}
