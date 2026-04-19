import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/gemini_config.dart';

/// Direct HTTP client for Anthropic Messages API.
/// Same shape as GeminiService so the rest of the app can swap between them.
class ClaudeService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );

  Future<String> _callMessages(
    String prompt, {
    String? model,
    int maxTokens = 2048,
    double temperature = 0.7,
  }) async {
    if (!ClaudeConfig.hasApiKey) {
      throw StateError('ANTHROPIC_API_KEY missing');
    }
    final response = await _dio.post(
      ClaudeConfig.endpoint,
      options: Options(
        headers: {
          'x-api-key': ClaudeConfig.apiKey,
          'anthropic-version': ClaudeConfig.version,
          'content-type': 'application/json',
        },
      ),
      data: {
        'model': model ?? ClaudeConfig.model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      },
    );
    final data = response.data as Map<String, dynamic>;
    final content = (data['content'] as List<dynamic>?) ?? const [];
    if (content.isEmpty) return '';
    final first = content.first as Map<String, dynamic>;
    return (first['text'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> _generateJson(
    String prompt, {
    bool fast = false,
    int maxTokens = 2048,
  }) async {
    final model = fast ? ClaudeConfig.fastModel : ClaudeConfig.model;
    int retries = 2;
    while (retries >= 0) {
      try {
        final raw = await _callMessages(
          prompt,
          model: model,
          maxTokens: maxTokens,
        );
        final cleaned = _cleanJson(raw);
        return jsonDecode(cleaned) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Claude _generateJson error (retries=$retries): $e');
        if (retries == 0) rethrow;
        retries--;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return {};
  }

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
    final prompt = '''
أنت محلل سوشيال ميديا متخصص في السوق العربي لديك خبرة 10 سنوات.
حلل بيانات حساب إنستغرام التالية بعمق وأجب بالعربي فقط.

البيانات:
- اسم المستخدم: $username
- المتابعون: $followers
- نسبة التفاعل: ${engagement.toStringAsFixed(2)}%
- أكثر دولة: $topCountry
- أكثر مدينة: $topCity
- أفضل منشور: $bestPostViews مشاهدة
- متوسط المشاهدات: $avgViews
- إجمالي المنشورات: $totalPosts
- فيديوهات: $videoPosts، صور: $photoPosts، كاروسيل: $carouselPosts
- النمو الشهري: ${monthlyGrowth.toStringAsFixed(2)}%
- إجمالي الإعجابات: $totalLikes
- إجمالي التعليقات: $totalComments

أرجع JSON فقط بهذا الشكل بالضبط، بدون أي نص قبله أو بعده:
{
  "score": رقم من 1 إلى 10 دقيق (يمكن كسر عشري),
  "score_breakdown": {
    "content_quality": رقم من 0 إلى 10,
    "engagement_health": رقم من 0 إلى 10,
    "consistency": رقم من 0 إلى 10,
    "growth_momentum": رقم من 0 إلى 10,
    "audience_fit": رقم من 0 إلى 10
  },
  "percentile_vs_niche": رقم من 1 إلى 99 (نسبة تفوق على الحسابات المشابهة),
  "summary": "ملخص عميق 3 جمل",
  "niche": "تحديد المجال",
  "strengths": ["نقطة قوة 1", "نقطة قوة 2", "نقطة قوة 3"],
  "weaknesses": ["نقطة ضعف 1", "نقطة ضعف 2", "نقطة ضعف 3"],
  "best_post_time": "أفضل وقت نشر",
  "alert": "تنبيه مهم فوري",
  "hook_tips": ["نصيحة هوك 1", "نصيحة 2", "نصيحة 3"],
  "retention_tips": ["نصيحة احتفاظ 1", "نصيحة 2"],
  "growth_forecast_30d": رقم متابعين جدد خلال 30 يوم,
  "growth_forecast_90d": رقم متابعين جدد خلال 90 يوم,
  "realistic_goal_month": "هدف شهري واقعي",
  "action_items_this_week": ["مهمة 1", "مهمة 2", "مهمة 3"],
  "content_ideas": [
    {"title": "عنوان", "description": "وصف", "priority": "high"},
    {"title": "عنوان", "description": "وصف", "priority": "high"},
    {"title": "عنوان", "description": "وصف", "priority": "medium"},
    {"title": "عنوان", "description": "وصف", "priority": "medium"},
    {"title": "عنوان", "description": "وصف", "priority": "low"}
  ],
  "market_benchmarks": {
    "avg_engagement_in_niche": رقم,
    "user_vs_avg": "أعلى/أقل/مساوي"
  }
}
''';
    return _generateJson(prompt, maxTokens: 3000);
  }

  Future<String> analyzePost({
    required String mediaType,
    required int likes,
    required int comments,
    required int views,
    required double engagementRate,
    required String caption,
  }) async {
    final viewsLine = views > 0
        ? '- المشاهدات: $views'
        : '- المشاهدات: غير متاحة (لا تستنتج أن المنشور لم يصل لأحد — API لم يُرجع هذه البيانة فقط)';
    final prompt = '''
حلل هذا المنشور بجملة واحدة بالعربي:
- النوع: $mediaType
- الإعجابات: $likes
- التعليقات: $comments
$viewsLine
- نسبة التفاعل: ${engagementRate.toStringAsFixed(2)}%
- النص: $caption

اكتب جملة واحدة فقط تشرح سبب نجاح أو ضعف هذا المنشور بناءً على الإعجابات والتعليقات والنص — بدون افتراض الفشل بسبب غياب بيانات المشاهدات.
''';
    try {
      return (await _callMessages(prompt,
              model: ClaudeConfig.fastModel, maxTokens: 120))
          .trim();
    } catch (e) {
      debugPrint('Claude analyzePost error: $e');
      return 'لا يتوفر تحليل';
    }
  }

  Future<List<Map<String, dynamic>>> generateSuggestions({
    required String username,
    required int followers,
    required String topCountry,
    required List<String> recentTopics,
    String niche = 'عام',
  }) async {
    final prompt = '''
أنت مستشار محتوى محترف للسوق العربي.

الحساب:
- اسم المستخدم: $username
- المتابعون: $followers
- الدولة: $topCountry
- المجال: $niche
- مواضيع حديثة: ${recentTopics.take(5).join(', ')}

أرجع JSON فقط، مصفوفة من 30 فكرة بهذا الشكل:
[
  {"title": "عنوان", "description": "وصف مع هوك", "reason": "سبب النجاح", "priority": "high", "hashtags": "#تاق1 #تاق2 #تاق3", "estimated_views": "تقدير"}
]

وزع: 10 high، 15 medium، 5 low.
''';
    try {
      final raw = await _callMessages(prompt, maxTokens: 4000);
      final cleaned = _cleanJson(raw);
      final decoded = jsonDecode(cleaned);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      if (decoded is Map && decoded.containsKey('ideas')) {
        return (decoded['ideas'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Claude generateSuggestions error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> generateWeeklyPlan({
    required String username,
    required String niche,
    required String topCountry,
    required String bestPostTime,
  }) async {
    final prompt = '''
أنت مخطط محتوى محترف. خطط أسبوع كامل لحساب "$username" في مجال "$niche" بدولة "$topCountry".

أرجع JSON فقط:
{
  "week_theme": "موضوع عام للأسبوع",
  "days": [
    {"day": "السبت", "content_type": "reel/post/story", "title": "", "description": "", "best_time": "$bestPostTime", "expected_engagement": "عالي/متوسط"},
    {"day": "الأحد", "content_type": "", "title": "", "description": "", "best_time": "", "expected_engagement": ""},
    {"day": "الإثنين", "content_type": "", "title": "", "description": "", "best_time": "", "expected_engagement": ""},
    {"day": "الثلاثاء", "content_type": "", "title": "", "description": "", "best_time": "", "expected_engagement": ""},
    {"day": "الأربعاء", "content_type": "", "title": "", "description": "", "best_time": "", "expected_engagement": ""},
    {"day": "الخميس", "content_type": "", "title": "", "description": "", "best_time": "", "expected_engagement": ""},
    {"day": "الجمعة", "content_type": "", "title": "", "description": "", "best_time": "", "expected_engagement": ""}
  ],
  "expected_growth": "",
  "key_metrics": ["", ""]
}
''';
    return _generateJson(prompt, maxTokens: 2500);
  }

  Future<Map<String, dynamic>> generateCaption({
    required String postIdea,
    required String niche,
    required String tone,
  }) async {
    final prompt = '''
اكتب كابشن جذاب بالعربي لفكرة إنستغرام.
الفكرة: $postIdea
المجال: $niche
الأسلوب: $tone

أرجع JSON فقط:
{
  "caption_short": "",
  "caption_medium": "",
  "caption_long": "",
  "hashtags": "#تاق1 #تاق2 #تاق3 #تاق4 #تاق5 #تاق6 #تاق7 #تاق8 #تاق9 #تاق10",
  "cta": "",
  "hook_variations": ["", "", ""]
}
''';
    return _generateJson(prompt, maxTokens: 1500);
  }

  Future<Map<String, dynamic>> analyzeVideoPerformance({
    required List<Map<String, dynamic>> topVideos,
    required int totalVideos,
    required double avgEngagement,
  }) async {
    final prompt = '''
حلل أداء فيديوهات هذا الحساب.
أفضل الفيديوهات: ${jsonEncode(topVideos)}
إجمالي الفيديوهات: $totalVideos
متوسط التفاعل: ${avgEngagement.toStringAsFixed(2)}%

أرجع JSON فقط:
{
  "common_success_factors": ["", "", ""],
  "hook_analysis": "",
  "retention_strategy": "",
  "optimal_duration": "",
  "best_words": ["", "", ""],
  "best_hashtags": ["#1", "#2", "#3", "#4", "#5"],
  "weak_videos_reason": "",
  "improvement_tips": ["", "", ""]
}
''';
    return _generateJson(prompt, maxTokens: 2000);
  }

  Future<Map<String, dynamic>> generateScoreBreakdown({
    required String username,
    required double currentScore,
    required Map<String, dynamic> metrics,
  }) async {
    final prompt = '''
أنت محلل سوشيال ميديا. حلل تقييم حساب "$username" الحالي (${currentScore.toStringAsFixed(1)}/10) بناء على:
${jsonEncode(metrics)}

أرجع JSON فقط:
{
  "headline": "تقييم عام بجملة",
  "why_this_score": "شرح تفصيلي 2-3 جمل لسبب التقييم",
  "sub_scores": [
    {"name": "جودة المحتوى", "score": 0-10, "note": "ملاحظة قصيرة"},
    {"name": "صحة التفاعل", "score": 0-10, "note": ""},
    {"name": "الانتظام", "score": 0-10, "note": ""},
    {"name": "زخم النمو", "score": 0-10, "note": ""},
    {"name": "ملاءمة الجمهور", "score": 0-10, "note": ""}
  ],
  "to_reach_next_point": ["خطوة 1", "خطوة 2", "خطوة 3"],
  "red_flags": ["تحذير 1", "تحذير 2"],
  "green_flags": ["إشارة إيجابية 1", "إشارة إيجابية 2"]
}
''';
    return _generateJson(prompt, maxTokens: 2000);
  }

  String _cleanJson(String text) {
    var cleaned = text.trim();
    // Strip markdown fences.
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    // Claude sometimes prepends a short intro line — slice from first { or [.
    final firstBrace = cleaned.indexOf('{');
    final firstBracket = cleaned.indexOf('[');
    int cut;
    if (firstBrace == -1) {
      cut = firstBracket;
    } else if (firstBracket == -1) {
      cut = firstBrace;
    } else {
      cut = firstBrace < firstBracket ? firstBrace : firstBracket;
    }
    if (cut > 0) cleaned = cleaned.substring(cut);
    return cleaned.trim();
  }
}
