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
    final rawMedia = await service.fetchUserMediaWithInsights(
      user.accessToken,
      igUserId: user.instagramId,
    );
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
/// Weighted by engagement so slot intensity = best PERFORMING time, not just most posted
final postingHeatmapProvider = Provider<Map<String, double>>((ref) {
  final posts = ref.watch(mediaProvider).valueOrNull ?? [];
  if (posts.isEmpty) return {};

  final engagementSum = <String, int>{};
  int maxEngagement = 0;

  for (final post in posts) {
    if (post.postedAt == null) continue;
    final weekday = (post.postedAt!.weekday + 1) % 7;
    final hour = post.postedAt!.hour;
    final key = '$weekday-$hour';
    final eng = post.totalEngagement.clamp(1, 1 << 30);
    engagementSum[key] = (engagementSum[key] ?? 0) + eng;
    if (engagementSum[key]! > maxEngagement) maxEngagement = engagementSum[key]!;
  }

  if (maxEngagement == 0) return {};

  final normalized = <String, double>{};
  for (final entry in engagementSum.entries) {
    normalized[entry.key] = entry.value / maxEngagement;
  }
  return normalized;
});

/// Best performing weekday (0=Saturday, 6=Friday)
final bestPostingDayProvider = Provider<Map<String, dynamic>>((ref) {
  final posts = ref.watch(mediaProvider).valueOrNull ?? [];
  if (posts.isEmpty) return {'day': 'غير محدد', 'engagement': 0};

  final engagementByDay = <int, int>{};
  final countByDay = <int, int>{};

  for (final post in posts) {
    if (post.postedAt == null) continue;
    final day = (post.postedAt!.weekday + 1) % 7;
    engagementByDay[day] = (engagementByDay[day] ?? 0) + post.totalEngagement;
    countByDay[day] = (countByDay[day] ?? 0) + 1;
  }

  if (engagementByDay.isEmpty) return {'day': 'غير محدد', 'engagement': 0};

  int bestDay = 0;
  double bestAvg = 0;
  engagementByDay.forEach((day, total) {
    final avg = total / (countByDay[day] ?? 1);
    if (avg > bestAvg) {
      bestAvg = avg;
      bestDay = day;
    }
  });

  const dayNames = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  return {'day': dayNames[bestDay], 'engagement': bestAvg.round()};
});

/// Best performing hour of day
final bestPostingHourProvider = Provider<Map<String, dynamic>>((ref) {
  final posts = ref.watch(mediaProvider).valueOrNull ?? [];
  if (posts.isEmpty) return {'hour': 'غير محدد', 'engagement': 0};

  final engByHour = <int, int>{};
  final countByHour = <int, int>{};

  for (final post in posts) {
    if (post.postedAt == null) continue;
    final hour = post.postedAt!.hour;
    engByHour[hour] = (engByHour[hour] ?? 0) + post.totalEngagement;
    countByHour[hour] = (countByHour[hour] ?? 0) + 1;
  }

  if (engByHour.isEmpty) return {'hour': 'غير محدد', 'engagement': 0};

  int bestHour = 0;
  double bestAvg = 0;
  engByHour.forEach((hour, total) {
    final avg = total / (countByHour[hour] ?? 1);
    if (avg > bestAvg) {
      bestAvg = avg;
      bestHour = hour;
    }
  });

  final display = bestHour == 0
      ? '12 ص'
      : bestHour < 12
          ? '$bestHour ص'
          : bestHour == 12
              ? '12 م'
              : '${bestHour - 12} م';
  return {'hour': display, 'engagement': bestAvg.round()};
});

/// Optimal posting frequency (posts per week average based on history)
final postingFrequencyProvider = Provider<double>((ref) {
  final posts = ref.watch(mediaProvider).valueOrNull ?? [];
  if (posts.length < 2) return 0;

  final sorted = [...posts]
    ..removeWhere((p) => p.postedAt == null)
    ..sort((a, b) => a.postedAt!.compareTo(b.postedAt!));

  if (sorted.length < 2) return 0;

  final span = sorted.last.postedAt!.difference(sorted.first.postedAt!);
  final weeks = span.inDays / 7.0;
  if (weeks <= 0) return sorted.length.toDouble();
  return sorted.length / weeks;
});

/// Top hashtags extracted from post captions, ranked by total engagement
/// earned across all posts that used the tag. Returns [{tag, count, engagement}].
final topHashtagsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final posts = ref.watch(mediaProvider).valueOrNull ?? [];
  if (posts.isEmpty) return [];

  final byTag = <String, Map<String, int>>{};
  for (final p in posts) {
    for (final tag in p.hashtags) {
      final key = tag.toLowerCase();
      final entry = byTag.putIfAbsent(key, () => {'count': 0, 'engagement': 0});
      entry['count'] = entry['count']! + 1;
      entry['engagement'] = entry['engagement']! + p.totalEngagement;
    }
  }

  final list = byTag.entries
      .map((e) => {
            'tag': e.key,
            'count': e.value['count']!,
            'engagement': e.value['engagement']!,
          })
      .toList()
    ..sort((a, b) => (b['engagement'] as int).compareTo(a['engagement'] as int));
  return list;
});

/// Media type distribution
final mediaTypeDistributionProvider = Provider<Map<String, Map<String, num>>>((ref) {
  final posts = ref.watch(mediaProvider).valueOrNull ?? [];
  if (posts.isEmpty) return {};

  final stats = <String, Map<String, num>>{
    'REELS': {'count': 0, 'engagement': 0, 'views': 0},
    'VIDEO': {'count': 0, 'engagement': 0, 'views': 0},
    'IMAGE': {'count': 0, 'engagement': 0, 'views': 0},
    'CAROUSEL_ALBUM': {'count': 0, 'engagement': 0, 'views': 0},
  };

  for (final p in posts) {
    final type = stats.containsKey(p.mediaType) ? p.mediaType : 'IMAGE';
    stats[type]!['count'] = (stats[type]!['count'] as int) + 1;
    stats[type]!['engagement'] = (stats[type]!['engagement'] as int) + p.totalEngagement;
    stats[type]!['views'] = (stats[type]!['views'] as int) + p.viewsCount;
  }

  stats.forEach((type, s) {
    final count = s['count'] as int;
    s['avg_engagement'] = count > 0 ? (s['engagement'] as int) / count : 0;
    s['avg_views'] = count > 0 ? (s['views'] as int) / count : 0;
  });

  return stats;
});
