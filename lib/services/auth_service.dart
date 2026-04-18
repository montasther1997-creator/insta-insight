import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/instagram_config.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Dio _dio = Dio();

  /// Start Instagram login — uses test token if available, otherwise OAuth
  Future<UserModel?> loginWithInstagram() async {
    if (InstagramConfig.hasTestToken) {
      return _loginWithTestToken();
    }
    return _loginWithOAuth();
  }

  /// Login using test token from .env (development mode)
  Future<UserModel?> _loginWithTestToken() async {
    debugPrint('🔧 Using test token mode — skipping OAuth');
    final token = InstagramConfig.testToken;

    // Get user profile directly with the test token (test tokens use /me endpoint)
    final response = await _dio.get(
      '${InstagramConfig.graphUrl}/me',
      queryParameters: {
        'fields': 'id,username,name,profile_picture_url,followers_count,media_count',
        'access_token': token,
      },
    );
    final profile = response.data as Map<String, dynamic>;
    final userId = profile['id'].toString();

    // Save user to Supabase
    final user = await _saveUser(
      instagramId: userId,
      accessToken: token,
      username: profile['username'] ?? '',
      fullName: profile['name'] ?? '',
      profilePictureUrl: profile['profile_picture_url'] ?? '',
      followersCount: profile['followers_count'] ?? 0,
    );

    await _storeInstagramId(userId);
    return user;
  }

  /// Login using Facebook Login OAuth flow (production mode)
  Future<UserModel?> _loginWithOAuth() async {
    // 1. Open Facebook Login page
    final result = await FlutterWebAuth2.authenticate(
      url: InstagramConfig.authorizationUrl,
      callbackUrlScheme: 'io.supabase.instainsight',
    );

    // 2. Extract authorization code from callback
    final uri = Uri.parse(result);
    final code = uri.queryParameters['code'];
    if (code == null) throw Exception('لم يتم الحصول على رمز التفويض');

    // 3. Exchange code for Facebook access token
    final accessToken = await _exchangeCodeForToken(code);

    // 4. Get long-lived token
    final longLivedToken = await _getLongLivedToken(accessToken);

    // 5. Get Instagram Business Account via Facebook Pages
    final igAccount = await _getInstagramBusinessAccount(longLivedToken);
    final igUserId = igAccount['id'] as String;

    // 6. Get Instagram profile
    final profile = await _getUserProfile(igUserId, longLivedToken);

    // 7. Save user to Supabase
    final user = await _saveUser(
      instagramId: igUserId,
      accessToken: longLivedToken,
      username: profile['username'] ?? '',
      fullName: profile['name'] ?? '',
      profilePictureUrl: profile['profile_picture_url'] ?? '',
      followersCount: profile['followers_count'] ?? 0,
    );

    await _storeInstagramId(igUserId);
    return user;
  }

  /// Exchange authorization code for Facebook access token
  Future<String> _exchangeCodeForToken(String code) async {
    final response = await _dio.get(
      InstagramConfig.tokenUrl,
      queryParameters: {
        'client_id': InstagramConfig.appId,
        'client_secret': InstagramConfig.appSecret,
        'redirect_uri': InstagramConfig.redirectUri,
        'code': code,
      },
    );
    return response.data['access_token'] as String;
  }

  /// Exchange short-lived token for long-lived token (60 days)
  Future<String> _getLongLivedToken(String shortLivedToken) async {
    final response = await _dio.get(
      '${InstagramConfig.graphUrl}/oauth/access_token',
      queryParameters: {
        'grant_type': 'fb_exchange_token',
        'client_id': InstagramConfig.appId,
        'client_secret': InstagramConfig.appSecret,
        'fb_exchange_token': shortLivedToken,
      },
    );
    return response.data['access_token'] as String;
  }

  /// Get Instagram Business Account ID from Facebook Pages
  Future<Map<String, dynamic>> _getInstagramBusinessAccount(String accessToken) async {
    // Get user's Facebook Pages
    final pagesResponse = await _dio.get(
      '${InstagramConfig.graphUrl}/me/accounts',
      queryParameters: {
        'fields': 'id,name,instagram_business_account',
        'access_token': accessToken,
      },
    );

    final pages = pagesResponse.data['data'] as List;
    if (pages.isEmpty) {
      throw Exception('لا توجد صفحات فيسبوك مرتبطة بحسابك. تحتاج ربط صفحة فيسبوك بحساب إنستغرام Business/Creator.');
    }

    // Find the page with an Instagram Business Account
    for (final page in pages) {
      if (page['instagram_business_account'] != null) {
        return page['instagram_business_account'] as Map<String, dynamic>;
      }
    }

    throw Exception('لا يوجد حساب إنستغرام Business/Creator مرتبط بصفحات فيسبوك الخاصة بك.');
  }

  /// Get user profile from Instagram Graph API
  Future<Map<String, dynamic>> _getUserProfile(String igUserId, String accessToken) async {
    final response = await _dio.get(
      '${InstagramConfig.graphUrl}/$igUserId',
      queryParameters: {
        'fields': 'id,username,name,profile_picture_url,followers_count,media_count',
        'access_token': accessToken,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Save or update user in Supabase
  Future<UserModel> _saveUser({
    required String instagramId,
    required String accessToken,
    required String username,
    required String fullName,
    required String profilePictureUrl,
    required int followersCount,
  }) async {
    final now = DateTime.now().toIso8601String();
    final expiresAt = DateTime.now().add(const Duration(days: 60)).toIso8601String();

    final data = {
      'instagram_id': instagramId,
      'access_token': accessToken,
      'username': username,
      'full_name': fullName,
      'profile_picture_url': profilePictureUrl,
      'followers_count': followersCount,
      'token_expires_at': expiresAt,
      'updated_at': now,
    };

    final response = await _supabase
        .from('users')
        .upsert({...data, 'created_at': now}, onConflict: 'instagram_id')
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  /// Get current logged in user from Supabase
  Future<UserModel?> getCurrentUser() async {
    try {
      final storedId = await _getStoredInstagramId();
      if (storedId == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('instagram_id', storedId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('getCurrentUser error: $e');
      return null;
    }
  }

  /// Store Instagram ID locally
  Future<void> _storeInstagramId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('instagram_id', id);
  }

  /// Get stored Instagram ID
  Future<String?> _getStoredInstagramId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('instagram_id');
  }

  /// Refresh token if it's about to expire (within 7 days)
  Future<void> refreshTokenIfNeeded(UserModel user) async {
    if (user.tokenExpiresAt == null) return;
    final daysLeft = user.tokenExpiresAt!.difference(DateTime.now()).inDays;
    if (daysLeft > 7) return;

    try {
      final response = await _dio.get(
        '${InstagramConfig.graphUrl}/oauth/access_token',
        queryParameters: {
          'grant_type': 'fb_exchange_token',
          'client_id': InstagramConfig.appId,
          'client_secret': InstagramConfig.appSecret,
          'fb_exchange_token': user.accessToken,
        },
      );

      final newToken = response.data['access_token'] as String;
      final expiresIn = response.data['expires_in'] as int;
      final newExpiry = DateTime.now().add(Duration(seconds: expiresIn));

      await _supabase.from('users').update({
        'access_token': newToken,
        'token_expires_at': newExpiry.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('instagram_id', user.instagramId);
    } catch (e) {
      debugPrint('Token refresh failed: $e — user will need to re-login when it expires');
    }
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('instagram_id');
  }
}
