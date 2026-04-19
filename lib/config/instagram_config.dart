import 'package:flutter_dotenv/flutter_dotenv.dart';

class InstagramConfig {
  static String get appId => dotenv.env['INSTAGRAM_APP_ID'] ?? '';
  static String get appSecret => dotenv.env['INSTAGRAM_APP_SECRET'] ?? '';
  static String get redirectUri => dotenv.env['INSTAGRAM_REDIRECT_URI'] ?? '';

  /// Test token for development — skips OAuth when present
  static String get testToken => dotenv.env['INSTAGRAM_TEST_TOKEN'] ?? '';
  static bool get hasTestToken => testToken.isNotEmpty;

  /// Instagram API with Instagram Login (direct Instagram OAuth)
  static const String authUrl = 'https://www.instagram.com/oauth/authorize';
  static const String tokenUrl = 'https://api.instagram.com/oauth/access_token';
  static const String graphUrl = 'https://graph.instagram.com';

  static const List<String> scopes = [
    'instagram_business_basic',
    'instagram_business_manage_insights',
  ];

  static String get authorizationUrl {
    final scope = scopes.join(',');
    // NOTE: we deliberately drop `force_authentication=1`. Forcing re-auth
    // routes the "Allow" redirect through Instagram's `l.instagram.com`
    // link-shim, which renders blank in Chrome Custom Tabs on some Android
    // browsers (notably Huawei) and never fires the scheme redirect. The
    // normal flow redirects straight to `redirect_uri`.
    return '$authUrl?enable_fb_login=0&client_id=$appId&redirect_uri=${Uri.encodeComponent(redirectUri)}&scope=$scope&response_type=code';
  }
}
