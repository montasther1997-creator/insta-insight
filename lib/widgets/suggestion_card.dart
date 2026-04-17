import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SuggestionCard extends StatelessWidget {
  final String title;
  final String description;
  final String? reason;
  final String priority;
  final int index;

  const SuggestionCard({
    super.key,
    required this.title,
    required this.description,
    this.reason,
    this.priority = 'medium',
    this.index = 0,
  });

  Color get _priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.accentPink;
      case 'medium':
        return AppColors.accentAmber;
      case 'low':
        return AppColors.accentBlue;
      default:
        return AppColors.accentAmber;
    }
  }

  String get _priorityLabel {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'أولوية عالية';
      case 'medium':
        return 'أولوية متوسطة';
      case 'low':
        return 'أولوية منخفضة';
      default:
        return priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          right: BorderSide(color: _priorityColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: _priorityColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _priorityLabel,
                  style: TextStyle(
                    color: _priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            description,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          // Reason
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: AppColors.accentAmber,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reason!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
