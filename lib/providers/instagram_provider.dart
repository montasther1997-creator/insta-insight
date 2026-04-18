import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/instagram_service.dart';
import '../services/cache_service.dart';
import 'auth_provider.dart';

final instagramServiceProvider = Provider<InstagramService>((ref) => InstagramService());

/// Provider for user's media/posts
final mediaProvider = FutureProvider<List<PostModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];

  final cache = await CacheService.getInstance();
  final cached = cache.get(CacheService.keyInstagramMedia);
  if (cached != null) {
    return (cached as List<dynamic>)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  try {
    final service = ref.read(instagramServiceProvider);
    final rawMedia = await service.fetchUserMedia(user.accessToken, igUserId: user.instagramId);
    final posts = service.parseMediaToModels(rawMedia, user.id);

    await cache.cacheInstagramData(
      CacheService.keyInstagramMedia,
      posts.map((p) => p.toJson()).toList(),
    );

    return posts;
  } catch (e) {
    debugPrint('mediaProvider network error: $e');
    // Try expired cache as offline fallback
    final stale = cache.get(CacheService.keyInstagramMedia, allowExpired: true);
    if (stale != null) {
      return (stale as List<dynamic>)
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    rethrow;
  }
});

/// Provider for video posts only
final videoPostsProvider = Provider<AsyncValue<List<PostModel>>>((ref) {
  return ref.watch(mediaProvider).whenData(
    (posts) => posts.where((p) => p.isVideo).toList()
      ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount)),
  );
});

/// Provider for engagement rate
final engagementRateProvider = Provider<double>((ref) {
  final authState = ref.watch(authStateProvider);
  final mediaState = ref.watch(mediaProvider);

  final user = authState.valueOrNull;
  final posts = mediaState.valueOrNull;

  if (user == null || posts == null || posts.isEmpty) return 0.0;
  if (user.followersCount == 0) return 0.0;

  final totalEngagement = posts.fold<int>(
    0,
    (sum, post) => sum + post.totalEngagement,
  );

  return (totalEngagement / posts.length / user.followersCount) * 100;
});

/// Provider for geo data
final geoDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return {};

  final cache = await CacheService.getInstance();
  final cached = cache.get(CacheService.keyGeoData);
  if (cached != null) return cached as Map<String, dynamic>;

  final service = ref.read(instagramServiceProvider);
  final data = await service.fetchAccountInsights(user.instagramId, user.accessToken);

  await cache.cacheInstagramData(CacheService.keyGeoData, data);
  return data;
});

/// Provider for weekly followers growth
final weeklyGrowthProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return 0;

  final service = ref.read(instagramServiceProvider);
  final data = await service.fetchFollowersOverTime(
    user.instagramId,
    user.accessToken,
    days: 7,
  );

  if (data.length < 2) return 0;

  final firstValue = data.first['value'] as int? ?? 0;
  final lastValue = data.last['value'] as int? ?? 0;
  return lastValue - firstValue;
});

/// Provider for followers over time (30 days)
final followersOverTimeProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];

  final service = ref.read(instagramServiceProvider);
  return service.fetchFollowersOverTime(
    user.instagramId,
    user.accessToken,
    days: 30,
  );
});

/// Provider for top country from geo data
final topCountryProvider = Provider<String>((ref) {
  final geoData = ref.watch(geoDataProvider).valueOrNull;
  if (geoData == null || geoData.isEmpty) return 'غير محدد';

  final demographics = geoData['follower_demographics'];
  if (demographics == null) return 'غير محدد';

  try {
    final breakdowns = demographics as List<dynamic>;
    for (final breakdown in breakdowns) {
      final dimension = breakdown['dimension_key'] as String?;
      if (dimension == 'country') {
        final results = breakdown['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          results.sort((a, b) =>
              (b['value'] as int).compareTo(a['value'] as int));
          return results.first['dimension_values']['value'] as String? ?? 'غير محدد';
        }
      }
    }
  } catch (e) {
    debugPrint('topCountryProvider error: $e');
  }
  return 'غير محدد';
});

