import 'package:flutter/foundation.dart';
import '../config/gemini_config.dart';
import '../models/suggestion_model.dart';
import 'claude_service.dart';
import 'gemini_service.dart';

/// Unified AI layer: Gemini first (free quota), Claude as fallback.
/// If both providers fail, returns a useful local fallback instead of crashing.
class AIService {
  final GeminiService _gemini = GeminiService();
  final ClaudeService _claude = ClaudeService();

  String lastProviderUsed = 'none';
  String? lastError;

  Future<Map<String, dynamic>> analyzeAccount({
    required String username,
    required int followers,
    required double engagement,
    required String topCountry,
    required String topCity,
    required int bestPostViews,
    required int avgViews,
    int totalPosts = 0,
    int videoPosts = 0,
    int photoPosts = 0,
    int carouselPosts = 0,
    double monthlyGrowth = 0.0,
    int totalLikes = 0,
    int totalComments = 0,
  }) async {
    Object? geminiErr;
    if (GeminiConfig.hasApiKey) {
      try {
        final r = await _gemini.analyzeAccount(
          username: username,
          followers: followers,
          engagement: engagement,
          topCountry: topCountry,
          topCity: topCity,
          bestPostViews: bestPostViews,
          avgViews: avgViews,
          totalPosts: totalPosts,
          videoPosts: videoPosts,
          photoPosts: photoPosts,
          carouselPosts: carouselPosts,
          monthlyGrowth: monthlyGrowth,
        );
        if (r.isNotEmpty) {
          lastProviderUsed = 'gemini';
          lastError = null;
          return r;
        }
      } catch (e) {
        geminiErr = e;
        debugPrint('AIService gemini failed: $e');
      }
    }
    if (ClaudeConfig.hasApiKey) {
      try {
        final r = await _claude.analyzeAccount(
          username: username,
          followers: followers,
          engagement: engagement,
          topCountry: topCountry,
          topCity: topCity,
          bestPostViews: bestPostViews,
          avgViews: avgViews,
          totalPosts: totalPosts,
          videoPosts: videoPosts,
          photoPosts: photoPosts,
          carouselPosts: carouselPosts,
          monthlyGrowth: monthlyGrowth,
          totalLikes: totalLikes,
          totalComments: totalComments,
        );
        if (r.isNotEmpty) {
          lastProviderUsed = 'claude';
          lastError = null;
          return r;
        }
      } catch (e) {
        debugPrint('AIService claude failed: $e');
        lastError = 'Gemini: $geminiErr | Claude: $e';
      }
    } else {
      lastError = 'Gemini: $geminiErr';
    }
    lastProviderUsed = 'local';
    return _localFallback(
      username: username,
      followers: followers,
      engagement: engagement,
      topCountry: topCountry,
      avgViews: avgViews,
      totalPosts: totalPosts,
    );
  }

  Future<String> analyzePost({
    required String mediaType,
    required int likes,
    required int comments,
    required int views,
    required double engagementRate,
    required String caption,
  }) async {
    if (GeminiConfig.hasApiKey) {
      try {
        final r = await _gemini.analyzePost(
          mediaType: mediaType,
          likes: likes,
          comments: comments,
          views: views,
          engagementRate: engagementRate,
          caption: caption,
        );
        if (r.isNotEmpty && r != 'لا يتوفر تحليل') {
          lastProviderUsed = 'gemini';
          return r;
        }
      } catch (e) {
        debugPrint('AIService.analyzePost gemini failed: $e');
      }
    }
    if (ClaudeConfig.hasApiKey) {
      try {
        final r = await _claude.analyzePost(
          mediaType: mediaType,
          likes: likes,
          comments: comments,
          views: views,
          engagementRate: engagementRate,
          caption: caption,
        );
        lastProviderUsed = 'claude';
        return r;
      } catch (e) {
        debugPrint('AIService.analyzePost claude failed: $e');
      }
    }
    return engagementRate > 3
        ? 'أداء قوي — الجمهور تفاعل بشكل جيد مع هذا المحتوى.'
        : 'أداء ضعيف نسبياً — جرّب تغيير الهوك أو التوقيت.';
  }

