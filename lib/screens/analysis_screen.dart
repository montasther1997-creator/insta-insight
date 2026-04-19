import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/instagram_provider.dart';
import '../providers/analysis_provider.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/post_card.dart';
import '../widgets/neumorphic.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProvider);
    final engagement = ref.watch(engagementRateProvider);
    final aiAnalysis = ref.watch(aiAnalysisProvider);
    final followersData = ref.watch(followersOverTimeProvider);
    final bestDay = ref.watch(bestPostingDayProvider);
    final bestHour = ref.watch(bestPostingHourProvider);
    final freq = ref.watch(postingFrequencyProvider);
    final monthlyGrowth = ref.watch(monthlyGrowthRateProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('التحليل', style: TextStyle(color: AppColors.text)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGrowthForecastCard(aiAnalysis, monthlyGrowth),
            const SizedBox(height: 16),

            _buildEngagementChart(engagement, followersData),
            const SizedBox(height: 16),

            _buildBestTimesRow(bestDay, bestHour, freq),
            const SizedBox(height: 16),

            mediaState.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(
                    child: Text('لا توجد منشورات', style: TextStyle(color: AppColors.muted)),
                  );
                }

                final sorted = [...posts]
                  ..sort((a, b) => b.totalEngagement.compareTo(a.totalEngagement));
                final best = sorted.first;
                final worst = sorted.last;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('أفضل منشور',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        )).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 10),
                    PostCard(post: best, rank: 1),
                    const SizedBox(height: 16),
                    const Text('أضعف منشور',
                        style: TextStyle(
                          color: AppColors.accentAluminum,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        )).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 8),
                    PostCard(post: worst),
                  ],
                );
              },
              loading: () => const ShimmerCardList(count: 2, cardHeight: 120),
              error: (e, _) => Text('خطأ: $e'),
            ),
            const SizedBox(height: 20),

            const HeatmapWidget().animate().fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 20),

            _buildHookTipsSection(aiAnalysis),
            const SizedBox(height: 16),

            _buildCompetitorSection(aiAnalysis),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthForecastCard(
      AsyncValue<Map<String, dynamic>> aiAnalysis, double monthlyGrowth) {
    return aiAnalysis.when(
      loading: () => const ShimmerLoader(height: 140),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final forecast30 = data['growth_forecast_30d'];
        final forecast90 = data['growth_forecast_90d'];
        final goal = data['realistic_goal_month'] as String?;
        final niche = data['niche'] as String?;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: NeumorphicDecoration.raisedGold(radius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const NeumorphicIconBadge(
                    icon: Icons.trending_up,
                    color: AppColors.accentGold,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                    child: const Text('التوقعات والنمو',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        )),
                  ),
                  const Spacer(),
                  if (niche != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: NeumorphicDecoration.pressed(radius: 10, offset: 2, blur: 4),
                      child: Text('المجال: $niche',
                          style: const TextStyle(
                            color: AppColors.accentGoldBright,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _forecastBlock('30 يوم', '+${forecast30 ?? '-'}', 'متابع', AppColors.accentGold),
                  const SizedBox(width: 10),
                  _forecastBlock('90 يوم', '+${forecast90 ?? '-'}', 'متابع', AppColors.accentGoldBright),
                  const SizedBox(width: 10),
                  _forecastBlock('شهري', '${monthlyGrowth.toStringAsFixed(1)}%', 'حالي', AppColors.accentAluminum),
                ],
              ),
              if (goal != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: NeumorphicDecoration.pressed(radius: 12, offset: 3, blur: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, size: 14, color: AppColors.accentGoldBright),
                      const SizedBox(width: 6),
                      const Text('هدف شهري:',
                          style: TextStyle(
                            color: AppColors.accentGoldBright,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(goal,
                              style: const TextStyle(
                                color: AppColors.text, fontSize: 12, height: 1.4))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 400.ms);
      },
    );
  }

  Widget _forecastBlock(String title, String value, String subtitle, Color color) {
    // Gemini sometimes returns verbose values like "20-50+ متابع (بافتراض ...)"
    // — strip anything after the first number-ish chunk so the 3-column row
    // stays horizontal instead of breaking into tall wrapped cells.
    final compactValue = _compactForecast(value);
    return Expanded(
      child: Container(
        height: 86,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: NeumorphicDecoration.raised(radius: 16, offset: 4, blur: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(compactValue,
                  maxLines: 1,
                  style: GoogleFonts.jetBrainsMono(
                    color: color, fontSize: 16, fontWeight: FontWeight.bold,
                  )),
            ),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // Keep only the leading numeric / range portion of Gemini's forecast string.
  // Examples: "+20-50+ متابع (بافتراض ...)" → "+20-50+", "+15 متابع جديد" → "+15".
  String _compactForecast(String v) {
    final match = RegExp(r'^[+\-]?[\d٠-٩]+(?:[\-\u2013][+\-]?[\d٠-٩]+)?\+?%?')
        .firstMatch(v.trim());
    if (match != null) return match.group(0) ?? v;
    // Percentage values like "13.39%" keep as-is.
    final pct = RegExp(r'^[+\-]?[\d٠-٩]+(?:\.[\d٠-٩]+)?%').firstMatch(v.trim());
    if (pct != null) return pct.group(0) ?? v;
    return v;
  }

  Widget _buildBestTimesRow(Map<String, dynamic> day, Map<String, dynamic> hour, double freq) {
    return Row(
      children: [
        _timeCard(Icons.calendar_today, 'أفضل يوم', day['day']?.toString() ?? '-', AppColors.accentGold),
        const SizedBox(width: 10),
        _timeCard(Icons.schedule, 'أفضل ساعة', hour['hour']?.toString() ?? '-', AppColors.accentGoldBright),
        const SizedBox(width: 10),
        _timeCard(Icons.replay, 'معدل النشر', '${freq.toStringAsFixed(1)}/أسبوع', AppColors.accentAluminum),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _timeCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: NeumorphicDecoration.raised(radius: 18, offset: 4, blur: 10),
        child: Column(
          children: [
            NeumorphicIconBadge(icon: icon, color: color, size: 34),
            const SizedBox(height: 6),
            Text(value,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildHookTipsSection(AsyncValue<Map<String, dynamic>> aiAnalysis) {
    return aiAnalysis.when(
      loading: () => const ShimmerLoader(height: 100),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final hookTips = (data['hook_tips'] as List<dynamic>?)?.cast<String>() ?? [];
        final retentionTips = (data['retention_tips'] as List<dynamic>?)?.cast<String>() ?? [];
        if (hookTips.isEmpty && retentionTips.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: NeumorphicDecoration.raised(radius: 22, offset: 5, blur: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const NeumorphicIconBadge(
                  icon: Icons.flash_on,
                  color: AppColors.accentGold,
                  size: 36,
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                  child: const Text('نصائح الهوك والاحتفاظ',
                      style: TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      )),
                ),
              ]),
              const SizedBox(height: 12),
              if (hookTips.isNotEmpty) ...[
                const Text('الثواني 3 الأولى',
                    style: TextStyle(
                      color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 6),
                ...hookTips.take(3).map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('▸ ', style: TextStyle(color: AppColors.accentGold, fontSize: 12)),
                        Expanded(child: Text(t,
                            style: const TextStyle(color: AppColors.text, fontSize: 12, height: 1.4))),
                      ]),
                    )),
              ],
              if (retentionTips.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('الاحتفاظ بالمشاهد',
                    style: TextStyle(
                      color: AppColors.accentGoldBright, fontSize: 12, fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 6),
                ...retentionTips.take(3).map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('▸ ', style: TextStyle(color: AppColors.accentGoldBright, fontSize: 12)),
                        Expanded(child: Text(t,
                            style: const TextStyle(color: AppColors.text, fontSize: 12, height: 1.4))),
                      ]),
                    )),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 350.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildEngagementChart(
      double currentEngagement, AsyncValue<List<Map<String, dynamic>>> followersData) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: NeumorphicDecoration.raised(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: const Text('نسبة التفاعل',
                  style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  )),
            ),
            const Spacer(),
            const Text('آخر 30 يوم',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text('${currentEngagement.toStringAsFixed(2)}%',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.accentGold, fontSize: 30, fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: followersData.when(
              data: (dataPoints) {
                final spots = <FlSpot>[];
                if (dataPoints.isNotEmpty) {
                  for (int i = 0; i < dataPoints.length; i++) {
                    final value = (dataPoints[i]['value'] as int?)?.toDouble() ?? 0;
                    spots.add(FlSpot(i.toDouble(), value));
                  }
                } else {
                  spots.add(FlSpot(0, currentEngagement));
                }
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _calcInterval(spots),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.surface2, strokeWidth: 0.5,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (spots.length / 5).ceilToDouble().clamp(1, 30),
                          getTitlesWidget: (value, meta) {
                            final day = value.toInt() + 1;
                            return Text('$day',
                                style: const TextStyle(color: AppColors.muted, fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            return Text(_formatChartValue(value),
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.muted, fontSize: 10,
                                ));
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        gradient: AppColors.goldGradient,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentGold.withValues(alpha: 0.25),
                              AppColors.accentGold.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: Text('تعذر تحميل بيانات الرسم البياني',
                    style: TextStyle(color: AppColors.muted)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  double _calcInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;
    if (range <= 0) return 1;
    return (range / 4).ceilToDouble().clamp(1, double.infinity);
  }

  String _formatChartValue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  Widget _buildCompetitorSection(AsyncValue<Map<String, dynamic>> aiAnalysis) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: NeumorphicDecoration.raised(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const NeumorphicIconBadge(
              icon: Icons.compare_arrows,
              color: AppColors.accentGold,
              size: 36,
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: const Text('مقارنة مع السوق',
                  style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  )),
            ),
          ]),
          const SizedBox(height: 14),
          aiAnalysis.when(
            data: (data) {
              final strengths = (data['strengths'] as List<dynamic>?)?.cast<String>() ?? [];
              final weaknesses = (data['weaknesses'] as List<dynamic>?)?.cast<String>() ?? [];
              final bestTime = data['best_post_time'] as String?;
              final benchmarks = data['market_benchmarks'] as Map<String, dynamic>?;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (benchmarks != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: NeumorphicDecoration.pressed(radius: 12, offset: 3, blur: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.insights, size: 16, color: AppColors.accentGoldBright),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'متوسط المجال: ${benchmarks['avg_engagement_in_niche']}% — ${benchmarks['user_vs_avg']}',
                              style: const TextStyle(
                                color: AppColors.text, fontSize: 12, height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (bestTime != null) ...[
                    Row(children: [
                      const Icon(Icons.schedule, size: 16, color: AppColors.accentGoldBright),
                      const SizedBox(width: 6),
                      Text('أفضل وقت للنشر: $bestTime',
                          style: const TextStyle(
                            color: AppColors.accentGoldBright, fontSize: 13, fontWeight: FontWeight.w600,
                          )),
                    ]),
                    const SizedBox(height: 12),
                  ],
                  if (strengths.isNotEmpty) ...strengths.take(2).map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('  +  ',
                              style: TextStyle(color: AppColors.accentGold, fontSize: 13)),
                          Expanded(
                              child: Text(s,
                                  style: const TextStyle(
                                      color: AppColors.text, fontSize: 12, height: 1.4))),
                        ]),
                      )),
                  if (weaknesses.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...weaknesses.take(2).map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('  -  ',
                                style: TextStyle(color: AppColors.accentAluminum, fontSize: 13)),
                            Expanded(
                                child: Text(w,
                                    style: const TextStyle(
                                        color: AppColors.text, fontSize: 12, height: 1.4))),
                          ]),
                        )),
                  ],
                  if (strengths.isEmpty && weaknesses.isEmpty)
                    const Text('لا يتوفر تحليل بعد',
                        style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              );
            },
            loading: () => const ShimmerLoader(height: 80),
            error: (_, _) => const Text('تعذر تحميل التحليل',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          const Text('التحليل مبني على AI',
              style: TextStyle(color: AppColors.muted, fontSize: 10)),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }
}
