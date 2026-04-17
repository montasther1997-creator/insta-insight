import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';

class GeoBar extends StatelessWidget {
  final String country;
  final double percentage;
  final double engagementRate;
  final String bestTime;
  final Color color;

  const GeoBar({
    super.key,
    required this.country,
    required this.percentage,
    this.engagementRate = 0,
    this.bestTime = '',
    this.color = AppColors.accentPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  country,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.jetBrainsMono(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          if (engagementRate > 0 || bestTime.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (engagementRate > 0)
                  _InfoChip(
                    icon: Icons.favorite_outline,
                    label: 'تفاعل ${engagementRate.toStringAsFixed(1)}%',
                  ),
                if (bestTime.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.access_time,
                    label: bestTime,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}
