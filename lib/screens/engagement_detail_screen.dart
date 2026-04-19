import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/instagram_provider.dart';
import '../widgets/glass.dart';
import 'post_detail_screen.dart';

class EngagementDetailScreen extends ConsumerWidget {
  const EngagementDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final posts = ref.watch(mediaProvider).valueOrNull ?? [];
    final engagement = ref.watch(engagementRateProvider);

    final totalLikes = posts.fold<int>(0, (s, p) => s + p.likesCount);
    final totalComments = posts.fold<int>(0, (s, p) => s + p.commentsCount);
    final totalViews = posts.fold<int>(0, (s, p) => s + p.viewsCount);
    final avgLikes = posts.isEmpty ? 0 : (totalLikes / posts.length).round();
    final avgComments =
        posts.isEmpty ? 0 : (totalComments / posts.length).round();
    final commentLikeRatio =
        totalLikes == 0 ? 0.0 : (totalComments / totalLikes) * 100;

    final sortedByEng = [...posts]
      ..sort((a, b) => b.totalEngagement.compareTo(a.totalEngagement));
    final topPost = sortedByEng.isNotEmpty ? sortedByEng.first : null;
    final worstPost = sortedByEng.isNotEmpty ? sortedByEng.last : null;

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBlobs(opacity: 0.7)),
          SafeArea(
            child: Column(
              children: [
                const _AppBar(
                  title: 'تفاصيل التفاعل',
                  subtitle: 'لايكات وتعليقات وردّات',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      Glass(
                        radius: 24,
                        gradient: true,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'نسبة التفاعل الإجمالية',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                GradientText(
                                  '${engagement.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w800,
                                    height: 0.9,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              engagement >= 3
                                  ? 'تفاعل صحي وأعلى من متوسط المجال (~2.5%).'
                                  : 'أقل من متوسط المجال — ركّز على الهوك والدعوة للتعليق.',
                              style: const TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.favorite,
                              color: AppColors.bad,
                              label: 'متوسط اللايكات',
                              value: '$avgLikes',
                              footer: 'إجمالي $totalLikes',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.chat_bubble,
                              color: AppColors.accentB,
                              label: 'متوسط التعليقات',
                              value: '$avgComments',
                              footer: 'إجمالي $totalComments',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.remove_red_eye,
                              color: AppColors.accentA,
                              label: 'إجمالي المشاهدات',
                              value: _fmt(totalViews),
                              footer: '${posts.length} منشور',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.insights,
                              color: AppColors.good,
                              label: 'نسبة التعليق/اللايك',
                              value: '${commentLikeRatio.toStringAsFixed(1)}%',
                              footer: commentLikeRatio > 5
                                  ? 'نقاش نشط'
                                  : 'جمهور صامت نسبياً',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _Label(
                          icon: Icons.trending_up, text: 'أعلى منشور تفاعلاً'),
                      const SizedBox(height: 8),
                      if (topPost != null)
                        _PostHighlight(
                          post: topPost,
                          good: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: topPost),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      const _Label(
                          icon: Icons.trending_down,
                          text: 'أقل منشور تفاعلاً'),
                      const SizedBox(height: 8),
                      if (worstPost != null)
                        _PostHighlight(
                          post: worstPost,
                          good: false,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: worstPost),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _TipsCard(
                        followers: user?.followersCount ?? 0,
                        engagement: engagement,
                        commentRatio: commentLikeRatio,
                      ),
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

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String footer;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassIconBadge(icon: icon, size: 30, iconSize: 14, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            footer,
            style: const TextStyle(
              color: AppColors.mutedSoft,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostHighlight extends StatelessWidget {
  final PostModel post;
  final bool good;
  final VoidCallback onTap;
  const _PostHighlight({
    required this.post,
    required this.good,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = good ? AppColors.good : AppColors.warn;
    final preview = post.captionPreview;
    final title = preview.isNotEmpty
        ? preview
        : (post.isVideo ? 'فيديو' : 'منشور');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Glass(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 68,
                    child: post.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: post.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _thumbFallback(),
                            placeholder: (_, _) => _thumbFallback(),
                          )
                        : _thumbFallback(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GlassIconBadge(
                            icon: good
                                ? Icons.emoji_events
                                : Icons.flag_outlined,
                            size: 28,
                            iconSize: 13,
                            color: color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _miniStat(Icons.favorite_outline,
                              '${post.likesCount}', AppColors.bad),
                          const SizedBox(width: 12),
                          _miniStat(Icons.chat_bubble_outline,
                              '${post.commentsCount}', AppColors.accentB),
                          const SizedBox(width: 12),
                          _miniStat(Icons.remove_red_eye_outlined,
                              _fmt(post.viewsCount), AppColors.muted),
                          const Spacer(),
                          const Icon(Icons.chevron_left,
                              size: 18, color: AppColors.muted),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                GlassChip(
                  color: color,
                  child: Text(
                      '${post.engagementRate.toStringAsFixed(1)}% تفاعل'),
                ),
                const SizedBox(width: 6),
                const GlassChip(
                  child: Text('اضغط لعرض التفاصيل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: Icon(
        post.isVideo ? Icons.play_arrow : Icons.image_outlined,
        color: AppColors.muted,
        size: 22,
      ),
    );
  }

  Widget _miniStat(IconData icon, String v, Color c) {
    return Row(
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(
          v,
          style: TextStyle(
            color: c,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
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

class _TipsCard extends StatelessWidget {
  final int followers;
  final double engagement;
  final double commentRatio;
  const _TipsCard({
    required this.followers,
    required this.engagement,
    required this.commentRatio,
  });

  @override
  Widget build(BuildContext context) {
    final tips = <String>[
      if (engagement < 3)
        'معدل التفاعل أقل من المتوسط — جرّب طرح سؤال في نهاية الكابشن.',
      if (commentRatio < 3)
        'التعليقات قليلة مقارنة بالإعجابات — استخدم دعوة واضحة للمحادثة.',
      if (followers > 5000 && engagement < 2)
        'جمهورك كبير لكن التفاعل منخفض — راجع توقيت النشر ونوع المحتوى.',
      'ركّز على الثواني الثلاث الأولى في الريلز — هي التي تحدد التفاعل.',
      'رُد على أول 10 تعليقات خلال ساعة من النشر لرفع الانتشار.',
    ];

    return Glass(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.accentB),
              SizedBox(width: 6),
              Text(
                'نصائح لرفع التفاعل',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accentB,
                        shape: BoxShape.circle,
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
              )),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Label({required this.icon, required this.text});

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

class _AppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _AppBar({required this.title, this.subtitle});

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
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
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
