import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final int rank;
  final String? geminiNote;

  const PostCard({
    super.key,
    required this.post,
    this.rank = 0,
    this.geminiNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: post.thumbnailUrl,
                  width: 100,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(
                    width: 100,
                    height: 120,
                    color: AppColors.surface2,
                  ),
                  errorWidget: (ctx, url, err) => Container(
                    width: 100,
                    height: 120,
                    color: AppColors.surface2,
                    child: const Icon(Icons.image, color: AppColors.muted),
                  ),
                ),
                if (rank > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: rank <= 3
                            ? AppColors.primaryGradient
                            : null,
                        color: rank > 3 ? AppColors.surface2 : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#$rank',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (post.isVideo)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.visibility_outlined,
                        value: _formatNumber(post.viewsCount),
                        color: AppColors.accentBlue,
                      ),
                      const SizedBox(width: 12),
                      _StatItem(
                        icon: Icons.favorite_outline,
                        value: _formatNumber(post.likesCount),
                        color: AppColors.accentPink,
                      ),
                      const SizedBox(width: 12),
                      _StatItem(
                        icon: Icons.chat_bubble_outline,
                        value: _formatNumber(post.commentsCount),
                        color: AppColors.accentGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Engagement rate
                  Row(
                    children: [
                      const Text(
                        'نسبة التفاعل',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.engagementRate.toStringAsFixed(1)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.accentAmber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Gemini analysis
                  if (geminiNote != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: AppColors.accentAmber,
                        ),
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
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
