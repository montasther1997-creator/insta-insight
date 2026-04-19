import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';
import '../models/suggestion_model.dart';

class GeminiService {
  late final GenerativeModel _flashModel;
  late final GenerativeModel _proModel;

  GeminiService() {
    _flashModel = GenerativeModel(
      model: GeminiConfig.flashModel,
      apiKey: GeminiConfig.apiKey,
    );
    _proModel = GenerativeModel(
      model: GeminiConfig.proModel,
      apiKey: GeminiConfig.apiKey,
    );
  }

  /// Analyze account and return structured JSON with deep insights
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
  }) async {
    final prompt = '''
أنت محلل سوشيال ميديا متخصص في السوق العربي لديك خبرة 10 سنوات.
حلل بيانات حساب إنستغرام التالية بعمق وأجب بالعربي فقط.

معلومات الحساب:
- اسم المستخدم: $username
- عدد المتابعين: $followers
- نسبة التفاعل: $engagement%
- أكثر دولة متابعين: $topCountry
- أكثر مدينة متابعين: $topCity
- أفضل فيديو: $bestPostViews مشاهدة
- متوسط المشاهدات: $avgViews
- إجمالي المنشورات: $totalPosts
- فيديوهات: $videoPosts
- صور: $photoPosts
- كاروسيل: $carouselPosts
- النمو الشهري: $monthlyGrowth%

أعطني JSON بهذا الشكل بالضبط:
{
  "score": (رقم من 1 إلى 10 بناءً على تفاعل حقيقي ومتابعين),
  "summary": "(ملخص عميق 3 جمل عن الحساب ومجاله ومستوى أدائه)",
  "niche": "(تحديد المجال: فاشن/طعام/رياضة/تعليم/ترفيه/ميم/عائلي/دين/الخ)",
  "strengths": ["نقطة قوة محددة 1", "نقطة قوة محددة 2", "نقطة قوة محددة 3"],
  "weaknesses": ["نقطة ضعف قابلة للإصلاح 1", "نقطة ضعف 2", "نقطة ضعف 3"],
  "best_post_time": "(أفضل وقت نشر بالتوقيت المحلي للدولة الأعلى متابعة)",
  "alert": "(تنبيه مهم فوري للمستخدم يحتاج عمل)",
  "hook_tips": ["نصيحة هوك للثواني 3 الأولى 1", "نصيحة 2", "نصيحة 3"],
  "retention_tips": ["كيف يحتفظ بالمشاهد 1", "نصيحة 2"],
  "growth_forecast_30d": (توقع رقم متابعين جدد خلال 30 يوم),
  "growth_forecast_90d": (توقع رقم متابعين جدد خلال 90 يوم),
  "realistic_goal_month": "(هدف شهري واقعي وعملي)",
  "content_ideas": [
    {"title": "عنوان الفكرة", "description": "وصف قصير", "priority": "high"},
    {"title": "عنوان الفكرة", "description": "وصف قصير", "priority": "high"},
    {"title": "عنوان الفكرة", "description": "وصف قصير", "priority": "medium"},
    {"title": "عنوان الفكرة", "description": "وصف قصير", "priority": "medium"},
    {"title": "عنوان الفكرة", "description": "وصف قصير", "priority": "low"}
  ],
  "market_benchmarks": {
    "avg_engagement_in_niche": (متوسط تفاعل المجال),
    "user_vs_avg": "(أعلى/أقل/مساوي لمتوسط المجال)"
  }
}

مهم: الرد JSON فقط بدون أي نص إضافي.
''';

    return _generateJson(prompt, usePro: false);
  }

  /// Analyze a single post and return reason for success/failure
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
أنت محلل محتوى إنستغرام. حلل هذا المنشور بجملة واحدة فقط بالعربي:
- النوع: $mediaType
- الإعجابات: $likes
- التعليقات: $comments
$viewsLine
- نسبة التفاعل: $engagementRate%
- النص: $caption

اكتب جملة واحدة فقط تشرح سبب نجاح أو ضعف هذا المنشور بناءً على الإعجابات والتعليقات والنص — بدون افتراض الفشل بسبب غياب بيانات المشاهدات.
''';

    try {
      final response = await _flashModel.generateContent([Content.text(prompt)]);
      return response.text ?? 'لا يتوفر تحليل';
    } catch (e) {
      debugPrint('analyzePost error: $e');
      return 'لا يتوفر تحليل';
    }
  }

  /// Analyze trending audio relevance to user's content
  Future<String> analyzeAudioRelevance({
    required String audioName,
    required String artistName,
    required String userContentType,
    required String userAudience,
  }) async {
    final prompt = '''
