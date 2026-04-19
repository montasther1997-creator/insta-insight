import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../utils/tap_feedback.dart';
import 'glass.dart';

/// Glass suggestion card with priority stripe + soft gradient icon.
class SuggestionCard extends StatelessWidget {
  final String title;
  final String description;
  final String? reason;
  final String priority;
  final String? hashtags;
  final String? estimatedViews;
  final int index;

  const SuggestionCard({
    super.key,
    required this.title,
    required this.description,
    this.reason,
    this.priority = 'medium',
    this.hashtags,
    this.estimatedViews,
    this.index = 0,
  });

  Color get _priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.bad;
      case 'medium':
      case 'med':
        return AppColors.warn;
      case 'low':
        return AppColors.good;
      default:
        return AppColors.warn;
    }
  }

  String get _priorityLabel {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'عالية';
      case 'medium':
      case 'med':
        return 'متوسطة';
      case 'low':
        return 'منخفضة';
      default:
        return priority;
    }
  }

  IconData get _priorityIcon {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.local_fire_department;
      case 'medium':
      case 'med':
        return Icons.auto_awesome;
      default:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          Glass(
            radius: 20,
            padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassIconBadge(
                  icon: _priorityIcon,
                  size: 36,
                  iconSize: 16,
                  color: AppColors.accentB,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassChip(
                        color: _priorityColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        child: Text(
                          _priorityLabel,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: _priorityColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 11.5,
                          height: 1.6,
                        ),
                      ),
                      if (reason != null && reason!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                size: 12, color: AppColors.warn),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                reason!,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (hashtags != null && hashtags!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.glassBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  hashtags!,
                                  style: const TextStyle(
                                    color: AppColors.accentA,
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  TapFeedback.light();
                                  Clipboard.setData(
                                      ClipboardData(text: hashtags!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم نسخ الهاشتاقات'),
                                      duration: Duration(seconds: 1),
                                      backgroundColor: AppColors.good,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.copy,
                                      size: 14, color: AppColors.accentA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.line,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (estimatedViews != null &&
                                estimatedViews!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.trending_up,
                                      size: 12, color: AppColors.good),
                                  const SizedBox(width: 4),
                                  Text(
                                    'مشاهدات متوقعة: $estimatedViews',
                                    style: const TextStyle(
                                      color: AppColors.good,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentB
                                        .withValues(alpha: 0.67),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: -3,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'طبّق',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Priority stripe on the right edge (RTL-aware: visually on the inner edge).
          Positioned(
            top: 14,
            bottom: 14,
            right: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: _priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
