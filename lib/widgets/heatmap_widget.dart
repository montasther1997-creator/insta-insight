import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/instagram_provider.dart';
import 'glass.dart';

/// Heatmap of posting times — violet→pink gradient cells, with peaks glowing.
/// Mirrors the `أوقات الذروة` glass card from the design bundle.
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

  // 8 time slots (matching the design's compact view).
  static const List<String> _slots = [
    '6ص',
    '9ص',
    '12ظ',
    '3م',
    '6م',
    '9م',
    '12ص',
    '3ص',
  ];

  // 24h bucket → 8 slot mapping.
  static const List<int> _hoursInSlot = [6, 9, 12, 15, 18, 21, 0, 3];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapData = ref.watch(postingHeatmapProvider);

    // Aggregate 24 hourly values → 8 slot values per day, carrying max.
    final cells = List.generate(7, (d) {
      return List.generate(8, (s) {
        final hour = _hoursInSlot[s];
        // Pick a small window around the slot hour.
        double maxV = 0;
        for (var h = hour - 1; h <= hour + 1; h++) {
          final key = '$d-${(h + 24) % 24}';
          maxV = (heatmapData[key] ?? 0) > maxV
              ? heatmapData[key] ?? 0
              : maxV;
        }
        return maxV;
      });
    });

    // Pick peak cell.
    int peakDay = 6, peakSlot = 5;
    double peakVal = 0;
    for (var d = 0; d < 7; d++) {
      for (var s = 0; s < 8; s++) {
        if (cells[d][s] > peakVal) {
          peakVal = cells[d][s];
          peakDay = d;
          peakSlot = s;
        }
      }
    }

    return Glass(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.local_fire_department,
                  size: 14, color: AppColors.accentB),
              SizedBox(width: 6),
              Text(
                'أوقات الذروة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Column headers.
          Padding(
            padding: const EdgeInsets.only(right: 38),
            child: Row(
              children: _slots
                  .map(
                    (s) => Expanded(
                      child: Text(
                        s,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: AppColors.mutedSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Rows.
          ...List.generate(7, (r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Text(
                      _days[r],
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  ...List.generate(8, (c) {
                    final v = cells[r][c].clamp(0.0, 1.0);
                    final isPeak = v >= 0.9;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: isPeak
                                ? AppColors.brandGradient
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.accentA
                                          .withValues(alpha: v * 0.86),
                                      AppColors.accentB
                                          .withValues(alpha: v * 0.78),
                                    ],
                                  ),
                            border: isPeak
                                ? Border.all(color: Colors.white, width: 1)
                                : null,
                            boxShadow: isPeak
                                ? [
                                    BoxShadow(
                                      color: AppColors.accentB
                                          .withValues(alpha: 0.8),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Opacity(
                            opacity: isPeak ? 1 : (0.3 + v * 0.7),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),
          Row(
            children: [
              const Text('أقل',
                  style: TextStyle(fontSize: 10, color: AppColors.muted)),
              const SizedBox(width: 6),
              ...[0.2, 0.4, 0.6, 0.8, 1.0].map(
                (a) => Container(
                  width: 14,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentA.withValues(alpha: a),
                        AppColors.accentB.withValues(alpha: a),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text('أكثر',
                  style: TextStyle(fontSize: 10, color: AppColors.muted)),
              const Spacer(),
              if (peakVal > 0)
                Text(
                  'ذروة: ${_days[peakDay]} ${_slots[peakSlot]}',
                  style: const TextStyle(
                    color: AppColors.accentB,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
