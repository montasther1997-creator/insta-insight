# InstaInsight

**محلل حسابات إنستغرام الذكي** - تطبيق Flutter يحلل حسابك على إنستغرام باستخدام الذكاء الاصطناعي Gemini AI ويقدم لك رؤى وتوصيات لتحسين أدائك.

---

## المميزات

### لوحة التحكم الرئيسية
- عرض بيانات الحساب (المتابعون، نسبة التفاعل، النمو الأسبوعي)
- تقييم شامل للحساب من 10 بواسطة Gemini AI
- تنبيهات ذكية وملخص تحليلي مع نقاط القوة والضعف

### التحليل المتقدم
- رسم بياني لنسبة التفاعل خلال آخر 30 يوم
- تحديد أفضل وأضعف منشور تلقائيا
- خريطة حرارية لأوقات النشر (Heatmap)
- تحليل AI للمنافسة مع تحديد أفضل وقت للنشر

### التحليل الجغرافي
- توزيع المتابعين حسب الدول والمدن
- عرض بصري بأشرطة التقدم

### تحليل الفيديوهات
- ترتيب أفضل 10 فيديوهات حسب التفاعل
- تحليل أفضل مدة للفيديو

### الأغاني الرائجة
- عرض الأصوات الرائجة في مجالك
- مؤشرات النمو لكل صوت

### الاقتراحات الذكية
- توصيات مخصصة من Gemini AI لتحسين المحتوى
- تصنيف حسب الأولوية (عالية، متوسطة، منخفضة)
- تنبيه فجوات المحتوى

---

## التقنيات المستخدمة

| التقنية | الاستخدام |
|---------|-----------|
| **Flutter** | إطار العمل الرئيسي (Dart) |
| **Riverpod** | إدارة الحالة |
| **Supabase** | المصادقة وقاعدة البيانات |
| **Instagram Graph API** | جلب بيانات الحساب |
| **Gemini AI** | التحليل الذكي والتوصيات |
| **fl_chart** | الرسوم البيانية |
| **Dio** | طلبات HTTP |
| **Google Fonts (Cairo)** | الخطوط العربية |

---

## هيكل المشروع

```
lib/
├── main.dart                  # نقطة الدخول
├── config/
│   ├── app_theme.dart         # الثيم الداكن والألوان
│   ├── supabase_config.dart   # إعدادات Supabase
│   ├── gemini_config.dart     # إعدادات Gemini AI
│   └── instagram_config.dart  # إعدادات Instagram API
├── models/
│   ├── user_model.dart        # نموذج المستخدم
│   ├── post_model.dart        # نموذج المنشور
│   ├── report_model.dart      # نموذج التقرير
│   └── suggestion_model.dart  # نموذج الاقتراحات
├── services/
│   ├── auth_service.dart      # خدمة المصادقة (OAuth)
│   ├── instagram_service.dart # خدمة Instagram API
│   ├── gemini_service.dart    # خدمة Gemini AI
│   └── cache_service.dart     # خدمة التخزين المؤقت
├── providers/
│   ├── auth_provider.dart     # مزود المصادقة
│   ├── instagram_provider.dart # مزود بيانات إنستغرام
│   └── analysis_provider.dart # مزود التحليل الذكي
├── screens/
│   ├── splash_screen.dart     # شاشة البداية
│   ├── login_screen.dart      # شاشة تسجيل الدخول
│   ├── dashboard_screen.dart  # لوحة التحكم الرئيسية
│   ├── analysis_screen.dart   # شاشة التحليل
│   ├── geo_screen.dart        # التحليل الجغرافي
│   ├── videos_screen.dart     # تحليل الفيديوهات
│   ├── music_screen.dart      # الأغاني الرائجة
│   └── suggestions_screen.dart # الاقتراحات الذكية
└── widgets/
    ├── stat_card.dart         # بطاقة الإحصائيات
    ├── post_card.dart         # بطاقة المنشور
    ├── suggestion_card.dart   # بطاقة الاقتراح
    ├── heatmap_widget.dart    # خريطة حرارية
    ├── geo_bar.dart           # شريط التوزيع الجغرافي
    └── shimmer_loader.dart    # تأثير التحميل
```

---

## التثبيت والتشغيل

### المتطلبات
- Flutter SDK 3.11.5+
- حساب [Supabase](https://supabase.com)
- مفتاح [Gemini AI API](https://ai.google.dev)
- تطبيق Instagram (Meta Developer Portal)

### الخطوات

1. **استنساخ المشروع**
   ```bash
   git clone <repo-url>
   cd insta_insight
   ```

2. **إنشاء ملف `.env`**
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_anon_key
   INSTAGRAM_APP_ID=your_app_id
   INSTAGRAM_APP_SECRET=your_app_secret
   INSTAGRAM_REDIRECT_URI=your_redirect_uri
   GEMINI_API_KEY=your_gemini_key
   ```

3. **تثبيت الحزم**
   ```bash
   flutter pub get
   ```

4. **تشغيل التطبيق**
   ```bash
   flutter run
   ```

---

## التصميم

- واجهة داكنة بالكامل (Dark Theme)
- خط Cairo العربي
- دعم كامل لـ RTL
- ألوان متدرجة (بنفسجي، وردي، أزرق، أخضر)
- تأثيرات حركية سلسة (flutter_animate)
- تأثير Shimmer أثناء التحميل
