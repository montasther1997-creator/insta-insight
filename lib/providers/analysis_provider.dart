import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/gemini_service.dart';
import '../services/cache_service.dart';
import '../models/suggestion_model.dart';
import 'auth_provider.dart';
import 'instagram_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

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

  final bestPost = media.isNotEmpty
      ? media.reduce((a, b) => a.totalEngagement > b.totalEngagement ? a : b)
      : null;

  final gemini = ref.read(geminiServiceProvider);
  final result = await gemini.analyzeAccount(
    username: user.username,
    followers: user.followersCount,
    engagement: engagement,
    topCountry: topCountry,
    topCity: topCity,
    bestPostViews: bestPost?.viewsCount ?? 0,
    avgViews: media.isNotEmpty
        ? media.fold<int>(0, (sum, p) => sum + p.viewsCount) ~/ media.length
        : 0,
  );

  await cache.cacheGeminiResult(CacheService.keyGeminiAnalysis, result);
  return result;
});

/// Provider for content suggestions
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
  final media = ref.read(mediaProvider).valueOrNull ?? [];

  // Extract recent topics from captions
  final recentTopics = <String>[];
  for (final post in media.take(10)) {
    if (post.geminiAnalysis != null && post.geminiAnalysis!.isNotEmpty) {
      recentTopics.add(post.geminiAnalysis!);
    }
  }

  final gemini = ref.read(geminiServiceProvider);
  final suggestions = await gemini.generateSuggestions(
    username: user.username,
    followers: user.followersCount,
    topCountry: topCountry,
    recentTopics: recentTopics,
  );

  await cache.cacheGeminiResult(CacheService.keySuggestions, suggestions);
  return suggestions;
});

/// Provider for trending audio — fetches from Supabase, falls back to Gemini
final trendingAudioProvider = FutureProvider<List<TrendingAudio>>((ref) async {
  final cache = await CacheService.getInstance();
  final cached = cache.get(CacheService.keyTrendingAudio);
  if (cached != null) {
    return (cached as List<dynamic>)
        .map((e) => TrendingAudio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('trending_audio')
        .select()
        .order('growth_rate', ascending: false)
        .limit(20);

    final audioList = (response as List<dynamic>)
        .map((e) => TrendingAudio.fromJson(e as Map<String, dynamic>))
        .toList();

    if (audioList.isNotEmpty) {
      await cache.cacheInstagramData(
        CacheService.keyTrendingAudio,
        audioList.map((a) => a.toJson()).toList(),
      );
      return audioList;
    }
  } catch (e) {
    debugPrint('trendingAudioProvider Supabase error: $e');
  }

  // Fallback: generate trending audio suggestions via Gemini
  try {
    final topCountry = ref.read(topCountryProvider);
    final gemini = ref.read(geminiServiceProvider);
    final audioSuggestions = await gemini.suggestTrendingAudio(region: topCountry);

    if (audioSuggestions.isNotEmpty) {
      await cache.cacheInstagramData(CacheService.keyTrendingAudio, audioSuggestions.map((a) => a.toJson()).toList());
    }
    return audioSuggestions;
  } catch (e) {
    debugPrint('trendingAudioProvider Gemini fallback error: $e');
    return [];
  }
});
