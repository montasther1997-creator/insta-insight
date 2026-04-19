# InstaInsight

**محلل حسابات إنستغرام الذكي** — تطبيق Flutter يحلل حسابك على إنستغرام باستخدام Gemini AI ويقدم توصيات لتحسين الأداء.

---

## متطلبات التصميم (مرتّبة حسب طلبي)

هذه قائمة بالتعديلات التصميمية الي طلبتها، بنفس الترتيب الي ناقشناه. كل نقطة فيها: الوصف، الحالة الحالية، الملفات المعنية. اعتمد هذه القائمة كبريف تصميم.

### 1. زيادة عدد الأصوات الرائجة (15-20 بدل 5)
- **المطلوب**: شاشة "الأغاني الرائجة" كانت تعرض 5 تراكات فقط، المطلوب 15-20.
- **الحالة**: تم — 3 مناطق (IQ + US + SA) + fallback من Gemini.
- **تصميم**: الشبكة نفسها، بس مع تراكات أكثر. يحتاج تأكيد إن الـ grid/list يتسع للعدد الأكبر.
- **الملفات**: `lib/screens/music_screen.dart`، `supabase/functions/fetch-trending-audio/index.ts`.

### 2. OAuth — الرجوع التلقائي للتطبيق بعد "Allow"
- **المطلوب**: المستخدم يضغط "Allow" ويرجع تلقائياً للتطبيق بدون الحاجة لإغلاق Chrome يدوياً.
- **الحالة**: تم — Edge Function ترجع 302 redirect للـ custom scheme.
- **تصميم**: (ليس تصميم بصري — تصميم تدفق فقط)
- **الملفات**: `supabase/functions/auth-callback/index.ts`، `lib/config/instagram_config.dart`.

### 3. شاشة "المتابعون النشطون" — البطاقات قابلة للضغط
- **المطلوب**: عند الضغط على "الأكثر تفاعلاً بالإعجابات" / "الأكثر تفاعلاً بالتعليقات" تظهر تفاصيل من تفاعل.
- **الحالة**: تم — كل صف فيه thumbnail للمنشور + شيفرون، يفتح تفاصيل المنشور عند الضغط.
- **تصميم**: يحتاج مراجعة لصف المنشور — الـ thumbnail صغير (36×44)، التصميم بسيط. ممكن يصير أبهى.
- **الملفات**: `lib/screens/followers_detail_screen.dart`.

### 4. زر "ولّد 30 فكرة" — النص غير واضح
- **المطلوب**: نص الزر بلون بنفسجي على خلفية متدرجة — ما يقرا. المطلوب يصير واضح 100%.
- **الحالة**: تم — لون أبيض، وزن w800، حجم 15، ظل داكن للقراءة.
- **تصميم**: الظل والتباين كافيين للقراءة لكن ممكن تحسين بصري للزر كامل.
- **الملفات**: `lib/screens/suggestions_screen.dart`.

### 5. الأغاني — تشغيل الصوت
- **المطلوب**: الأيقونات الموسيقية ما تشغل صوت. المطلوب تصير قابلة للتشغيل.
- **الحالة**: تم — iTunes Search API يوفر `preview_url` + كوفر 600×600 لكل تراك من Gemini.
- **تصميم**: بطاقة التراك تحتاج زر play/pause واضح + مؤشر تحميل + حالة "تشغيل حالياً".
- **الملفات**: `lib/services/gemini_service.dart`، `lib/screens/music_screen.dart`.

### 6. البطاقة الثالثة في "المتابعون النشطون" — "يصلهم المحتوى دون تفاعل"
- **المطلوب**: البطاقة كانت فاضية وفيها footnote "API إنستغرام لا يُعيد قائمة الأسماء". المطلوب تشتغل 100% مع بيانات فعلية.
- **الحالة**: تم — العنوان صار "المنشورات الأوسع انتشاراً"، أيقونة عين، تعرض أعلى 3 منشورات حسب المشاهدات، قابلة للضغط.
- **تصميم**: نفس تصميم البطاقتين الأخريتين — متسق.
- **الملفات**: `lib/screens/followers_detail_screen.dart`.

