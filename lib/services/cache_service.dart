import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static CacheService? _instance;
  late SharedPreferences _prefs;

  CacheService._();

  static Future<CacheService> getInstance() async {
    if (_instance == null) {
      _instance = CacheService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  /// Save data with expiration
  Future<void> save(String key, dynamic data, {Duration expiration = const Duration(hours: 6)}) async {
    final entry = {
      'data': data,
      'expires_at': DateTime.now().add(expiration).millisecondsSinceEpoch,
    };
    await _prefs.setString('cache_$key', jsonEncode(entry));
  }

  /// Get cached data (returns null if expired, unless allowExpired is true)
  dynamic get(String key, {bool allowExpired = false}) {
    final raw = _prefs.getString('cache_$key');
    if (raw == null) return null;

    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = entry['expires_at'] as int;
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        if (!allowExpired) {
          _prefs.remove('cache_$key');
          return null;
        }
        // Return expired data as offline fallback
        debugPrint('Cache expired for $key, returning stale data (offline fallback)');
      }
      return entry['data'];
    } catch (e) {
      debugPrint('Cache read error for $key: $e');
      return null;
    }
  }

  /// Check if cache exists and is valid
  bool has(String key) => get(key) != null;

  /// Check if any cached data exists (even expired) for offline use
  bool hasAny(String key) => _prefs.containsKey('cache_$key');

  /// Clear specific cache
  Future<void> clear(String key) async {
    await _prefs.remove('cache_$key');
  }

  /// Clear all cache
  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('cache_'));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  // Predefined cache keys
  static const String keyInstagramProfile = 'instagram_profile';
  static const String keyInstagramMedia = 'instagram_media';
  static const String keyGeminiAnalysis = 'gemini_analysis';
  static const String keyGeoData = 'geo_data';
  static const String keyTrendingAudio = 'trending_audio';
  static const String keySuggestions = 'suggestions';

  /// Cache Instagram data (6 hours)
  Future<void> cacheInstagramData(String key, dynamic data) async {
    await save(key, data, expiration: const Duration(hours: 6));
  }

  /// Cache Gemini results (24 hours)
  Future<void> cacheGeminiResult(String key, dynamic data) async {
    await save(key, data, expiration: const Duration(hours: 24));
  }
}
