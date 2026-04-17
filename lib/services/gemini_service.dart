import 'dart:convert';
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

  /// Analyze account and return structured JSON
  Future<Map<String, dynamic>> analyzeAccount({
    required String username,
    required int followers,
    required double engagement,
    required String topCountry,
    required String topCity,
    required int bestPostViews,
    required int avgViews,
  }) async {
    final prompt = '''
أنت محلل سوشيال ميديا متخصص في السوق العربي.
حلل بيانات حساب إنستغرام التالية وأجب بالعربي فقط.

معلومات الحساب:
- اسم المستخدم: $username
- عدد المتابعين: $followers
- نسبة التفاعل: $engagement%
- أكثر دولة متابعين: $topCountry
- أكثر مدينة متابعين: $topCity
- أفضل فيديو: $bestPostViews مشاهدة
- متوسط المشاهدات: $avgViews

أعطني JSON بهذا الشكل بالضبط:
{
  "score": (رقم من 1 إلى 10),
  "summary": "(ملخص 2 جملة عن الحساب)",
  "strengths": ["نقطة قوة 1", "نقطة قوة 2", "نقطة قوة 3"],
  "weaknesses": ["نقطة ضعف 1", "نقطة ضعف 2"],
  "best_post_time": "(أفضل وقت نشر بالتوقيت المحلي)",
  "alert": "(تنبيه مهم واحد للمستخدم)",
  "content_ideas": [
    {"title": "عنوان الفكرة", "description": "وصف قصير", "priority": "high"},
    {"title": "عنوان الفكرة", "description": "وصف قصير", "priority": "medium"},
    {"title": "عنوان الفكرة", "description": "وصف قصير", "priority": "medium"},
    {"title": "عنوان الفكرة", "description": "وصف قصير", "priority": "low"},
    {"title": "عنوان الفكرة", "description": "وصف قصير", "priority": "low"}
  ]
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
    final prompt = '''
أنت محلل محتوى إنستغرام. حلل هذا المنشور بجملة واحدة فقط بالعربي:
- النوع: $mediaType
- الإعجابات: $likes
- التعليقات: $comments
- المشاهدات: $views
- نسبة التفاعل: $engagementRate%
- النص: $caption

اكتب جملة واحدة فقط تشرح سبب نجاح أو ضعف هذا المنشور.
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

  /// Generate content suggestions
  Future<List<Map<String, dynamic>>> generateSuggestions({
    required String username,
    required int followers,
    required String topCountry,
    required List<String> recentTopics,
  }) async {
    final prompt = '''
أنت مستشار محتوى سوشيال ميديا للسوق العربي.

معلومات الحساب:
- اسم المستخدم: $username
- المتابعين: $followers
- أكثر دولة: $topCountry
- مواضيع حديثة: ${recentTopics.join(', ')}

أعطني JSON يحتوي 10 أفكار فيديو مخصصة بهذا الشكل:
[
  {"title": "عنوان الفكرة", "description": "وصف قصير", "reason": "سبب الاقتراح", "priority": "high/medium/low"}
]

مهم: الرد JSON فقط (مصفوفة) بدون أي نص إضافي.
''';

    try {
      final result = await _generateJson(prompt, usePro: false);
      if (result.containsKey('ideas')) {
        return (result['ideas'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('generateSuggestions first attempt failed: $e');
      // Try parsing as array directly
      try {
        final response = await _flashModel.generateContent([Content.text(prompt)]);
        final text = response.text ?? '[]';
        final cleaned = _cleanJsonString(text);
        final list = jsonDecode(cleaned) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      } catch (e2) {
        debugPrint('generateSuggestions fallback failed: $e2');
        return [];
      }
    }
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
  "summary": "ملخص الأسبوع",
  "highlights": ["إنجاز 1", "إنجاز 2"],
  "areas_to_improve": ["نقطة 1", "نقطة 2"],
  "next_week_plan": ["خطة 1", "خطة 2", "خطة 3"],
  "competitor_gap": "فجوة المحتوى مقارنة بالمنافسين"
}

مهم: الرد JSON فقط بدون أي نص إضافي.
''';

    return _generateJson(prompt, usePro: true);
  }

  /// Suggest trending audio for a region
  Future<List<TrendingAudio>> suggestTrendingAudio({required String region}) async {
    final prompt = '''
أنت خبير في اتجاهات الموسيقى على إنستغرام ريلز في المنطقة العربية.
أعطني قائمة بـ 10 أغاني ترند حالياً في "$region" على إنستغرام ريلز.

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
      return list.map((e) {
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
    } catch (e) {
      debugPrint('suggestTrendingAudio error: $e');
      return [];
    }
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
