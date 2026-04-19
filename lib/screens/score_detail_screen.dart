import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/instagram_provider.dart';
import '../widgets/glass.dart';

Map<String, dynamic> _buildFallback({
  required Map<String, dynamic> ai,
  required double engagement,
  required int postsCount,
}) {
  return {
    'headline': 'تقييم ذكي للحساب',
    'why_this_score': ai['summary'] ??
        'تم احتساب التقييم من بياناتك الحالية: المتابعون، معدل التفاعل، الانتظام في النشر، ونوع المحتوى.',
    'sub_scores': [
      {
        'name': 'جودة المحتوى',
        'score':
            (ai['score_breakdown']?['content_quality'] as num?)?.toDouble() ??
                6.0,
        'note': 'استمر بالتنويع في الأنواع.',
      },
      {
        'name': 'صحة التفاعل',
        'score':
            (ai['score_breakdown']?['engagement_health'] as num?)?.toDouble() ??
                (engagement * 1.5).clamp(0, 10),
        'note': 'ركز على الردود والمحادثة داخل التعليقات.',
      },
      {
        'name': 'الانتظام',
        'score': (ai['score_breakdown']?['consistency'] as num?)?.toDouble() ??
            (postsCount > 20 ? 7.5 : 5),
        'note': postsCount > 20
            ? 'جدول نشر جيد.'
            : 'زد وتيرة النشر لـ 3 مرات أسبوعياً.',
      },
      {
        'name': 'زخم النمو',
        'score':
            (ai['score_breakdown']?['growth_momentum'] as num?)?.toDouble() ??
                6.0,
        'note': 'النمو الحالي ضمن الطبيعي.',
      },
      {
        'name': 'ملاءمة الجمهور',
        'score':
            (ai['score_breakdown']?['audience_fit'] as num?)?.toDouble() ?? 7.0,
        'note': 'المحتوى يناسب الجمهور الحالي.',
      },
    ],
    'to_reach_next_point':
        (ai['action_items_this_week'] as List?)?.cast<String>() ??
            const [
              'انشر ريلز هذا الأسبوع',
              'رد على التعليقات خلال ساعة',
              'جرب هوك مختلف في أول 3 ثوان',
            ],
    'red_flags': (ai['weaknesses'] as List?)?.cast<String>() ?? const [],
    'green_flags': (ai['strengths'] as List?)?.cast<String>() ?? const [],
  };
}

/// Returns the fallback breakdown instantly, then enriches with Claude in the
/// background when it succeeds. The UI never sees an indefinite loading state.
final _scoreBreakdownProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final ai = ref.watch(aiAnalysisProvider).valueOrNull ?? {};
  final engagement = ref.read(engagementRateProvider);
  final posts = ref.read(mediaProvider).valueOrNull ?? [];

  final fallback = _buildFallback(
    ai: ai,
    engagement: engagement,
    postsCount: posts.length,
  );

  if (user == null) return fallback;

  final score = (ai['score'] as num?)?.toDouble() ?? 0;
  final videoCount = posts.where((p) => p.isVideo).length;
  final svc = ref.read(aiServiceProvider);

  try {
    final breakdown = await svc
        .scoreBreakdown(
          username: user.username,
          currentScore: score,
          metrics: {
            'followers': user.followersCount,
            'engagement_rate': engagement,
            'total_posts': posts.length,
            'videos': videoCount,
            'top_country': ref.read(topCountryProvider),
            'monthly_growth_percent': ref.read(monthlyGrowthRateProvider),
          },
        )
        .timeout(const Duration(seconds: 10), onTimeout: () => {});
    if (breakdown.isEmpty) return fallback;
    return breakdown;
  } catch (_) {
    return fallback;
  }
});