### 7. شريط التنقل السفلي — أنيميشن مميز للتبديل
- **المطلوب**: عند التنقل بين التابات (الرئيسية، التحليل، فيديوهات، الاقتراحات، خطة) يكون فيه أنيميشن "كلش مميز".
- **الحالة**: تم:
  - "حبة" متدرجة تنزلق بين التابات (`AnimatedAlign`, 420ms easeOutCubic)
  - الأيقونة النشطة تسوي bounce بمنحنى `elasticOut` + glow شفاف بلون العلامة التجارية
  - كل شاشة تدخل بأنيميشن: fade + scale (0.93→1.0) + slide حسب موقع التابة
  - كل تابة تحتفظ بحالتها (scroll + filters لا تنريست)
- **تصميم**: يحتاج مراجعة للطابع البصري للـ pill (تدرج، glow، border) — ممكن يصير أكثر لمعاناً.
- **الملفات**: `lib/screens/dashboard_screen.dart`.

### 8. صوت + هزة خفيفة عند الضغط على أي زر
- **المطلوب**: أي زر بالتطبيق يطلع صوت خفيف + هزة خفيفة (haptic) عند الضغط.
- **الحالة**: تم — helper موحّد `TapFeedback` يدمج `HapticFeedback.selectionClick()` + `SystemSound.play(SystemSoundType.click)`. مربوط بـ:
  - تابات البوتم نف
  - `StatCard`، `NeumorphicButton`، `HeaderIconBtn`
  - `PostCard`، `SuggestionCard`
  - variant `medium()` للأزرار الرئيسية الذهبية (هزة أقوى قليلاً)
- **تصميم**: لا يؤثر على البصريات — interaction فقط.
- **الملفات**: `lib/utils/tap_feedback.dart`، `lib/widgets/*.dart`.

### 9. تطبيق حزمة التصميم (Royal · Gold + Violet)
- **المطلوب**: تطبيق حزمة التصميم المرسلة (design bundle) على الكود — اللوحة الرسمية + توقيتات الأنيميشن.
- **الحالة**: تم:
  - **اللوحة**: لوحة Royal الرسمية — `accentA` = ذهبي `#F0B95C`، `accentB` = بنفسجي `#A855F7`، `accentC` = وردي `#EC4899`.
  - **التدرج الذهبي**: `goldGradient` صار متدرج ذهبي فعلي `#FDE68A → #F0B95C → #B45309` (كان aliased لـ brandGradient، يعني أي شاشة تستخدم `AppColors.goldGradient` أو `accentGold` هسه تعرض ذهبياً حقيقياً).
  - **شريط التنقل السفلي**: الحبة تدرج ذهبي + slide 650ms بمنحنى `Cubic(0.25, 0.8, 0.3, 1)` (كان 420ms بنفسجي). الأيقونة/النص النشط بلون داكن `#2A0F05` للتباين على الذهبي.
  - **انتقالات الشاشات**: 550ms بنفس المنحنى (كانت 360/440ms) — مطابق لمواصفة `tabInLeft/tabInRight` من `InstaInsight.html`.
- **تصميم**: متسق مع `theme.jsx` و`frame.jsx` من الحزمة.
- **الملفات**: `lib/config/app_theme.dart`، `lib/screens/dashboard_screen.dart`.

### 10. إصلاح شريط التنقل في RTL + مشكلة "علوق" على تابة الخطة
- **المطلوب**: الحبة المتدرجة كانت تطلع باتجاه معكوس في RTL (اضغط "الرئيسية" يظهر المؤشر على يمين "خطة")، ولما توصل للتابة الأخيرة (الخطة) ما ترجع للتابات الثانية.
- **الحالة**: تم:
  - بدلنا `Alignment(alignX, 0)` بـ `AlignmentDirectional(alignX, 0)` ليحترم `TextDirection.rtl`، وفلبنا إشارة الـ slide sign حسب `Directionality.of(context)`.
  - بدلنا Stack-of-slots بـ `IndexedStack` — الشاشة النشطة هي الوحيدة المرسومة فوق، فلا تغطي الشاشات الأخرى على التفاعل.
  - الانتقال صار `AnimationController(550ms)` مع `Transform.translate + Transform.scale(0.96→1.0) + Opacity` مطبق على الحاوي كله.
