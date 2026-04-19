import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service.dart';
import '../services/cache_service.dart';
import '../models/suggestion_model.dart';
import 'auth_provider.dart';
import 'instagram_provider.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

/// Backwards-compat alias; kept so older code compiles while we migrate.
final geminiServiceProvider = aiServiceProvider;

/// Provider for AI analysis results
final aiAnalysisProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return {};

  final cache = await CacheService.getInstance();
  final cached = cache.get(CacheService.keyGeminiAnalysis);
  if (cached != null) return cached as Map<String, dynamic>;

  final engagement = ref.read(engagementRateProvider);
  final media = ref.read(mediaProvider).valueOrNull ?? [];
  final topCountry = ref.read(topCountryProvider);
  final topCity = ref.read(topCityProvider);
  final monthlyGrowth = ref.read(monthlyGrowthRateProvider);

  final country = (topCountry == 'غير محدد' || topCountry.isEmpty) ? 'غير متوفر' : topCountry;
  final city = (topCity == 'غير محدد' || topCity.isEmpty) ? 'غير متوفر' : topCity;

  final bestPost = media.isNotEmpty
      ? media.reduce((a, b) => a.totalEngagement > b.totalEngagement ? a : b)
      : null;

  final videoCount = media.where((p) => p.isVideo).length;
  final photoCount = media.where((p) => p.mediaType == 'IMAGE').length;
  final carouselCount = media.where((p) => p.mediaType == 'CAROUSEL_ALBUM').length;

  final gemini = ref.read(aiServiceProvider);
  try {
    final result = await gemini.analyzeAccount(
      username: user.username,
      followers: user.followersCount,
      engagement: engagement,
      topCountry: country,
      topCity: city,
      bestPostViews: bestPost?.viewsCount ?? 0,
      avgViews: media.isNotEmpty
          ? media.fold<int>(0, (sum, p) => sum + p.viewsCount) ~/ media.length
          : 0,
      totalPosts: media.length,
      videoPosts: videoCount,
      photoPosts: photoCount,
      carouselPosts: carouselCount,
      monthlyGrowth: monthlyGrowth,
    );
    if (result.isNotEmpty) {
      await cache.cacheGeminiResult(CacheService.keyGeminiAnalysis, result);
    }
    return result;
  } catch (e) {
    debugPrint('aiAnalysisProvider error: $e');
    return {};
  }
});

/// Provider for content suggestions (30 ideas)
final suggestionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];

  final cache = await CacheService.getInstance();
  final cached = cache.get(CacheService.keySuggestions);
  if (cached != null) {
    return (cached as List<dynamic>).cast<Map<String, dynamic>>();
  }

  final topCountry = ref.read(topCountryProvider);
  final suggestionsCountry = (topCountry == 'غير محدد' || topCountry.isEmpty) ? 'العراق' : topCountry;
  final media = ref.read(mediaProvider).valueOrNull ?? [];
  final aiAnalysis = ref.read(aiAnalysisProvider).valueOrNull ?? {};
  final niche = (aiAnalysis['niche'] as String?) ?? 'عام';

  final recentTopics = <String>[];
  for (final post in media.take(10)) {
    if (post.geminiAnalysis != null && post.geminiAnalysis!.isNotEmpty) {
      recentTopics.add(post.geminiAnalysis!);
    }
  }
  if (recentTopics.isEmpty) {
    recentTopics.add('محتوى عام');
  }

  final gemini = ref.read(aiServiceProvider);
  try {
    final suggestions = await gemini.generateSuggestions(
      username: user.username,
      followers: user.followersCount,
      topCountry: suggestionsCountry,
      recentTopics: recentTopics,
      niche: niche,
    );
    if (suggestions.isNotEmpty) {
      await cache.cacheGeminiResult(CacheService.keySuggestions, suggestions);
    }
    return suggestions;
  } catch (e) {
    debugPrint('suggestionsProvider error: $e');
    return [];
  }
});

/// Provider for trending audio — reads the live TikTok-sourced snapshot that
/// the Supabase Edge Function `fetch-trending-audio` refreshes every 12h.
/// When the snapshot is thin (IQ feed often filters to <10 non-original
/// tracks) we top it up with Gemini suggestions so the screen never shows
/// an anemic 5-track list.
final trendingAudioProvider = FutureProvider<List<TrendingAudio>>((ref) async {
  final cache = await CacheService.getInstance();
  final cached = cache.get(CacheService.keyTrendingAudio);
  if (cached != null) {
    final list = (cached as List<dynamic>)
        .map((e) => TrendingAudio.fromJson(e as Map<String, dynamic>))
        .toList();
    // Only serve cache if it already has enough tracks; otherwise re-fetch so
    // thin snapshots from a previous failed Gemini call don't linger.
    if (list.length >= 15) return list;
  }

  final merged = <String, TrendingAudio>{};

  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('trending_audio')
        .select()
        .order('usage_count', ascending: false)
        .order('updated_at', ascending: false)
        .limit(20);

    for (final e in response as List<dynamic>) {
      final audio = TrendingAudio.fromJson(e as Map<String, dynamic>);
      merged[audio.id] = audio;
    }
  } catch (e) {
    debugPrint('trendingAudioProvider supabase error: $e');
  }

  // Supplement with Gemini across multiple regions until we reach ~20 tracks.
  // The RapidAPI edge-fn cron is best-effort — if it hasn't populated recently
  // we fall back to Gemini so the UI is never thin.
  if (merged.length < 18) {
    final ai = ref.read(aiServiceProvider);
    for (final region in const ['IQ', 'SA', 'US']) {
      if (merged.length >= 20) break;
      try {
        final supplement = await ai.suggestTrendingAudio(region: region);
        for (final a in supplement) {
          merged.putIfAbsent(a.id, () => a);
          if (merged.length >= 20) break;
        }
      } catch (e) {
        debugPrint('trendingAudioProvider gemini $region error: $e');
      }
    }
  }

  final audioList = merged.values.toList()
    ..sort((a, b) => b.usageCount.compareTo(a.usageCount));

  if (audioList.isNotEmpty) {
    await cache.cacheInstagramData(
      CacheService.keyTrendingAudio,
      audioList.map((a) => a.toJson()).toList(),
    );
  }
  return audioList;
});

