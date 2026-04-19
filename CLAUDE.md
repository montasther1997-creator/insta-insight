# CLAUDE.md

هذا الملف يعطي Claude Code سياقاً سريعاً عن المشروع حتى يشتغل بكفاءة بدون ما يحتاج يستكشف كل مرة.

---

## نظرة عامة

**InstaInsight** — تطبيق Flutter يحلل حسابات إنستغرام باستخدام Gemini AI. الواجهة عربية RTL بالكامل، مصمّمة بـ glassmorphism + neumorphism + لوحة ألوان "Royal" (ذهبي + بنفسجي + وردي).

**الفرع الرئيسي**: `main`. الـ PRs تُفتح مقابله.

---

## التكنولوجيا

- **Flutter 3.11.5+** (Dart)
- **Riverpod** لإدارة الحالة (جميع الـ providers في `lib/providers/`)
- **Supabase** — auth + قاعدة بيانات + Edge Functions
- **Gemini AI** — تحليل ذكي، توصيات، أصوات رائجة
- **Instagram Graph API** — بيانات الحساب
- **iTunes Search API** — تشغيل مقاطع + كوفرات 600×600
- **fl_chart**, **audioplayers**, **dio**, **google_fonts (Cairo)**

---

## التصميم الأساسي (Royal)

- `accentA = accentGold = #F0B95C` (ذهبي)
- `accentB = accentViolet = #A855F7` (بنفسجي)
- `accentC = accentPink = #EC4899` (وردي)
- `goldGradient`: `#FDE68A → #F0B95C → #B45309`
- توقيت انتقالات الشاشات: `550ms` بمنحنى `Cubic(0.25, 0.8, 0.3, 1.0)`
- الحبة المتدرجة في شريط التنقل: `650ms` بنفس المنحنى
- خط Cairo، داكن بالكامل، RTL

---

## الهيكل المختصر

```
lib/
├── config/          # app_theme, supabase_config, gemini_config, instagram_config
├── models/          # data classes (user, post, report, suggestion)
├── services/        # auth, instagram, gemini, cache
├── providers/       # riverpod providers (auth, instagram, analysis)
├── utils/           # tap_feedback (haptic + sound helper)
├── screens/         # dashboard + الشاشات الفرعية (5 تابات)
└── widgets/         # stat_card, post_card, glass, neumorphic, ...
supabase/
└── functions/
    ├── auth-callback/         # Instagram OAuth redirect → custom scheme
    └── fetch-trending-audio/  # pg_cron job يجمع الأصوات الرائجة
```

---

## أنماط مهمة لتكرار الشغل

### 1. تبديل التابات في `dashboard_screen.dart`
استخدم `IndexedStack` (ما تستخدم Stack-of-slots مع `Positioned.fill`). السبب: فقط الشاشة النشطة تُرسم، ما تغطي الشاشات الثانية على التفاعل. أي محاولة للرجوع لـ Stack + Positioned ستسبب مشكلة "الـ Planner يعلق".

### 2. اتجاه الأنيميشن في RTL
- استخدم `AlignmentDirectional(x, y)` بدل `Alignment(x, y)` عندما الأنيميشن يتعلق بالـ start/end (Row children تنعكس في RTL).
- عندما تحسب `sign` لـ `Transform.translate`، اضرب في `Directionality.of(context) == TextDirection.rtl ? -1 : 1`.

### 3. الـ Gemini fallback متعدد المناطق (trending audio)
عدد التراكات الخام يتقلب — لا تعتمد على منطقة واحدة. النمط الصحيح:
```dart
for (final region in const ['IQ', 'SA', 'US']) {
  if (merged.length >= 20) break;
  try {
    final supplement = await ai.suggestTrendingAudio(region: region);
    for (final a in supplement) merged.putIfAbsent(a.id, () => a);
  } catch (_) {}
}
```
عتبة الكاش الدنيا `>= 15`. أي تغيير جوهري في schema/شكل النتيجة يحتاج bump لمفتاح الكاش (`trending_audio_v3` → `v4`).

### 4. Bottom padding تحت التابات
كل شاشة قابلة للتمرير داخل الـ dashboard لازم تكون `padding.bottom = 120` على الأقل، وإلا الـ floating nav يغطي آخر عنصر.

### 5. TapFeedback على كل تفاعل
أي widget جديد قابل للضغط لازم يستدعي `TapFeedback.light()` (أو `.medium()` للأزرار الكبيرة) قبل `onTap`. الـ helper موحّد في `lib/utils/tap_feedback.dart`.

### 6. النصوص المتعددة المصادر (Gemini + user content)
نصوص Gemini ممكن تطلع طويلة أو مختلطة أرقام عربي/لاتيني. عندما تحشر نص في cell صغير:
- استخدم `FittedBox(fit: BoxFit.scaleDown)` + `maxLines: 1` + `overflow: ellipsis`.
- لو النص رقمي (نسبة/عدد)، استخدم regex لتقلّص لأول رقم مثل `_compactForecast` في `analysis_screen.dart`.

---

## OAuth flow

1. المستخدم يضغط "دخول بإنستغرام" → يفتح Chrome بـ URL تفويض Meta.
2. بعد "Allow" → Meta يرجع لـ Supabase Edge Function `auth-callback`.
3. الـ Edge Function يحفظ الـ token ويرجع `302 redirect` للـ custom scheme (`instainsight://auth-callback?...`).
4. Android intent filter في `AndroidManifest.xml` يمسك الـ scheme ويرجع المستخدم للتطبيق.

لا تضيف steps يدوية (إغلاق Chrome، clipboard paste، ...). الـ redirect التلقائي هو السلوك المطلوب.

---

## ملفات التوثيق (لا تكسرها)

- **README.md** — قائمة مرقمة بمتطلبات التصميم (1, 2, 3, ...) بالعربية. كل متطلب جديد يُضاف كقسم جديد بنفس الترتيب. لا تعيد ترقيم الأقسام الموجودة.
- **CLAUDE.md** (هذا الملف) — سياق للمساعد. حدّثه فقط عند تغيير **أنماط معمارية** جوهرية، ليس عند كل ميزة.

---

## أوامر سريعة

```bash
# تشغيل
flutter run

# APK release
flutter build apk --release

# تحليل
flutter analyze

# اختبارات
flutter test
```