- **الملفات**: `lib/screens/dashboard_screen.dart`.

### 11. الأغاني الرائجة — ضمان 15-20 تراك (لا 6)
- **المطلوب**: شاشة "الأغاني الرائجة" كانت تعرض 6 فقط رغم ادعاء الإصلاح السابق.
- **الحالة**: تم:
  - رفعنا طلب Gemini من 10 → 20 تراكاً + تلميح 2024-2026 لضمان توفرها على iTunes.
  - fallback يدور على 3 مناطق تباعاً (IQ → SA → US) ويدمج بدون تكرار حتى الوصول لـ 20 تراكاً.
  - عتبة الكاش صارت `>= 15` (كانت `>= 10`)، ومفتاح الكاش صار `trending_audio_v3` (كان v2) لإجبار تحديث الكاش القديم.
- **الملفات**: `lib/services/gemini_service.dart`، `lib/providers/analysis_provider.dart`، `lib/services/cache_service.dart`.

### 12. بطاقات التنبؤ أفقياً + padding سفلي للتابات
- **المطلوب**: بطاقات "30 يوم / 90 يوم / الشهر الحالي" كانت تنكسر عمودياً، والتابات السفلية تغطي آخر عنصر في كل قائمة قابلة للتمرير.
- **الحالة**: تم:
  - `_compactForecast` يعمل regex ويمسك الرقم الأمامي فقط (مثلاً `+20-50` بدل "`+20-50 متابع (بافتراض...)`")، ثم `FittedBox + maxLines: 1 + height: 86` يضمن أنها تفضل داخل Row أفقياً.
  - كل الشاشات القابلة للتمرير في الـ dashboard (analysis / videos / suggestions / planner / music) رفعنا الـ `padding.bottom` إلى `120` (كان 20-32) حتى يرتفع المحتوى فوق شريط التنقل.
- **الملفات**: `lib/screens/analysis_screen.dart`، `lib/screens/videos_screen.dart`، `lib/screens/suggestions_screen.dart`، `lib/screens/planner_screen.dart`، `lib/screens/music_screen.dart`.

### 13. زر الأجراس الفوق — Bottom Sheet فيه أبرز التحديثات
- **المطلوب**: أيقونة الأجراس أعلى الـ dashboard كانت ديكورية — المطلوب تصير شغالة وتعرض أبرز التحديثات الي تخص الحساب.
- **الحالة**: تم — ملف جديد `lib/screens/notifications_sheet.dart`:
  - `DraggableScrollableSheet` بخلفية Glass (blur + hairline border)، header بأيقونة جرس + شارة "X جديد".
  - `_buildAlerts(ref)` يولّد التنبيهات من providers موجودة أصلاً:
    - `aiAnalysisProvider.alert` — تنبيه ذكي من تحليل Gemini.
    - `weeklyGrowthProvider` — نمو/تراجع المتابعين هذا الأسبوع.
    - `engagementRateProvider` — نسبة التفاعل مع عتبة ≥3 (good) وإلا warn.
    - AI strengths/weaknesses — أول نقطة قوة وأول فرصة تحسين.
    - `mediaProvider` — أفضل منشور حالياً حسب مجموع التفاعل.
    - `trendingAudioProvider` — عدد الأصوات الصاعدة.
  - `notificationsCount(ref)` يرجع العدد للـ badge على أيقونة الجرس في الـ header.
  - `HeaderIconBtn(icon: notifications_none_rounded, badge: $count, onTap: showNotificationsSheet)` في `_DashboardHeader`.
- **تصميم**: متسق مع باقي الـ Glass components.
- **الملفات**: `lib/screens/notifications_sheet.dart` (جديد)، `lib/screens/dashboard_screen.dart`.