بجملة واحدة بالعربي، هل أغنية "$audioName" لـ "$artistName" مناسبة لصانع محتوى يقدم "$userContentType" وجمهوره من "$userAudience"؟
أجب بـ "مناسبة جداً" أو "مناسبة" أو "غير مناسبة" مع السبب.
''';

    try {
      final response = await _flashModel.generateContent([Content.text(prompt)]);
      return response.text ?? 'غير محدد';
    } catch (e) {
      debugPrint('analyzeAudioRelevance error: $e');
      return 'غير محدد';
    }
  }

  /// Generate 30 detailed content suggestions
  Future<List<Map<String, dynamic>>> generateSuggestions({
    required String username,
    required int followers,
    required String topCountry,
    required List<String> recentTopics,
    String niche = 'عام',
  }) async {
    final prompt = '''
أنت مستشار محتوى سوشيال ميديا محترف للسوق العربي.

معلومات الحساب:
- اسم المستخدم: $username
- المتابعين: $followers
- أكثر دولة: $topCountry
- المجال: $niche
- مواضيع حديثة: ${recentTopics.take(5).join(', ')}

أعطني JSON يحتوي 30 فكرة فيديو مخصصة ومتنوعة بهذا الشكل:
[
  {"title": "عنوان جذاب قصير", "description": "وصف مفصل مع هوك قوي", "reason": "سبب الاقتراح ولماذا سينجح", "priority": "high", "hashtags": "#هاشتاق1 #هاشتاق2 #هاشتاق3", "estimated_views": "تقدير المشاهدات"}
]

وزع الأولويات:
- 10 فكرة high priority (ترند حالي وأعلى فرصة نجاح)
- 15 فكرة medium priority (محتوى متنوع)
- 5 فكرة low priority (تجريبي وإبداعي)

مهم: الرد JSON فقط (مصفوفة من 30 فكرة) بدون أي نص إضافي.
''';

    try {
      final response = await _flashModel.generateContent([Content.text(prompt)]);
      final text = response.text ?? '[]';
      final cleaned = _cleanJsonString(text);
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      } else if (decoded is Map && decoded.containsKey('ideas')) {
        return (decoded['ideas'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('generateSuggestions error: $e');
      return [];
    }
  }

  /// Analyze video performance (top videos, hook, retention)
  Future<Map<String, dynamic>> analyzeVideoPerformance({
    required List<Map<String, dynamic>> topVideos,
    required int totalVideos,
    required double avgEngagement,
  }) async {
    final prompt = '''
أنت خبير تحليل فيديوهات إنستغرام. حلل أداء فيديوهات هذا الحساب.

أفضل الفيديوهات:
${jsonEncode(topVideos)}

إجمالي الفيديوهات: $totalVideos
متوسط التفاعل: $avgEngagement%

أعطني JSON:
{
  "common_success_factors": ["سبب نجاح مشترك 1", "سبب 2", "سبب 3"],
  "hook_analysis": "(تحليل الهوك في الثواني 3 الأولى)",
  "retention_strategy": "(كيف يحافظ على المشاهد)",
  "optimal_duration": "(المدة المثالية بالثواني)",
  "best_words": ["كلمة جذابة 1", "كلمة 2", "كلمة 3"],
  "best_hashtags": ["#هاشتاق1", "#هاشتاق2", "#هاشتاق3", "#هاشتاق4", "#هاشتاق5"],
  "weak_videos_reason": "(لماذا بعض الفيديوهات فشلت)",
  "improvement_tips": ["نصيحة تحسين 1", "نصيحة 2", "نصيحة 3"]
}

مهم: الرد JSON فقط بدون أي نص إضافي.
''';

    return _generateJson(prompt, usePro: false);
  }

  /// Generate weekly content plan
  Future<Map<String, dynamic>> generateWeeklyPlan({
    required String username,
    required String niche,
    required String topCountry,
    required String bestPostTime,
  }) async {
    final prompt = '''
