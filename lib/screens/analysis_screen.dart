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

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProvider);
    final engagement = ref.watch(engagementRateProvider);
    final aiAnalysis = ref.watch(aiAnalysisProvider);
    final followersData = ref.watch(followersOverTimeProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('التحليل', style: TextStyle(color: AppColors.text)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Engagement chart with real followers data
            _buildEngagementChart(engagement, followersData),
            const SizedBox(height: 20),

            // Best & worst posts
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
                    const Text(
                      'أفضل منشور',
                      style: TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 8),
                    PostCard(post: best, rank: 1),
                    const SizedBox(height: 16),
                    const Text(
                      'أضعف منشور',
                      style: TextStyle(
                        color: AppColors.accentPink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 8),
                    PostCard(post: worst),
                  ],
                );
              },
              loading: () => const ShimmerCardList(count: 2, cardHeight: 120),
              error: (e, _) => Text('خطأ: $e'),
            ),
            const SizedBox(height: 20),

            // Posting heatmap
            const HeatmapWidget().animate().fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 20),

            // AI-powered competitor comparison
            _buildCompetitorSection(aiAnalysis),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart(
      double currentEngagement, AsyncValue<List<Map<String, dynamic>>> followersData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'نسبة التفاعل',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Text(
                'آخر 30 يوم',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${currentEngagement.toStringAsFixed(2)}%',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.accentPurple,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                  // Fallback: single point with current engagement
                  spots.add(FlSpot(0, currentEngagement));
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _calcInterval(spots),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.surface2,
                        strokeWidth: 0.5,
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
                            return Text(
                              '$day',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _formatChartValue(value),
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        gradient: AppColors.primaryGradient,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentPurple.withValues(alpha: 0.2),
                              AppColors.accentPurple.withValues(alpha: 0.0),
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
              error: (_, __) => const Center(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows, color: AppColors.accentBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'تحليل AI للمنافسة',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          aiAnalysis.when(
            data: (data) {
              final strengths = (data['strengths'] as List<dynamic>?)?.cast<String>() ?? [];
              final weaknesses = (data['weaknesses'] as List<dynamic>?)?.cast<String>() ?? [];
              final bestTime = data['best_post_time'] as String?;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bestTime != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: AppColors.accentAmber),
                        const SizedBox(width: 6),
                        Text(
                          'أفضل وقت للنشر: $bestTime',
                          style: const TextStyle(
                            color: AppColors.accentAmber,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (strengths.isNotEmpty) ...[
                    ...strengths.take(2).map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('  +  ',
                                  style: TextStyle(color: AppColors.accentGreen, fontSize: 13)),
                              Expanded(
                                child: Text(s,
                                    style: const TextStyle(
                                        color: AppColors.text, fontSize: 12, height: 1.4)),
                              ),
                            ],
                          ),
                        )),
                  ],
                  if (weaknesses.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...weaknesses.take(2).map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('  -  ',
                                  style: TextStyle(color: AppColors.accentPink, fontSize: 13)),
                              Expanded(
                                child: Text(w,
                                    style: const TextStyle(
                                        color: AppColors.text, fontSize: 12, height: 1.4)),
                              ),
                            ],
                          ),
                        )),
                  ],
                  if (strengths.isEmpty && weaknesses.isEmpty)
                    const Text(
                      'لا يتوفر تحليل بعد',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                ],
              );
            },
            loading: () => const ShimmerLoader(height: 80),
            error: (_, __) => const Text(
              'تعذر تحميل التحليل',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'التحليل مبني على Gemini AI',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }
}
