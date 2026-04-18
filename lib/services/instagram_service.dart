import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/instagram_config.dart';
import '../models/post_model.dart';

class InstagramService {
  final Dio _dio = Dio();

  /// Fetch user's media (posts/reels) via Instagram Graph API
  Future<List<Map<String, dynamic>>> fetchUserMedia(String accessToken, {String? igUserId, int limit = 50}) async {
    final endpoint = igUserId != null
        ? '${InstagramConfig.graphUrl}/$igUserId/media'
        : '${InstagramConfig.graphUrl}/me/media';

    final response = await _dio.get(
      endpoint,
      queryParameters: {
        'fields': 'id,caption,media_type,media_url,thumbnail_url,timestamp,like_count,comments_count',
        'limit': limit,
        'access_token': accessToken,
      },
    );

    final data = response.data['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// Fetch insights for a specific media
  Future<Map<String, dynamic>> fetchMediaInsights(
    String mediaId,
    String accessToken, {
    required String mediaType,
  }) async {
    final metrics = mediaType == 'VIDEO' || mediaType == 'REELS'
        ? 'plays,reach,total_interactions'
        : 'reach,impressions,total_interactions';

    try {
      final response = await _dio.get(
        '${InstagramConfig.graphUrl}/$mediaId/insights',
        queryParameters: {
          'metric': metrics,
          'access_token': accessToken,
        },
      );

      final insightsData = response.data['data'] as List<dynamic>;
      final result = <String, dynamic>{};
      for (final insight in insightsData) {
        final name = insight['name'] as String;
        final values = insight['values'] as List<dynamic>;
        if (values.isNotEmpty) {
          result[name] = values[0]['value'];
        }
      }
      return result;
    } catch (e) {
      debugPrint('fetchMediaInsights error for $mediaId: $e');
      return {};
    }
  }

  /// Fetch user's account insights (followers demographics)
  Future<Map<String, dynamic>> fetchAccountInsights(
    String igUserId,
    String accessToken,
  ) async {
    try {
      final response = await _dio.get(
        '${InstagramConfig.graphUrl}/$igUserId/insights',
        queryParameters: {
          'metric': 'follower_demographics',
          'period': 'lifetime',
          'metric_type': 'total_value',
          'timeframe': 'this_month',
          'access_token': accessToken,
        },
      );

      final data = response.data['data'] as List<dynamic>;
      final result = <String, dynamic>{};
      for (final metric in data) {
        result[metric['name'] as String] = metric['total_value']?['breakdowns'];
      }
      return result;
    } catch (e) {
      debugPrint('fetchAccountInsights error: $e');
      return {};
    }
  }

  /// Fetch followers count over time
  Future<List<Map<String, dynamic>>> fetchFollowersOverTime(
    String igUserId,
    String accessToken, {
    int days = 30,
  }) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final until = DateTime.now();

      final response = await _dio.get(
        '${InstagramConfig.graphUrl}/$igUserId/insights',
        queryParameters: {
          'metric': 'follower_count',
          'period': 'day',
          'since': since.millisecondsSinceEpoch ~/ 1000,
          'until': until.millisecondsSinceEpoch ~/ 1000,
          'access_token': accessToken,
        },
      );

      final data = response.data['data'] as List<dynamic>;
      if (data.isNotEmpty) {
        final values = data[0]['values'] as List<dynamic>;
        return values.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('fetchFollowersOverTime error: $e');
      return [];
    }
  }

  /// Parse raw media data into PostModel list
  List<PostModel> parseMediaToModels(
    List<Map<String, dynamic>> mediaList,
    String userId,
  ) {
    return mediaList.map((media) {
      return PostModel(
        id: '',
        userId: userId,
        postId: media['id'] as String,
        mediaType: media['media_type'] as String? ?? 'IMAGE',
        thumbnailUrl: (media['thumbnail_url'] ?? media['media_url'] ?? '') as String,
        likesCount: media['like_count'] as int? ?? 0,
        commentsCount: media['comments_count'] as int? ?? 0,
        postedAt: media['timestamp'] != null
            ? DateTime.parse(media['timestamp'] as String)
            : null,
        analyzedAt: DateTime.now(),
      );
    }).toList();
  }
}
