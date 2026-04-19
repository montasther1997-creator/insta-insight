import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/post_model.dart';
import '../providers/instagram_provider.dart';
import '../providers/analysis_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/neumorphic.dart';
import 'post_detail_screen.dart';
import 'music_screen.dart';
import '../models/suggestion_model.dart';

class VideosScreen extends ConsumerWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(videoPostsProvider);
    final typeStats = ref.watch(mediaTypeDistributionProvider);
    final videoAnalysis = ref.watch(videoAnalysisProvider);
    final realHashtags = ref.watch(topHashtagsProvider);

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
                  Icon(Icons.videocam_off_outlined, size: 60,
                      color: AppColors.muted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('لا توجد فيديوهات بعد',
                      style: TextStyle(color: AppColors.muted, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('ستظهر فيديوهاتك هنا بعد تسجيل الدخول',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            );
          }

          final topVideos = videos.take(10).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryStats(videos),
                      const SizedBox(height: 12),
                      _buildMediaTypeComparison(typeStats),
                      const SizedBox(height: 12),
                      _buildAiVideoAnalysis(videoAnalysis, realHashtags),
                      const SizedBox(height: 12),
                      _TrendingAudioInline(
                        audio: ref.watch(trendingAudioProvider),
                      ),
                      const SizedBox(height: 8),
                      _buildSectionHeader('أفضل 10 فيديوهات'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final v = topVideos[index];
                      return PostCard(
                        post: v,
                        rank: index + 1,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(post: v),
                          ),
                        ),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: index * 60),
                            duration: 400.ms,
                          );
                    },
                    childCount: topVideos.length,
                  ),
                ),
              ),
              // Leave room so the floating gold tab pill never overlaps the
              // last video row (nav height + safe area ~= 110).
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(List<PostModel> videos) {
    final avgLikes = videos.fold<int>(0, (s, v) => s + v.likesCount) / videos.length;
    final avgComments = videos.fold<int>(0, (s, v) => s + v.commentsCount) / videos.length;
    final avgViews = videos.fold<int>(0, (s, v) => s + v.viewsCount) / videos.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicDecoration.raised(radius: 22, offset: 5, blur: 12),
      child: Row(
        children: [
          _statBlock(Icons.favorite_outline, 'لايك', _fmt(avgLikes.round()), AppColors.accentGold),
          _statDivider(),
          _statBlock(Icons.chat_bubble_outline, 'تعليق', _fmt(avgComments.round()), AppColors.accentGoldBright),
          _statDivider(),
          _statBlock(Icons.visibility_outlined, 'مشاهدة', _fmt(avgViews.round()), AppColors.accentAluminum),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _statBlock(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          NeumorphicIconBadge(icon: icon, color: color, size: 34),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                color: color, fontSize: 14, fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 2),
          Text('متوسط $label',
              style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _statDivider() =>
      Container(width: 1, height: 40, color: AppColors.shadowDark);

  Widget _buildMediaTypeComparison(Map<String, Map<String, num>> stats) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final reels = stats['REELS'] ?? {};
    final videos = stats['VIDEO'] ?? {};
    final images = stats['IMAGE'] ?? {};
    final carousel = stats['CAROUSEL_ALBUM'] ?? {};

    final hasAny = (reels['count'] ?? 0) > 0 ||
        (videos['count'] ?? 0) > 0 ||
        (images['count'] ?? 0) > 0 ||
        (carousel['count'] ?? 0) > 0;
    if (!hasAny) return const SizedBox.shrink();

    String best = 'غير محدد';
    double bestEng = 0;
    void check(String name, Map<String, num> s) {
      final avg = (s['avg_engagement'] ?? 0).toDouble();
      if (avg > bestEng) {
        bestEng = avg;
        best = name;
      }
    }
    check('ريلز', reels);
    check('فيديو', videos);
    check('صورة', images);
    check('كاروسيل', carousel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicDecoration.raisedGold(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NeumorphicIconBadge(
                icon: Icons.compare_arrows,
                color: AppColors.accentGold,
                size: 32,
              ),
              const SizedBox(width: 8),
              const Text('مقارنة أنواع المحتوى',
                  style: TextStyle(
                    color: AppColors.text, fontSize: 13, fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('الأفضل: $best',
                    style: const TextStyle(
                      color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _typeRow('ريلز', reels, AppColors.accentGold),
          _typeRow('فيديو', videos, AppColors.accentGoldBright),
          _typeRow('صور', images, AppColors.accentAluminum),
          _typeRow('كاروسيل', carousel, AppColors.accentGold),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _typeRow(String label, Map<String, num> s, Color color) {
    final count = (s['count'] ?? 0).toInt();
    if (count == 0) return const SizedBox.shrink();
    final avgEng = (s['avg_engagement'] ?? 0).toDouble().round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text(label, style: const TextStyle(color: AppColors.text, fontSize: 12))),
          Text('$count منشور',
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const Spacer(),
          Text('${_fmt(avgEng)} تفاعل',
              style: GoogleFonts.jetBrainsMono(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAiVideoAnalysis(
    AsyncValue<Map<String, dynamic>> analysis,
    List<Map<String, dynamic>> realHashtags,
  ) {
    return analysis.when(
      loading: () => const ShimmerLoader(height: 120),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.isEmpty && realHashtags.isEmpty) {
          return const SizedBox.shrink();
        }
        final hook = data['hook_analysis'] as String?;
        final retention = data['retention_strategy'] as String?;
        final duration = data['optimal_duration'] as String?;
        final tips =
            (data['improvement_tips'] as List<dynamic>?)?.cast<String>() ?? [];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: NeumorphicDecoration.raised(radius: 22, offset: 5, blur: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const NeumorphicIconBadge(
                    icon: Icons.auto_awesome,
                    color: AppColors.accentGold,
                    size: 34,
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                    child: const Text('تحليل AI للفيديوهات',
                        style: TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (duration != null) _infoRow(Icons.timer_outlined, 'المدة المثالية', duration, AppColors.accentGoldBright),
              if (hook != null) _infoRow(Icons.flash_on, 'تحليل الهوك', hook, AppColors.accentGold),
              if (retention != null) _infoRow(Icons.visibility_outlined, 'الاحتفاظ بالمشاهد', retention, AppColors.accentAluminum),
              _buildHashtagsSection(realHashtags),
              if (tips.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...tips.take(3).map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(color: AppColors.accentGoldBright, fontSize: 12)),
                          Expanded(
                              child: Text(t,
                                  style: const TextStyle(color: AppColors.text, fontSize: 12, height: 1.4))),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
      },
    );
  }

  /// Real hashtags extracted from the user's own post captions, ranked by
  /// engagement. Shows up to 10 with usage counts. Falls back to a helpful
  /// empty state when the account hasn't used any hashtags yet.
  Widget _buildHashtagsSection(List<Map<String, dynamic>> hashtags) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'هاشتاقاتك الأعلى تفاعلاً',
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.good.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'محدّث فعلياً',
                  style: TextStyle(
                    color: AppColors.good,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hashtags.isEmpty)
            Text(
              'لم نعثر على هاشتاقات في كابشن منشوراتك بعد. أضف 3-5 هاشتاقات متنوعة (شائع، متخصص، علامتك) في منشوراتك القادمة وسيظهر تحليلها هنا.',
              style: const TextStyle(
                color: AppColors.textSoft,
                fontSize: 11.5,
                height: 1.6,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: hashtags.take(10).map((h) {
                final tag = h['tag'] as String;
                final count = h['count'] as int;
                final engagement = h['engagement'] as int;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: NeumorphicDecoration.raised(
                      radius: 10, offset: 2, blur: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$tag',
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '×$count · ${_fmt(engagement)}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: AppColors.text, fontSize: 11, height: 1.4))),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

/// Prominent teaser block for trending audio — tapping opens the full screen.
/// Renders the top 3 tracks so the user sees real signal without leaving.
class _TrendingAudioInline extends StatelessWidget {
  final AsyncValue<List<TrendingAudio>> audio;
  const _TrendingAudioInline({required this.audio});

  @override
  Widget build(BuildContext context) {
    return audio.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final top = list.take(3).toList();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MusicScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentGold.withValues(alpha: 0.18),
                  AppColors.accentB.withValues(alpha: 0.13),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.graphic_eq,
                          color: Colors.black, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'الأغاني الترند الآن',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'محدّث كل 12 ساعة من تيك توك',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'عرض الكل',
                            style: TextStyle(
                              color: AppColors.accentGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_back_ios,
                              size: 10, color: AppColors.accentGold),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...top.asMap().entries.map((e) {
                  final i = e.key;
                  final a = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: i == 0
                                  ? AppColors.accentGold
                                  : AppColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.audioName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                a.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (a.isRising)
                          const Icon(Icons.trending_up,
                              size: 14, color: AppColors.accentGold),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
      },
    );
  }
}
