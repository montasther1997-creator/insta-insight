import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../utils/tap_feedback.dart';
import 'glass.dart';

/// Compact glass stat tile — small icon badge, big value, tiny delta chip.
/// Tappable when `onTap` is provided; a small chevron hints interactivity.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color = AppColors.accentB,
    this.gradient,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final delta = subtitle;
    final isUp = delta != null && delta.trim().startsWith('+');
    final inner = Glass(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GlassIconBadge(
                icon: icon,
                size: 28,
                iconSize: 14,
                color: color,
                radius: 9,
              ),
              if (delta != null)
                Text(
                  delta,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isUp ? AppColors.good : AppColors.bad,
                  ),
                ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_back_ios_new,
                  size: 10,
                  color: AppColors.muted,
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return inner;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        TapFeedback.light();
        onTap!();
      },
      child: inner,
    );
  }
}
