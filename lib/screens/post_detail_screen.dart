import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../models/post_model.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/instagram_provider.dart';
import '../widgets/glass.dart';

/// Deep-dive view for a single post/video: media, caption, full stats,
/// extracted hashtags, and an AI verdict on why it did or didn't trend.
class PostDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  Future<String>? _analysis;

  @override
  void initState() {
    super.initState();
    _analysis = _runAnalysis();
  }

  Future<String> _runAnalysis() async {
    final ai = ref.read(aiServiceProvider);
    return ai.analyzePost(
      mediaType: widget.post.mediaType,
      likes: widget.post.likesCount,
      comments: widget.post.commentsCount,
      views: widget.post.viewsCount,
      engagementRate: widget.post.engagementRate,
      caption: widget.post.caption,
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final user = ref.watch(authStateProvider).valueOrNull;
    final allPosts = ref.watch(mediaProvider).valueOrNull ?? const [];
    final avgEngagement = allPosts.isEmpty
        ? 0.0
        : allPosts.fold<double>(0, (s, p) => s + p.engagementRate) /
            allPosts.length;
    final delta = post.engagementRate - avgEngagement;
    final isTrending = delta > 1 || post.engagementRate > 5;

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBlobs(opacity: 0.6)),
          SafeArea(
            child: Column(
              children: [
                _Header(post: post),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      _HeroMedia(post: post),
                      const SizedBox(height: 14),
                      _VerdictPill(
                        rate: post.engagementRate,
                        avg: avgEngagement,
                        trending: isTrending,
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 14),
                      _StatsGrid(
                        post: post,
                        followers: user?.followersCount ?? 0,
                      ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
                      if (post.caption.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _CaptionCard(caption: post.caption)
                            .animate()
                            .fadeIn(delay: 160.ms, duration: 300.ms),
                      ],
                      if (post.hashtags.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _HashtagsCard(tags: post.hashtags)
                            .animate()
                            .fadeIn(delay: 220.ms, duration: 300.ms),
                      ],
                      const SizedBox(height: 14),
                      _AnalysisCard(
                        future: _analysis,
                        trending: isTrending,
                        delta: delta,
                      ).animate().fadeIn(delay: 280.ms, duration: 300.ms),
                      if (post.permalink.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _OpenInstagramButton(url: post.permalink)
                            .animate()
                            .fadeIn(delay: 340.ms, duration: 300.ms),
                      ],
                    ],
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

class _Header extends StatelessWidget {
  final PostModel post;
  const _Header({required this.post});

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
                Text(
                  post.isVideo ? 'تفاصيل الفيديو' : 'تفاصيل المنشور',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (post.postedAt != null)
                  Text(
                    _fmtDate(post.postedAt!),
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

  static String _fmtDate(DateTime d) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _HeroMedia extends StatelessWidget {
  final PostModel post;
  const _HeroMedia({required this.post});

  @override
  Widget build(BuildContext context) {
    final url = post.thumbnailUrl.isNotEmpty ? post.thumbnailUrl : post.mediaUrl;
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentA.withValues(alpha: 0.27),
                    AppColors.accentB.withValues(alpha: 0.27),
                  ],
                ),
              ),
            ),
            if (url.isNotEmpty)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      color: AppColors.muted, size: 48),
                ),
              ),
            if (post.isVideo)
              Positioned(
                bottom: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_arrow,
                          color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'فيديو',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VerdictPill extends StatelessWidget {
  final double rate;
  final double avg;
  final bool trending;
  const _VerdictPill({
    required this.rate,
    required this.avg,
    required this.trending,
  });

  @override
  Widget build(BuildContext context) {
    final color = trending ? AppColors.good : AppColors.warn;
    final label = trending ? 'أداء قوي — صعود' : 'أداء متوسط — لم يصعد';
    final diff = (rate - avg).abs().toStringAsFixed(1);
    final comparison =
        rate >= avg ? 'أعلى من متوسطك بـ $diff%' : 'أقل من متوسطك بـ $diff%';

    return Glass(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          GlassIconBadge(
            icon: trending ? Icons.local_fire_department : Icons.bar_chart,
            size: 36,
            iconSize: 18,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comparison,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GradientText(
            '${rate.toStringAsFixed(1)}٪',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final PostModel post;
  final int followers;
  const _StatsGrid({required this.post, required this.followers});

  @override
  Widget build(BuildContext context) {
    final reachPct = followers > 0
        ? (post.viewsCount / followers * 100).clamp(0, 999)
        : 0;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _StatTile(
          icon: Icons.remove_red_eye_outlined,
          color: AppColors.accentA,
          label: 'المشاهدات',
          value: post.viewsCount > 0 ? _fmt(post.viewsCount) : '—',
          sub: post.viewsCount > 0 && followers > 0
              ? '${reachPct.toStringAsFixed(0)}٪ وصول'
              : (post.viewsCount == 0 ? 'غير متاحة' : null),
        ),
        _StatTile(
          icon: Icons.favorite_outline,
          color: AppColors.bad,
          label: 'الإعجابات',
          value: _fmt(post.likesCount),
        ),
        _StatTile(
          icon: Icons.chat_bubble_outline,
          color: AppColors.accentB,
          label: 'التعليقات',
          value: _fmt(post.commentsCount),
        ),
        _StatTile(
          icon: Icons.share_outlined,
          color: AppColors.accentC,
          label: 'المشاركات',
          value: _fmt(post.sharesCount),
        ),
        _StatTile(
          icon: Icons.bookmark_outline,
          color: AppColors.good,
          label: 'الحفظ',
          value: _fmt(post.savesCount),
        ),
        _StatTile(
          icon: Icons.insights,
          color: AppColors.warn,
          label: 'التفاعل الكلي',
          value: _fmt(post.totalEngagement),
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? sub;
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassIconBadge(icon: icon, size: 26, iconSize: 12, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 1),
            Text(
              sub!,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CaptionCard extends StatefulWidget {
  final String caption;
  const _CaptionCard({required this.caption});

  @override
  State<_CaptionCard> createState() => _CaptionCardState();
}

class _CaptionCardState extends State<_CaptionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final caption = widget.caption;
    final showToggle = caption.length > 240;

    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              const Text(
                'الكابشن',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: caption));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم نسخ الكابشن'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.copy,
                    size: 14, color: AppColors.accentB),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            caption,
            maxLines: _expanded ? null : 6,
            overflow:
                _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13.5,
              height: 1.7,
            ),
          ),
          if (showToggle) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'إخفاء' : 'عرض الكل',
                style: const TextStyle(
                  color: AppColors.accentB,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HashtagsCard extends StatelessWidget {
  final List<String> tags;
  const _HashtagsCard({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tag, size: 14, color: AppColors.accentB),
              const SizedBox(width: 6),
              Text(
                'هاشتاقات (${tags.length})',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentB.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accentB.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '#$t',
                        style: const TextStyle(
                          color: AppColors.accentB,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final Future<String>? future;
  final bool trending;
  final double delta;
  const _AnalysisCard({
    required this.future,
    required this.trending,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 20,
      gradient: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIconBadge(
                icon: Icons.auto_awesome,
                size: 32,
                iconSize: 14,
                color: AppColors.accentB,
              ),
              const SizedBox(width: 10),
              const Text(
                'تحليل AI — لماذا صعد أو لم يصعد؟',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<String>(
            future: future,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const _AnalysisSkeleton();
              }
              final text = snap.data ?? '';
              if (text.isEmpty) {
                return const Text(
                  'تعذّر الحصول على تحليل — تحقق من اتصال الإنترنت.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                );
              }
              return Text(
                text,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  height: 1.8,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalysisSkeleton extends StatelessWidget {
  const _AnalysisSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 12,
            width: i == 2 ? 180 : double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenInstagramButton extends StatelessWidget {
  final String url;
  const _OpenInstagramButton({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.open_in_new, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'فتح المنشور في إنستغرام',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