أنت مخطط محتوى سوشيال ميديا. خطط أسبوع كامل لحساب "$username" في مجال "$niche" بدولة "$topCountry".

أعطني JSON:
{
  "week_theme": "(موضوع عام للأسبوع)",
  "days": [
    {"day": "السبت", "content_type": "reel/post/story", "title": "عنوان", "description": "وصف", "best_time": "$bestPostTime", "expected_engagement": "عالي/متوسط"},
    {"day": "الأحد", "content_type": "...", "title": "...", "description": "...", "best_time": "...", "expected_engagement": "..."},
    {"day": "الإثنين", "content_type": "...", "title": "...", "description": "...", "best_time": "...", "expected_engagement": "..."},
    {"day": "الثلاثاء", "content_type": "...", "title": "...", "description": "...", "best_time": "...", "expected_engagement": "..."},
    {"day": "الأربعاء", "content_type": "...", "title": "...", "description": "...", "best_time": "...", "expected_engagement": "..."},
    {"day": "الخميس", "content_type": "...", "title": "...", "description": "...", "best_time": "...", "expected_engagement": "..."},
    {"day": "الجمعة", "content_type": "...", "title": "...", "description": "...", "best_time": "...", "expected_engagement": "..."}
  ],
  "expected_growth": "نمو متوقع للأسبوع",
  "key_metrics": ["مقياس مهم 1", "مقياس 2"]
}

مهم: الرد JSON فقط بدون أي نص إضافي.
''';

    return _generateJson(prompt, usePro: false);
  }

  /// Generate auto-caption for a post idea
  Future<Map<String, dynamic>> generateCaption({
    required String postIdea,
    required String niche,
    required String tone,
  }) async {
    final prompt = '''
أنت كاتب محتوى سوشيال ميديا محترف.
اكتب كابشن جذاب بالعربي لفكرة منشور إنستغرام.

الفكرة: $postIdea
المجال: $niche
الأسلوب: $tone

أعطني JSON:
{
  "caption_short": "(كابشن قصير جذاب سطر واحد)",
  "caption_medium": "(كابشن متوسط مع إيموجي وCTA)",
  "caption_long": "(كابشن طويل قصصي مع هوك قوي في البداية)",
  "hashtags": "#هاشتاق1 #هاشتاق2 #هاشتاق3 #هاشتاق4 #هاشتاق5 #هاشتاق6 #هاشتاق7 #هاشتاق8 #هاشتاق9 #هاشتاق10",
  "cta": "(دعوة واضحة للتفاعل)",
  "hook_variations": ["هوك 1", "هوك 2", "هوك 3"]
}

مهم: الرد JSON فقط بدون أي نص إضافي.
''';

    return _generateJson(prompt, usePro: false);
  }

  /// Weekly report using Pro model
  Future<Map<String, dynamic>> generateWeeklyReport({
    required String username,
    required Map<String, dynamic> weeklyData,
  }) async {
    final prompt = '''
أنت محلل سوشيال ميديا متخصص. أنشئ تقريراً أسبوعياً مفصلاً لحساب "$username".

البيانات الأسبوعية:
${jsonEncode(weeklyData)}

أعطني JSON بهذا الشكل:
{
  "overall_score": (1-10),
  "summary": "ملخص الأسبوع بثلاث جمل",
  "highlights": ["إنجاز 1", "إنجاز 2", "إنجاز 3"],
  "areas_to_improve": ["نقطة 1", "نقطة 2", "نقطة 3"],
  "next_week_plan": ["خطة 1", "خطة 2", "خطة 3", "خطة 4"],
  "competitor_gap": "فجوة المحتوى مقارنة بالمنافسين",
  "best_post_of_week": "وصف أفضل منشور ولماذا",
  "engagement_trend": "صاعد/ثابت/هابط مع نسبة",
  "recommendation": "توصية رئيسية للأسبوع القادم"
}

مهم: الرد JSON فقط بدون أي نص إضافي.
''';

    return _generateJson(prompt, usePro: true);
  }

  /// Suggest trending audio for a region
  Future<List<TrendingAudio>> suggestTrendingAudio({required String region}) async {
    final prompt = '''
