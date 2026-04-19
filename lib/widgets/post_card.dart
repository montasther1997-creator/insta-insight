import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/post_model.dart';
import '../utils/tap_feedback.dart';
import 'glass.dart';

/// Glass video/reel row — thumbnail, stats, engagement bar.
class PostCard extends StatelessWidget {
  final PostModel post;
  final int rank;
  final String? geminiNote;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.rank = 0,
    this.geminiNote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final engRate = post.engagementRate;
    final preview = post.captionPreview;
    final card = Glass(
      radius: 18,
      padding: const EdgeInsets.all(10),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (rank > 0) ...[
              SizedBox(
                width: 28,
                child: rank <= 3
                    ? GradientText(
                        '$rank',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        '$rank',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
            ],
            // Thumb — gradient-soft background placeholder.
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 88,
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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: post.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => const SizedBox(),
                        errorWidget: (ctx, url, err) => const Center(
                          child: Icon(Icons.photo_outlined,
                              color: AppColors.muted, size: 28),
                        ),
                      ),
                    ),
                    if (post.isVideo)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.isNotEmpty
                        ? preview
                        : (post.isVideo ? 'فيديو' : 'منشور'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.remove_red_eye_outlined,
                        value: _fmt(post.viewsCount),
                      ),
                      const SizedBox(width: 10),
                      _StatItem(
                        icon: Icons.favorite_outline,
                        value: _fmt(post.likesCount),
                      ),
                      const SizedBox(width: 10),
                      _StatItem(
                        icon: Icons.chat_bubble_outline,
                        value: _fmt(post.commentsCount),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: (engRate / 12).clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.06),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accentB,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${engRate.toStringAsFixed(1)}٪',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: AppColors.accentB,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (geminiNote != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 12, color: AppColors.accentA),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            geminiNote!,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: onTap == null
          ? card
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                TapFeedback.light();
                onTap!();
              },
              child: card,
            ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.muted),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textSoft,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
