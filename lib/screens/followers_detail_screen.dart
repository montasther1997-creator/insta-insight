import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/instagram_provider.dart';
import '../widgets/glass.dart';
import 'post_detail_screen.dart';

/// "المتابعون النشطون" — top contributors grouped by interaction type.
/// Instagram Graph API doesn't expose the per-follower username list to
/// business accounts, so we synthesize groups from the posts' interaction
/// counts and surface the real totals.
class FollowersDetailScreen extends ConsumerWidget {
  const FollowersDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final posts = ref.watch(mediaProvider).valueOrNull ?? [];

    final totalLikes = posts.fold<int>(0, (s, p) => s + p.likesCount);
    final totalComments = posts.fold<int>(0, (s, p) => s + p.commentsCount);
    final totalViews = posts.fold<int>(0, (s, p) => s + p.viewsCount);
    final followers = user?.followersCount ?? 0;

    // Rough share counts: approximate active followers by clamping ratios.
    final approxLikers = (totalLikes / (posts.isEmpty ? 1 : posts.length))
        .clamp(0, followers.toDouble())
        .round();
    final approxCommenters = (totalComments * 1.8)
        .clamp(0, followers.toDouble())
        .round();
    final approxReachers =
        (totalViews / (posts.isEmpty ? 1 : posts.length).toDouble())
            .clamp(0, followers.toDouble() * 4)
            .round();

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBlobs(opacity: 0.7)),
          SafeArea(
            child: Column(
              children: [
                const _AppBar(
                  title: 'المتابعون النشطون',
                  subtitle: 'مقسّمون حسب نوع التفاعل',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      _HeaderSummary(followers: followers),
                      const SizedBox(height: 14),
                      _GroupBlock(
                        icon: Icons.favorite,
                        color: AppColors.bad,
                        title: 'الأكثر تفاعلاً بالإعجابات',
                        subtitle:
                            '~$approxLikers متابع يضع لايك على منشوراتك بانتظام',
                        metric: totalLikes,
                        metricLabel: 'إجمالي اللايكات',
                        items: _buildLikeLeaders(posts),
                      ),
                      const SizedBox(height: 12),
                      _GroupBlock(
                        icon: Icons.chat_bubble,
                        color: AppColors.accentB,
                        title: 'الأكثر تفاعلاً بالتعليقات',
                        subtitle:
                            '~$approxCommenters متابع يعلّقون على محتواك',
                        metric: totalComments,
                        metricLabel: 'إجمالي التعليقات',
                        items: _buildCommentLeaders(posts),
                      ),
                      const SizedBox(height: 12),
                      _GroupBlock(
                        icon: Icons.visibility,
                        color: AppColors.accentA,
                        title: 'المنشورات الأوسع انتشاراً',
                        subtitle:
                            '~$approxReachers متابع يشاهدون محتواك بانتظام',
                        metric: totalViews,
                        metricLabel: 'إجمالي المشاهدات',
                        items: _buildReachLeaders(posts),
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

  List<_LeaderItem> _buildLikeLeaders(List<PostModel> posts) {
    final sorted = [...posts]
      ..sort((a, b) => b.likesCount.compareTo(a.likesCount));
    return sorted.take(3).map<_LeaderItem>((p) {
      return _LeaderItem(
        post: p,
        label: p.isVideo ? 'فيديو' : 'منشور',
        detail: '${p.likesCount} لايك',
        icon: Icons.favorite_outline,
      );
    }).toList();
  }

  List<_LeaderItem> _buildCommentLeaders(List<PostModel> posts) {
    final sorted = [...posts]
      ..sort((a, b) => b.commentsCount.compareTo(a.commentsCount));
    return sorted.take(3).map<_LeaderItem>((p) {
      return _LeaderItem(
        post: p,
        label: p.isVideo ? 'فيديو' : 'منشور',
        detail: '${p.commentsCount} تعليق',
        icon: Icons.chat_bubble_outline,
      );
    }).toList();
  }

  List<_LeaderItem> _buildReachLeaders(List<PostModel> posts) {
    final withViews = posts.where((p) => p.viewsCount > 0).toList()
      ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    return withViews.take(3).map<_LeaderItem>((p) {
      return _LeaderItem(
        post: p,
        label: p.isVideo ? 'فيديو' : 'منشور',
        detail: '${_fmtViews(p.viewsCount)} مشاهدة',
        icon: Icons.visibility_outlined,
      );
    }).toList();
  }

  String _fmtViews(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _HeaderSummary extends StatelessWidget {
  final int followers;
  const _HeaderSummary({required this.followers});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 22,
      gradient: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          GlassIconBadge(
            icon: Icons.people_alt,
            size: 44,
            iconSize: 20,
            color: AppColors.accentB,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إجمالي المتابعين',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                GradientText(
                  _fmt(followers),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          GlassChip(
            color: AppColors.accentB,
            child: const Text('تحديث لحظي'),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _GroupBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int metric;
  final String metricLabel;
  final List<_LeaderItem> items;

  const _GroupBlock({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.metricLabel,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIconBadge(
                icon: icon,
                size: 36,
                iconSize: 16,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(metric),
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    metricLabel,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.line, height: 1),
            const SizedBox(height: 10),
            ...items.map((i) => _ClickableLeaderRow(item: i, accent: color)),
            const SizedBox(height: 4),
            Text(
              'اضغط على أي منشور لرؤية التفاعل الفعلي وتحليل AI',
              style: TextStyle(
                color: AppColors.mutedSoft.withValues(alpha: 0.7),
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _LeaderItem {
  final PostModel post;
  final String label;
  final String detail;
  final IconData icon;
  _LeaderItem({
    required this.post,
    required this.label,
    required this.detail,
    required this.icon,
  });
}

/// Tappable leader row. Instagram's API doesn't hand us the individual
/// follower list, but the originating post does — so tapping opens the
/// post detail (with the real likes/comments counts + AI analysis).
class _ClickableLeaderRow extends StatelessWidget {
  final _LeaderItem item;
  final Color accent;
  const _ClickableLeaderRow({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final thumb = item.post.thumbnailUrl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PostDetailScreen(post: item.post),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 36,
                height: 44,
                child: thumb.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _thumbFallback(),
                        placeholder: (_, _) => _thumbFallback(),
                      )
                    : _thumbFallback(),
              ),
            ),
            const SizedBox(width: 10),
            Icon(item.icon, size: 12, color: accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              item.detail,
              style: TextStyle(
                color: accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_left, size: 14, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        color: Colors.white.withValues(alpha: 0.04),
        child: const Icon(Icons.image_outlined,
            size: 16, color: AppColors.muted),
      );
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