/// Provider for top city from geo data
final topCityProvider = Provider<String>((ref) {
  final geoData = ref.watch(geoDataProvider).valueOrNull;
  if (geoData == null || geoData.isEmpty) return 'غير محدد';

  final demographics = geoData['follower_demographics'];
  if (demographics == null) return 'غير محدد';

  try {
    final breakdowns = demographics as List<dynamic>;
    for (final breakdown in breakdowns) {
      final dimension = breakdown['dimension_key'] as String?;
      if (dimension == 'city') {
        final results = breakdown['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          results.sort((a, b) =>
              (b['value'] as int).compareTo(a['value'] as int));
          return results.first['dimension_values']['value'] as String? ?? 'غير محدد';
        }
      }
    }
  } catch (e) {
    debugPrint('topCityProvider error: $e');
  }
  return 'غير محدد';
});

/// Parsed geo entries for display (countries)
final geoCountriesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final geoData = ref.watch(geoDataProvider).valueOrNull;
  if (geoData == null || geoData.isEmpty) return [];

  final demographics = geoData['follower_demographics'];
  if (demographics == null) return [];

  try {
    final breakdowns = demographics as List<dynamic>;
    for (final breakdown in breakdowns) {
      final dimension = breakdown['dimension_key'] as String?;
      if (dimension == 'country') {
        final results = breakdown['results'] as List<dynamic>;
        final total = results.fold<int>(0, (sum, r) => sum + (r['value'] as int));
        if (total == 0) return [];

        final entries = results.map((r) {
          final value = r['value'] as int;
          final name = r['dimension_values']['value'] as String? ?? '?';
          return {
            'name': name,
            'percentage': (value / total * 100),
          };
        }).toList();
        entries.sort((a, b) =>
            (b['percentage'] as double).compareTo(a['percentage'] as double));
        return entries.cast<Map<String, dynamic>>();
      }
    }
  } catch (e) {
    debugPrint('geoCountriesProvider error: $e');
  }
  return [];
});

/// Parsed geo entries for display (cities)
final geoCitiesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final geoData = ref.watch(geoDataProvider).valueOrNull;
  if (geoData == null || geoData.isEmpty) return [];

  final demographics = geoData['follower_demographics'];
  if (demographics == null) return [];

  try {
    final breakdowns = demographics as List<dynamic>;
    for (final breakdown in breakdowns) {
      final dimension = breakdown['dimension_key'] as String?;
      if (dimension == 'city') {
        final results = breakdown['results'] as List<dynamic>;
        final total = results.fold<int>(0, (sum, r) => sum + (r['value'] as int));
        if (total == 0) return [];

        final entries = results.map((r) {
          final value = r['value'] as int;
          final name = r['dimension_values']['value'] as String? ?? '?';
          return {
            'name': name,
            'percentage': (value / total * 100),
          };
        }).toList();
        entries.sort((a, b) =>
            (b['percentage'] as double).compareTo(a['percentage'] as double));
        return entries.cast<Map<String, dynamic>>();
      }
    }
  } catch (e) {
    debugPrint('geoCitiesProvider error: $e');
  }
  return [];
});

/// Provider for posting heatmap data based on actual post timestamps
final postingHeatmapProvider = Provider<Map<String, double>>((ref) {
  final posts = ref.watch(mediaProvider).valueOrNull ?? [];
  if (posts.isEmpty) return {};

  // Count posts per day-hour slot
  final counts = <String, int>{};
  int maxCount = 0;

  for (final post in posts) {
    if (post.postedAt == null) continue;
    // Convert to Saturday-based week (0=Saturday)
    final weekday = (post.postedAt!.weekday + 1) % 7;
    final hour = post.postedAt!.hour;
    final key = '$weekday-$hour';
    counts[key] = (counts[key] ?? 0) + 1;
    if (counts[key]! > maxCount) maxCount = counts[key]!;
  }

  if (maxCount == 0) return {};

  // Normalize to 0.0-1.0 range
  final normalized = <String, double>{};
  for (final entry in counts.entries) {
    normalized[entry.key] = entry.value / maxCount;
  }
  return normalized;
});
