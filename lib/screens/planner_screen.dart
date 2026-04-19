import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/analysis_provider.dart';
import '../services/cache_service.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/neumorphic.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  Future<void> _regenerate() async {
    final cache = await CacheService.getInstance();
    await cache.clear(CacheService.keyWeeklyPlan);
    ref.invalidate(weeklyPlanProvider);
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(weeklyPlanProvider);
    final report = ref.watch(weeklyReportProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('الخطة الأسبوعية', style: TextStyle(color: AppColors.text)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.muted),
            onPressed: _regenerate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklyReport(report),
            const SizedBox(height: 16),
            _buildPlanHeader(plan),
            const SizedBox(height: 12),
            _buildDaysList(plan),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyReport(AsyncValue<Map<String, dynamic>> report) {
    return report.when(
      loading: () => const ShimmerLoader(height: 140),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        final score = data['overall_score']?.toString() ?? '-';
        final summary = data['summary'] as String?;
        final trend = data['engagement_trend'] as String?;
        final recommendation = data['recommendation'] as String?;
        final highlights = (data['highlights'] as List<dynamic>?)?.cast<String>() ?? [];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: NeumorphicDecoration.raisedGold(radius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const NeumorphicIconBadge(
                    icon: Icons.assessment,
                    color: AppColors.accentGold,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                    child: const Text('تقرير الأسبوع',
                        style: TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        )),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$score/10',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold,
                        )),
                  ),
                ],
              ),
              if (summary != null) ...[
                const SizedBox(height: 12),
                Text(summary,
                    style: const TextStyle(color: AppColors.text, fontSize: 12, height: 1.5)),
              ],
              if (trend != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.trending_up, size: 14, color: AppColors.accentGoldBright),
                  const SizedBox(width: 4),
                  Expanded(child: Text(trend,
                      style: const TextStyle(
                        color: AppColors.accentGoldBright, fontSize: 12, fontWeight: FontWeight.w600,
                      ))),
                ]),
              ],
              if (highlights.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...highlights.take(2).map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('★ ', style: TextStyle(color: AppColors.accentGold)),
                        Expanded(child: Text(h,
                            style: const TextStyle(
                              color: AppColors.text, fontSize: 12, height: 1.4,
                            ))),
                      ]),
                    )),
              ],
              if (recommendation != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: NeumorphicDecoration.pressed(radius: 12, offset: 3, blur: 6),
                  child: Row(children: [
                    const Icon(Icons.lightbulb, size: 14, color: AppColors.accentGoldBright),
                    const SizedBox(width: 6),
                    Expanded(child: Text(recommendation,
                        style: const TextStyle(color: AppColors.text, fontSize: 11, height: 1.4))),
                  ]),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _buildPlanHeader(AsyncValue<Map<String, dynamic>> plan) {
    return plan.when(
      loading: () => const ShimmerLoader(height: 60),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        final theme = data['week_theme'] as String?;
        final growth = data['expected_growth'] as String?;
        if (theme == null && growth == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: NeumorphicDecoration.raised(radius: 18, offset: 4, blur: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (theme != null)
                Row(children: [
                  const Icon(Icons.auto_awesome, size: 16, color: AppColors.accentGold),
                  const SizedBox(width: 6),
                  Expanded(child: Text('موضوع الأسبوع: $theme',
                      style: const TextStyle(
                        color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.w600,
                      ))),
                ]),
              if (growth != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.trending_up, size: 14, color: AppColors.accentGoldBright),
                  const SizedBox(width: 6),
                  Expanded(child: Text(growth,
                      style: const TextStyle(color: AppColors.muted, fontSize: 11))),
                ]),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _buildDaysList(AsyncValue<Map<String, dynamic>> plan) {
    return plan.when(
      loading: () => const ShimmerCardList(count: 7, cardHeight: 90),
      error: (e, _) => Center(child: Text('خطأ: $e',
          style: const TextStyle(color: AppColors.muted))),
      data: (data) {
        final days = (data['days'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        if (days.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: NeumorphicDecoration.raised(radius: 18),
            child: Column(
              children: [
                Icon(Icons.event_note, size: 40,
                    color: AppColors.muted.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                const Text('لم يتم توليد خطة بعد',
                    style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                NeumorphicButton(
                  onPressed: _regenerate,
                  gold: true,
                  radius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: const Text('توليد خطة جديدة',
                      style: TextStyle(
                        color: AppColors.accentGoldBright,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          );
        }

        return Column(
          children: List.generate(days.length, (i) {
            final day = days[i];
            return _buildDayCard(day, i);
          }),
        );
      },
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day, int index) {
    final dayName = day['day'] as String? ?? '';
    final contentType = day['content_type'] as String? ?? '';
    final title = day['title'] as String? ?? '';
    final description = day['description'] as String? ?? '';
    final bestTime = day['best_time'] as String? ?? '';
    final expectedEng = day['expected_engagement'] as String? ?? '';

    IconData icon;
    Color color;
    switch (contentType.toLowerCase()) {
      case 'reel':
      case 'reels':
        icon = Icons.play_circle;
        color = AppColors.accentGold;
        break;
      case 'story':
        icon = Icons.auto_stories;
        color = AppColors.accentGoldBright;
        break;
      case 'post':
      case 'carousel':
        icon = Icons.photo_library;
        color = AppColors.accentAluminum;
        break;
      default:
        icon = Icons.article;
        color = AppColors.accentGold;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicDecoration.raised(radius: 20, offset: 5, blur: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeumorphicIconBadge(icon: icon, color: color, size: 38),
              const SizedBox(width: 12),
              Text(dayName,
                  style: const TextStyle(
                    color: AppColors.text, fontSize: 14, fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  )),
              const Spacer(),
              if (bestTime.isNotEmpty)
                Row(children: [
                  const Icon(Icons.schedule, size: 12, color: AppColors.muted),
                  const SizedBox(width: 3),
                  Text(bestTime,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.muted, fontSize: 11,
                      )),
                ]),
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 4),
          Text(description,
              style: const TextStyle(color: AppColors.text, fontSize: 12, height: 1.4)),
          if (expectedEng.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: NeumorphicDecoration.pressed(radius: 8, offset: 2, blur: 4),
              child: Text('تفاعل متوقع: $expectedEng',
                  style: const TextStyle(
                    color: AppColors.accentGoldBright, fontSize: 10, fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: index * 70),
          duration: 400.ms,
        ).slideX(begin: 0.05);
  }
}