---

## المميزات

### لوحة التحكم الرئيسية
- عرض بيانات الحساب (المتابعون، نسبة التفاعل، النمو الأسبوعي)
- تقييم شامل للحساب من 10 بواسطة Gemini AI
- تنبيهات ذكية وملخص تحليلي مع نقاط القوة والضعف

### التحليل المتقدم
- رسم بياني لنسبة التفاعل خلال آخر 30 يوم
- تحديد أفضل وأضعف منشور تلقائياً
- خريطة حرارية لأوقات النشر (Heatmap)
- تحليل AI للمنافسة مع تحديد أفضل وقت للنشر

### التحليل الجغرافي
- توزيع المتابعين حسب الدول والمدن
- عرض بصري بأشرطة التقدم

### تحليل الفيديوهات
- ترتيب أفضل 10 فيديوهات حسب التفاعل
- تحليل أفضل مدة للفيديو

### الأغاني الرائجة
- عرض الأصوات الرائجة في مجالك مع إمكانية التشغيل (iTunes previews)
- كوفر أرت عالي الدقة 600×600

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
| **Supabase** | المصادقة وقاعدة البيانات + Edge Functions |
| **Instagram Graph API** | جلب بيانات الحساب |
| **Gemini AI** | التحليل الذكي والتوصيات |
| **iTunes Search API** | كوفرات وروابط تشغيل للتراكات |
| **fl_chart** | الرسوم البيانية |
| **Dio** | طلبات HTTP |
| **audioplayers** | تشغيل مقاطع الأغاني |
| **Google Fonts (Cairo)** | الخطوط العربية |

---

## هيكل المشروع

```
lib/
├── main.dart
├── config/
│   ├── app_theme.dart
│   ├── supabase_config.dart
│   ├── gemini_config.dart
│   └── instagram_config.dart
├── models/
│   ├── user_model.dart
│   ├── post_model.dart
│   ├── report_model.dart
│   └── suggestion_model.dart
├── services/
│   ├── auth_service.dart
│   ├── instagram_service.dart
│   ├── gemini_service.dart       # + iTunes enrichment
│   └── cache_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── instagram_provider.dart
│   └── analysis_provider.dart
├── utils/
│   └── tap_feedback.dart          # haptic + sound helper
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── dashboard_screen.dart     # animated tab bar + transitions
│   ├── analysis_screen.dart
│   ├── geo_screen.dart
│   ├── videos_screen.dart
│   ├── music_screen.dart
│   ├── suggestions_screen.dart
│   ├── followers_detail_screen.dart  # clickable cards + reach leaders
│   ├── caption_screen.dart
│   ├── planner_screen.dart
│   └── notifications_sheet.dart      # bell → glass bottom sheet
└── widgets/
    ├── stat_card.dart           # wired to TapFeedback
    ├── post_card.dart           # wired to TapFeedback
    ├── suggestion_card.dart     # wired to TapFeedback
    ├── neumorphic.dart          # wired to TapFeedback
    ├── glass.dart               # HeaderIconBtn wired to TapFeedback
    ├── heatmap_widget.dart
    ├── geo_bar.dart
    └── shimmer_loader.dart
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

## التصميم الحالي

- واجهة داكنة بالكامل (Dark Theme)
- خط Cairo العربي
- دعم كامل لـ RTL
- Glassmorphism (BackdropFilter blur + tint + hairline border)
- Ambient blobs بالخلفية (gradient متحرك)
- ألوان العلامة التجارية (Royal): ذهبي (`accentA` = `#F0B95C`) + بنفسجي (`accentB` = `#A855F7`) + وردي (`accentC` = `#EC4899`)
- تأثيرات حركية بـ `flutter_animate`
- Shimmer loaders أثناء التحميل
- أنيميشن التبديل بين التابات: fade + scale + directional slide
- Bottom nav: sliding pill indicator + elastic icon bounce
- Haptic + system click sound على كل التفاعلات