/// Provider for video performance analysis
final videoAnalysisProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final media = ref.watch(mediaProvider).valueOrNull ?? [];
  final videos = media.where((p) => p.isVideo).toList()
    ..sort((a, b) => b.totalEngagement.compareTo(a.totalEngagement));

  if (videos.isEmpty) return {};

  final cache = await CacheService.getInstance();
  final cached = cache.get(CacheService.keyVideoAnalysis);
  if (cached != null) return cached as Map<String, dynamic>;

  final topVideos = videos.take(5).map((v) => {
    'likes': v.likesCount,
    'comments': v.commentsCount,
    'views': v.viewsCount,
    'type': v.mediaType,
  }).toList();

  final avgEngagement = videos.isNotEmpty
      ? videos.fold<double>(0, (sum, v) => sum + v.engagementRate) / videos.length
      : 0.0;

  final gemini = ref.read(aiServiceProvider);
  try {
    final result = await gemini.analyzeVideoPerformance(
      topVideos: topVideos,
      totalVideos: videos.length,
      avgEngagement: avgEngagement,
    );
    if (result.isNotEmpty) {
      await cache.cacheGeminiResult(CacheService.keyVideoAnalysis, result);
    }
    return result;
  } catch (e) {
    debugPrint('videoAnalysisProvider error: $e');
    return {};
  }
});

/// Provider for weekly content plan
final weeklyPlanProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return {};

  final cache = await CacheService.getInstance();
  final cached = cache.get(CacheService.keyWeeklyPlan);
  if (cached != null) return cached as Map<String, dynamic>;

  final topCountry = ref.read(topCountryProvider);
  final country = (topCountry == 'غير محدد' || topCountry.isEmpty) ? 'العراق' : topCountry;
  final aiAnalysis = ref.read(aiAnalysisProvider).valueOrNull ?? {};
  final niche = (aiAnalysis['niche'] as String?) ?? 'عام';
  final bestTime = (aiAnalysis['best_post_time'] as String?) ?? '8 مساءً';

  final gemini = ref.read(aiServiceProvider);
  try {
    final result = await gemini.generateWeeklyPlan(
      username: user.username,
      niche: niche,
      topCountry: country,
      bestPostTime: bestTime,
    );
    if (result.isNotEmpty) {
      await cache.cacheGeminiResult(CacheService.keyWeeklyPlan, result);
    }
    return result;
  } catch (e) {
    debugPrint('weeklyPlanProvider error: $e');
    return {};
  }
});

/// Provider for monthly growth rate (calculated from followers over time)
final monthlyGrowthRateProvider = Provider<double>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  final followersData = ref.watch(followersOverTimeProvider).valueOrNull ?? [];

  if (user == null || user.followersCount == 0) return 0.0;
  if (followersData.length < 2) return 0.0;

  final firstValue = followersData.first['value'] as int? ?? user.followersCount;
  final lastValue = followersData.last['value'] as int? ?? user.followersCount;
  if (firstValue == 0) return 0.0;

  return ((lastValue - firstValue) / firstValue) * 100;
});

/// Provider for weekly report
final weeklyReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return {};

  final cache = await CacheService.getInstance();
  final cached = cache.get(CacheService.keyWeeklyReport);
  if (cached != null) return cached as Map<String, dynamic>;

  final media = ref.read(mediaProvider).valueOrNull ?? [];
  final engagement = ref.read(engagementRateProvider);
  final weeklyGrowth = ref.read(weeklyGrowthProvider).valueOrNull ?? 0;
  final monthlyGrowth = ref.read(monthlyGrowthRateProvider);

  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final weekPosts = media.where((p) =>
      p.postedAt != null && p.postedAt!.isAfter(weekAgo)).toList();

  final weeklyData = {
    'followers': user.followersCount,
    'weekly_growth': weeklyGrowth,
    'monthly_growth_percent': monthlyGrowth,
    'engagement_rate': engagement,
    'posts_this_week': weekPosts.length,
    'total_likes_this_week': weekPosts.fold<int>(0, (s, p) => s + p.likesCount),
    'total_comments_this_week': weekPosts.fold<int>(0, (s, p) => s + p.commentsCount),
  };

  final gemini = ref.read(aiServiceProvider);
  try {
    final result = await gemini.generateWeeklyReport(
      username: user.username,
      weeklyData: weeklyData,
    );
    if (result.isNotEmpty) {
      await cache.cacheGeminiResult(CacheService.keyWeeklyReport, result);
    }
    return result;
  } catch (e) {
    debugPrint('weeklyReportProvider error: $e');
    return {};
  }
});
