import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/post_model.dart';
import '../providers/instagram_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/shimmer_loader.dart';

class VideosScreen extends ConsumerWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(videoPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('الفيديوهات', style: TextStyle(color: AppColors.text)),
        automaticallyImplyLeading: false,
      ),
      body: videosState.when(
        data: (videos) {
          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off_outlined,
                    size: 60,
                    color: AppColors.muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد فيديوهات بعد',
                    style: TextStyle(color: AppColors.muted, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ستظهر فيديوهاتك هنا بعد تسجيل الدخول',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          final topVideos = videos.take(10).toList();

          return CustomScrollView(
            slivers: [
              // Best duration card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildBestDurationCard(topVideos),
                ),
              ),
              // Video list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return PostCard(
                        post: topVideos[index],
                        rank: index + 1,
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: index * 80),
                            duration: 400.ms,
                          );
                    },
                    childCount: topVideos.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: ShimmerCardList(count: 5, cardHeight: 120),
        ),
        error: (e, _) => Center(
          child: Text('خطأ: $e', style: const TextStyle(color: AppColors.muted)),
        ),
      ),
    );
  }

  Widget _buildBestDurationCard(List<PostModel> videos) {
    // Calculate best performing video type based on engagement
    String bestDuration = 'غير محدد';
    String subtitle = 'ننتظر بيانات أكثر للتحليل';

    if (videos.length >= 3) {
      // Sort by engagement and take top 30%
      final sorted = [...videos]
        ..sort((a, b) => b.totalEngagement.compareTo(a.totalEngagement));
      final topCount = (sorted.length * 0.3).ceil().clamp(1, sorted.length);
      final topVideos = sorted.take(topCount).toList();

      // Check media types distribution in top videos
      final reelsCount = topVideos.where((v) => v.mediaType == 'REELS').length;
      final videoCount = topVideos.where((v) => v.mediaType == 'VIDEO').length;

      if (reelsCount > videoCount) {
        bestDuration = 'ريلز قصيرة';
        subtitle = 'الريلز تحقق تفاعل أعلى بـ ${((reelsCount / topCount) * 100).toStringAsFixed(0)}%';
      } else if (videoCount > reelsCount) {
        bestDuration = 'فيديو طويل';
        subtitle = 'الفيديوهات الطويلة تحقق أداء أفضل عندك';
      } else {
        bestDuration = 'متنوع';
        subtitle = 'كلا النوعين يحقق أداء جيد';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentBlue.withValues(alpha: 0.15),
            AppColors.accentGreen.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.timer, color: AppColors.accentBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أفضل نوع فيديو لجمهورك',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  bestDuration,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.accentBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
