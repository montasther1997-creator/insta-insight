import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// A single row of the countries list on the Geo screen:
/// name + share %, gradient progress bar, optional engagement / best-time chips.
class GeoBar extends StatelessWidget {
  final String country;
  final double percentage;
  final double engagementRate;
  final String bestTime;
  final String? flag;
  final String? count;

  const GeoBar({
    super.key,
    required this.country,
    required this.percentage,
    this.engagementRate = 0,
    this.bestTime = '',
    this.flag,
    this.count,
    Color color = AppColors.accentB,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (flag != null) ...[
            Text(flag!, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        country,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (count != null)
                      Text(
                        count!,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (count != null)
                      const Text(' · ',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          )),
                    Text(
                      '${percentage.toStringAsFixed(0)}٪',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: (percentage / 50).clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (engagementRate > 0 || bestTime.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (engagementRate > 0)
                        _InfoChip(
                          icon: Icons.favorite_outline,
                          label:
                              'تفاعل ${engagementRate.toStringAsFixed(1)}%',
                        ),
                      if (bestTime.isNotEmpty) ...[
                        const SizedBox(width: 10),
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
          ),
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
        Icon(icon, size: 11, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}