  Future<List<Map<String, dynamic>>> generateSuggestions({
    required String username,
    required int followers,
    required String topCountry,
    required List<String> recentTopics,
    String niche = 'عام',
  }) async {
    if (GeminiConfig.hasApiKey) {
      try {
        final r = await _gemini.generateSuggestions(
          username: username,
          followers: followers,
          topCountry: topCountry,
          recentTopics: recentTopics,
          niche: niche,
        );
        if (r.isNotEmpty) {
          lastProviderUsed = 'gemini';
          return r;
        }
      } catch (e) {
        debugPrint('AIService.generateSuggestions gemini failed: $e');
      }
    }
    if (ClaudeConfig.hasApiKey) {
      try {
        final r = await _claude.generateSuggestions(
          username: username,
          followers: followers,
          topCountry: topCountry,
          recentTopics: recentTopics,
          niche: niche,
        );
        lastProviderUsed = 'claude';
        return r;
      } catch (e) {
        debugPrint('AIService.generateSuggestions claude failed: $e');
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> analyzeVideoPerformance({
    required List<Map<String, dynamic>> topVideos,
    required int totalVideos,
    required double avgEngagement,
  }) async {
    if (GeminiConfig.hasApiKey) {
      try {
        final r = await _gemini.analyzeVideoPerformance(
          topVideos: topVideos,
          totalVideos: totalVideos,
          avgEngagement: avgEngagement,
        );
        if (r.isNotEmpty) {
          lastProviderUsed = 'gemini';
          return r;
        }
      } catch (e) {
        debugPrint('AIService.analyzeVideoPerformance gemini failed: $e');
      }
    }
    if (ClaudeConfig.hasApiKey) {
      try {
        final r = await _claude.analyzeVideoPerformance(
          topVideos: topVideos,
          totalVideos: totalVideos,
          avgEngagement: avgEngagement,
        );
        lastProviderUsed = 'claude';
        return r;
      } catch (e) {
        debugPrint('AIService.analyzeVideoPerformance claude failed: $e');
      }
    }
    return {};
  }

  Future<Map<String, dynamic>> generateWeeklyPlan({
    required String username,
    required String niche,
    required String topCountry,
    required String bestPostTime,
  }) async {
    if (GeminiConfig.hasApiKey) {
      try {
        final r = await _gemini.generateWeeklyPlan(
          username: username,
          niche: niche,
          topCountry: topCountry,
          bestPostTime: bestPostTime,
        );
        if (r.isNotEmpty) {
          lastProviderUsed = 'gemini';
          return r;
        }
      } catch (e) {
        debugPrint('AIService.generateWeeklyPlan gemini failed: $e');
      }
    }
    if (ClaudeConfig.hasApiKey) {
      try {
        final r = await _claude.generateWeeklyPlan(
          username: username,
          niche: niche,
          topCountry: topCountry,
          bestPostTime: bestPostTime,
        );
        lastProviderUsed = 'claude';
        return r;
      } catch (e) {
        debugPrint('AIService.generateWeeklyPlan claude failed: $e');
      }
    }
    return {};
  }

  Future<Map<String, dynamic>> generateCaption({
    required String postIdea,
    required String niche,
    required String tone,
  }) async {
    if (GeminiConfig.hasApiKey) {
      try {
        final r = await _gemini.generateCaption(
          postIdea: postIdea,
          niche: niche,
          tone: tone,
        );
        if (r.isNotEmpty) {
          lastProviderUsed = 'gemini';
          return r;
        }
      } catch (e) {
        debugPrint('AIService.generateCaption gemini failed: $e');
      }
    }
    if (ClaudeConfig.hasApiKey) {
      try {
        final r = await _claude.generateCaption(
          postIdea: postIdea,
          niche: niche,
          tone: tone,
        );
        lastProviderUsed = 'claude';
        return r;
      } catch (e) {
        debugPrint('AIService.generateCaption claude failed: $e');
      }
    }
    return {};
  }

  Future<Map<String, dynamic>> generateWeeklyReport({
    required String username,
    required Map<String, dynamic> weeklyData,
  }) async {
    if (GeminiConfig.hasApiKey) {
      try {
        final r = await _gemini.generateWeeklyReport(
          username: username,
          weeklyData: weeklyData,
        );
        if (r.isNotEmpty) {
          lastProviderUsed = 'gemini';
          return r;
        }
      } catch (e) {
        debugPrint('AIService.generateWeeklyReport gemini failed: $e');
      }
    }
    return {};
  }

  Future<List<TrendingAudio>> suggestTrendingAudio({
    required String region,
  }) async {
    if (GeminiConfig.hasApiKey) {
      try {
        final r = await _gemini.suggestTrendingAudio(region: region);
        if (r.isNotEmpty) {
          lastProviderUsed = 'gemini';
          return r;
        }
      } catch (e) {
        debugPrint('AIService.suggestTrendingAudio gemini failed: $e');
      }
    }
    return [];
  }

  /// Claude-only: granular score breakdown for the detail screen.
  Future<Map<String, dynamic>> scoreBreakdown({
    required String username,
    required double currentScore,
    required Map<String, dynamic> metrics,
  }) async {
    if (ClaudeConfig.hasApiKey) {
      try {
        final r = await _claude.generateScoreBreakdown(
          username: username,
          currentScore: currentScore,
          metrics: metrics,
        );
        lastProviderUsed = 'claude';
        return r;
      } catch (e) {
        debugPrint('AIService.scoreBreakdown claude failed: $e');
        lastError = '$e';
      }
    }
    return {};
  }

  /// Deterministic local fallback so the UI never shows empty data.
  Map<String, dynamic> _localFallback({
    required String username,
    required int followers,
    required double engagement,
    required String topCountry,
    required int avgViews,
    required int totalPosts,
  }) {
    double score = 5;
    if (engagement >= 6) {
      score = 8.5;
    } else if (engagement >= 3) {
      score = 7;
    } else if (engagement >= 1.5) {
      score = 5.5;
    } else {
      score = 4;
    }
    if (followers > 10000) score += 0.5;
    if (totalPosts > 30) score += 0.3;
    if (score > 10) score = 10;
    return {
      'score': double.parse(score.toStringAsFixed(1)),
      'score_breakdown': {
        'content_quality': score,
        'engagement_health': (engagement * 1.5).clamp(0, 10),
        'consistency': totalPosts > 20 ? 7.5 : 5,
        'growth_momentum': 6,
        'audience_fit': 7,
      },
      'percentile_vs_niche': 60,
      'summary':
          'حسابك في نمو صحي. معدل التفاعل الحالي ${engagement.toStringAsFixed(1)}% — استمر في النشر بانتظام وركز على أوقات الذروة.',
      'niche': 'عام',
      'strengths': const [
        'نشاط مستمر على المنصة',
        'جمهور متفاعل نسبياً',
        'تنوع في المحتوى',
      ],
      'weaknesses': const [
        'قلة استخدام الريلز',
        'توقيت النشر غير مثالي',
        'قلة التفاعل في التعليقات',
      ],
      'best_post_time': '8 مساءً',
      'alert': 'للحصول على تحليل ذكاء اصطناعي كامل، تحقق من اتصال الإنترنت أو مفاتيح API.',
      'hook_tips': const [
        'ابدأ بسؤال مثير للاهتمام',
        'اعرض النتيجة في البداية',
        'استخدم صوت مفاجئ',
      ],
      'retention_tips': const [
        'حافظ على الإيقاع السريع',
        'أضف نصوص على الشاشة',
      ],
      'growth_forecast_30d': (followers * 0.03).round(),
      'growth_forecast_90d': (followers * 0.10).round(),
      'realistic_goal_month': 'زيادة التفاعل 20%',
      'action_items_this_week': const [
        'انشر 3 ريلز هذا الأسبوع',
        'رد على التعليقات خلال ساعة',
        'جرب هوك مختلف',
      ],
      'content_ideas': const [],
      'market_benchmarks': {
        'avg_engagement_in_niche': 2.5,
        'user_vs_avg': engagement > 2.5 ? 'أعلى' : 'أقل',
      },
    };
  }
}