أنت خبير في اتجاهات الموسيقى على إنستغرام ريلز في المنطقة العربية.
أعطني قائمة بـ 20 أغنية ترند حالياً في "$region" على إنستغرام ريلز/TikTok.
تنوّع بين العربي والإنجليزي، واذكر أغاني معروفة حالياً (2024-2026) حتى يصير الـ iTunes preview متوفر.

أعطني JSON مصفوفة بهذا الشكل بالضبط:
[
  {
    "audio_name": "اسم الأغنية",
    "artist_name": "اسم الفنان",
    "usage_count": (رقم تقريبي),
    "growth_rate": (نسبة نمو تقريبية),
    "country_codes": ["SA", "AE"],
    "is_rising": true
  }
]

مهم: الرد JSON فقط (مصفوفة) بدون أي نص إضافي.
''';

    try {
      final response = await _flashModel.generateContent([Content.text(prompt)]);
      final text = response.text ?? '[]';
      final cleaned = _cleanJsonString(text);
      final list = jsonDecode(cleaned) as List<dynamic>;
      // Build bare tracks first, then enrich with iTunes Search API in parallel
      // to fetch real preview_url + cover artwork — Gemini only gives names.
      final bare = list.map((e) {
        final map = e as Map<String, dynamic>;
        return TrendingAudio(
          id: 'gemini_${list.indexOf(e)}',
          audioName: map['audio_name'] as String? ?? '',
          artistName: map['artist_name'] as String? ?? '',
          usageCount: map['usage_count'] as int? ?? 0,
          growthRate: (map['growth_rate'] as num?)?.toDouble() ?? 0.0,
          countryCodes: (map['country_codes'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
          isRising: map['is_rising'] as bool? ?? false,
          detectedAt: DateTime.now(),
        );
      }).toList();
      return await _enrichWithItunes(bare);
    } catch (e) {
      debugPrint('suggestTrendingAudio error: $e');
      return [];
    }
  }

  /// Look up `previewUrl` + `coverUrl` for each track via iTunes Search API
  /// (free, no auth). Done in parallel so the UI gets playable tracks fast.
  Future<List<TrendingAudio>> _enrichWithItunes(
      List<TrendingAudio> tracks) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ));
    final futures = tracks.map((t) async {
      if ((t.previewUrl?.isNotEmpty ?? false) &&
          (t.coverUrl?.isNotEmpty ?? false)) {
        return t;
      }
      final query = '${t.artistName} ${t.audioName}'.trim();
      if (query.isEmpty) return t;
      try {
        final r = await dio.get(
          'https://itunes.apple.com/search',
          queryParameters: {
            'term': query,
            'media': 'music',
            'entity': 'song',
            'limit': 1,
          },
        );
        final results = (r.data['results'] as List?) ?? const [];
        if (results.isEmpty) return t;
        final hit = results.first as Map<String, dynamic>;
        final previewUrl = hit['previewUrl'] as String?;
        // Upscale the 100x100 artwork to 600x600 — iTunes serves a predictable
        // URL pattern so we swap the size in place.
        final art = hit['artworkUrl100'] as String?;
        final coverUrl = art?.replaceAll('100x100bb', '600x600bb');
        return TrendingAudio(
          id: t.id,
          audioName: t.audioName,
          artistName: t.artistName,
          usageCount: t.usageCount,
          growthRate: t.growthRate,
          countryCodes: t.countryCodes,
          isRising: t.isRising,
          detectedAt: t.detectedAt,
          previewUrl: previewUrl ?? t.previewUrl,
          coverUrl: coverUrl ?? t.coverUrl,
          duration: (hit['trackTimeMillis'] as num?) != null
              ? ((hit['trackTimeMillis'] as num) ~/ 1000).toInt()
              : t.duration,
        );
      } catch (e) {
        debugPrint('iTunes lookup failed for "$query": $e');
        return t;
      }
    });
    return Future.wait(futures);
  }

  /// Internal: generate JSON from Gemini
  Future<Map<String, dynamic>> _generateJson(String prompt, {bool usePro = false}) async {
    final model = usePro ? _proModel : _flashModel;

    int retries = 3;
    while (retries > 0) {
      try {
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text ?? '{}';
        final cleaned = _cleanJsonString(text);
        return jsonDecode(cleaned) as Map<String, dynamic>;
      } catch (e) {
        retries--;
        if (retries == 0) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return {};
  }

  /// Clean JSON string from markdown code blocks
  String _cleanJsonString(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
