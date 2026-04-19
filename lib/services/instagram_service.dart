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
        'fields': 'id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,like_count,comments_count',
        'limit': limit,
        'access_token': accessToken,
      },
    );

    final data = response.data['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// Fetch insights for a specific media — returns views/reach/shares/saves when available.
  ///
  /// Instagram renamed `plays`/`video_views` → `views` in 2024 (Graph API v21+).
  /// Older Business accounts may still only respond to `plays`. We try the
  /// modern metric set first and fall back progressively so the caller always
  /// gets whatever data the account supports.
  Future<Map<String, dynamic>> fetchMediaInsights(
    String mediaId,
    String accessToken, {
    required String mediaType,
  }) async {
    final isVideo = mediaType == 'VIDEO' || mediaType == 'REELS';

    // Try each metric set in order; the first that succeeds wins.
    final attempts = <String>[
      if (isVideo) 'views,reach,shares,saved,total_interactions',
      if (isVideo) 'plays,reach,shares,saved,total_interactions',
      'views,reach,shares,saved,total_interactions',
      'reach,shares,saved,total_interactions',
      'reach,shares,saved',
      'reach',
    ];

    for (final metrics in attempts) {
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
        if (result.isNotEmpty) return result;
      } catch (e) {
        debugPrint(
            'fetchMediaInsights attempt failed for $mediaId ($metrics): $e');
      }
    }
    return {};
  }

  /// Fetch media list and enrich each item with insights (views, shares, saves).
  /// Runs insights in parallel to keep the total request time short.
  Future<List<Map<String, dynamic>>> fetchUserMediaWithInsights(
    String accessToken, {
    String? igUserId,
    int limit = 50,
  }) async {
    final media = await fetchUserMedia(accessToken, igUserId: igUserId, limit: limit);
    final futures = media.map((m) async {
      final type = m['media_type'] as String? ?? 'IMAGE';
      final id = m['id'] as String?;
      if (id == null) return m;
      final insights = await fetchMediaInsights(id, accessToken, mediaType: type);
      return {...m, '_insights': insights};
    });
    return Future.wait(futures);
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

  /// Parse raw media data into PostModel list.
  /// Items enriched by `fetchUserMediaWithInsights` carry an `_insights` map
  /// with views/shares/saves from the Graph API; when absent we keep zeros.
  List<PostModel> parseMediaToModels(
    List<Map<String, dynamic>> mediaList,
    String userId,
  ) {
    return mediaList.map((media) {
      final insights = (media['_insights'] as Map<String, dynamic>?) ?? const {};
      // Instagram renamed `plays` → `views` in 2024. Accept either; fall back
      // to `reach` (unique viewers) so we never falsely report 0 views.
      final plays = (insights['views'] as num?)?.toInt() ??
          (insights['plays'] as num?)?.toInt() ??
          (insights['reach'] as num?)?.toInt() ??
          0;
      final shares = (insights['shares'] as num?)?.toInt() ?? 0;
      final saved = (insights['saved'] as num?)?.toInt() ?? 0;
      final likes = media['like_count'] as int? ?? 0;
      final comments = media['comments_count'] as int? ?? 0;
      // Engagement rate: interactions / reach-or-views, expressed as percent.
      // Falls back to 0 when the API didn't return a denominator so we don't
      // divide by zero or invent a rate.
      final totalEng = likes + comments + shares + saved;
      final engagementRate =
          plays > 0 ? (totalEng / plays) * 100.0 : 0.0;
      return PostModel(
        id: '',
        userId: userId,
        postId: media['id'] as String,
        mediaType: media['media_type'] as String? ?? 'IMAGE',
        thumbnailUrl: (media['thumbnail_url'] ?? media['media_url'] ?? '') as String,
        mediaUrl: (media['media_url'] as String?) ?? '',
        caption: (media['caption'] as String?) ?? '',
        permalink: (media['permalink'] as String?) ?? '',
        viewsCount: plays,
        likesCount: likes,
        commentsCount: comments,
        sharesCount: shares,
        savesCount: saved,
        engagementRate: engagementRate,
        postedAt: media['timestamp'] != null
            ? DateTime.parse(media['timestamp'] as String)
            : null,
        analyzedAt: DateTime.now(),
      );
    }).toList();
  }
}
