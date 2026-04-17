import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/instagram_provider.dart';

class HeatmapWidget extends ConsumerWidget {
  const HeatmapWidget({super.key});

  static const List<String> _days = [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  static const List<String> _hours = [
    '12ص', '1', '2', '3', '4', '5',
    '6', '7', '8', '9', '10', '11',
    '12م', '1', '2', '3', '4', '5',
    '6', '7', '8', '9', '10', '11',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapData = ref.watch(postingHeatmapProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'خريطة أوقات النشر',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            heatmapData.isEmpty
                ? 'ستظهر البيانات بعد تحليل منشوراتك'
                : 'أفضل الأوقات للنشر بناءً على تفاعل جمهورك',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                // Hour labels
                Row(
                  children: [
                    const SizedBox(width: 60),
                    ...List.generate(24, (h) {
                      if (h % 3 != 0) return const SizedBox(width: 28);
                      return SizedBox(
                        width: 28,
                        child: Text(
                          _hours[h],
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                // Heatmap grid
                ...List.generate(7, (dayIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            _days[dayIndex],
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        ...List.generate(24, (hourIndex) {
                          final key = '$dayIndex-$hourIndex';
                          final value = heatmapData[key] ?? 0.0;
                          return Container(
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: _getColor(value),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
                // Legend
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('منخفض', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                    const SizedBox(width: 8),
                    ...List.generate(5, (i) {
                      return Container(
                        width: 20,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _getColor(i / 4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    const Text('مرتفع', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(double value) {
    if (value <= 0.1) return AppColors.surface2;
    if (value <= 0.3) return AppColors.accentPurple.withValues(alpha: 0.2);
    if (value <= 0.5) return AppColors.accentPurple.withValues(alpha: 0.4);
    if (value <= 0.7) return AppColors.accentPurple.withValues(alpha: 0.6);
    return AppColors.accentPurple;
  }
}