class ScoreDetailScreen extends ConsumerWidget {
  const ScoreDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_scoreBreakdownProvider);
    final ai = ref.watch(aiAnalysisProvider).valueOrNull ?? {};
    final baseScore = (ai['score'] as num?)?.toDouble() ?? 0;
    final engagement = ref.watch(engagementRateProvider);
    final postsCount = ref.watch(mediaProvider).valueOrNull?.length ?? 0;

    final data = async.maybeWhen(
      data: (d) => d,
      orElse: () => _buildFallback(
        ai: ai,
        engagement: engagement,
        postsCount: postsCount,
      ),
    );
    final isEnriching = async.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBlobs(opacity: 0.7)),
          SafeArea(
            child: Column(
              children: [
                _DetailAppBar(
                  title: 'تقييم الحساب الشامل',
                  subtitle: 'تحليل كل بند بمعزل عن الآخر',
                  loading: isEnriching,
                ),
                Expanded(
                  child: _ScoreBody(data: data, score: baseScore),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final double score;
  const _ScoreBody({required this.data, required this.score});

  @override
  Widget build(BuildContext context) {
    final subScores = (data['sub_scores'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final toNext = (data['to_reach_next_point'] as List<dynamic>? ?? const [])
        .cast<String>();
    final red = (data['red_flags'] as List<dynamic>? ?? const []).cast<String>();
    final green = (data['green_flags'] as List<dynamic>? ?? const [])
        .cast<String>();
    final percentile =
        (data['percentile_vs_niche'] as num?)?.toDouble() ?? 72;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        // Hero score.
        Glass(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome,
                      size: 14, color: AppColors.accentB),
                  SizedBox(width: 6),
                  Text(
                    'تقييم AI',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.accentB,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  GradientText(
                    score.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 0.9,
                    ),
                  ),
                  const Text(
                    '/10',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                (data['headline'] as String?) ?? 'تقييم ممتاز',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (data['why_this_score'] as String?) ??
                    'تم احتساب التقييم بناءً على خمسة محاور.',
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 12.5,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  GlassChip(
                    color: AppColors.accentB,
                    child: Text('تتفوق على ${percentile.toStringAsFixed(0)}٪'),
                  ),
                  const SizedBox(width: 6),
                  GlassChip(
                    color: AppColors.good,
                    child: const Text('التحليل مُحدث لحظياً'),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 16),

        const _SectionLabel(icon: Icons.segment, text: 'المحاور الفرعية'),
        const SizedBox(height: 8),
        ...subScores.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SubScoreRow(
              name: (s['name'] as String?) ?? 'محور',
              score: (s['score'] as num?)?.toDouble() ?? 0,
              note: (s['note'] as String?) ?? '',
            ),
          ).animate().fadeIn(delay: (120 + 80 * i).ms, duration: 300.ms);
        }),

        const SizedBox(height: 12),
        const _SectionLabel(
            icon: Icons.flag_outlined, text: 'للوصول إلى النقطة التالية'),
        const SizedBox(height: 8),
        Glass(
          radius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: toNext
                .asMap()
                .entries
                .map(
                  (e) => Padding(
                    padding: EdgeInsets.only(
                        bottom: e.key == toNext.length - 1 ? 0 : 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradientSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        if (green.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionLabel(
              icon: Icons.trending_up, text: 'إشارات إيجابية'),
          const SizedBox(height: 8),
          _FlagList(items: green, color: AppColors.good),
        ],

        if (red.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionLabel(
              icon: Icons.error_outline, text: 'نقاط تحتاج انتباه'),
          const SizedBox(height: 8),
          _FlagList(items: red, color: AppColors.warn),
        ],
      ],
    );
  }
}

class _SubScoreRow extends StatelessWidget {
  final String name;
  final double score;
  final String note;
  const _SubScoreRow({
    required this.name,
    required this.score,
    required this.note,
  });

  Color get _color {
    if (score >= 8) return AppColors.good;
    if (score >= 5.5) return AppColors.accentB;
    return AppColors.warn;
  }

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)}/10',
                style: TextStyle(
                  color: _color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (score / 10).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: const TextStyle(
                color: AppColors.textSoft,
                fontSize: 11.5,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlagList extends StatelessWidget {
  final List<String> items;
  final Color color;
  const _FlagList({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.55),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12.5,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.accentB),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool loading;
  const _DetailAppBar({
    required this.title,
    this.subtitle,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          HeaderIconBtn(
            icon: Icons.arrow_forward,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (loading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accentB),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    loading ? 'جاري تحديث التحليل…' : subtitle!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
