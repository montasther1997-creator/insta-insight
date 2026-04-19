import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/instagram_provider.dart';
import '../widgets/glass.dart';

enum _GrowthRange { day, week, month, year, custom }

class GrowthDetailScreen extends ConsumerStatefulWidget {
  const GrowthDetailScreen({super.key});

  @override
  ConsumerState<GrowthDetailScreen> createState() => _GrowthDetailScreenState();
}

class _GrowthDetailScreenState extends ConsumerState<GrowthDetailScreen> {
  _GrowthRange _range = _GrowthRange.week;
  DateTimeRange? _customRange;
  Future<List<Map<String, dynamic>>>? _seriesFuture;
  int _cachedDays = -1;

  int get _days {
    switch (_range) {
      case _GrowthRange.day:
        return 1;
      case _GrowthRange.week:
        return 7;
      case _GrowthRange.month:
        return 30;
      case _GrowthRange.year:
        return 365;
      case _GrowthRange.custom:
        if (_customRange == null) return 30;
        return _customRange!.duration.inDays.clamp(1, 365);
    }
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return [];
    final service = ref.read(instagramServiceProvider);
    return service.fetchFollowersOverTime(
      user.instagramId,
      user.accessToken,
      days: _days,
    );
  }

  void _refresh() {
    if (_cachedDays == _days) return;
    _cachedDays = _days;
    setState(() {
      _seriesFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    _refresh();
    final user = ref.watch(authStateProvider).valueOrNull;
    final currentFollowers = user?.followersCount ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBlobs(opacity: 0.7)),
          SafeArea(
            child: Column(
              children: [
                const _AppBar(
                  title: 'نمو المتابعين',
                  subtitle: 'اليومي • الأسبوعي • الشهري • السنوي',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      _RangeSelector(
                        active: _range,
                        onChange: (r) => setState(() {
                          _range = r;
                          _cachedDays = -1;
                        }),
                        customLabel: _customRange == null
                            ? 'مدى مخصص'
                            : '${_fmtDate(_customRange!.start)} → ${_fmtDate(_customRange!.end)}',
                        onCustomTap: _pickCustomRange,
                      ),
                      const SizedBox(height: 14),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _seriesFuture,
                        builder: (context, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const _SkeletonCard();
                          }
                          final raw = snap.data ?? [];
                          final filtered = _applyCustomRange(raw);
                          return _GrowthBody(
                            current: currentFollowers,
                            series: filtered,
                            range: _range,
                          );
                        },
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

  List<Map<String, dynamic>> _applyCustomRange(
    List<Map<String, dynamic>> raw,
  ) {
    if (_range != _GrowthRange.custom || _customRange == null) return raw;
    return raw.where((e) {
      final dt = DateTime.tryParse(e['end_time'] as String? ?? '');
      if (dt == null) return true;
      return dt.isAfter(
              _customRange!.start.subtract(const Duration(days: 1))) &&
          dt.isBefore(_customRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentB,
              onPrimary: Colors.white,
              surface: AppColors.bg2,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _range = _GrowthRange.custom;
        _cachedDays = -1;
      });
    }
  }
}

class _RangeSelector extends StatelessWidget {
  final _GrowthRange active;
  final ValueChanged<_GrowthRange> onChange;
  final String customLabel;
  final VoidCallback onCustomTap;

  const _RangeSelector({
    required this.active,
    required this.onChange,
    required this.customLabel,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      _RangeOption(_GrowthRange.day, 'يوم', Icons.today),
      _RangeOption(_GrowthRange.week, 'أسبوع', Icons.view_week),
      _RangeOption(_GrowthRange.month, 'شهر', Icons.calendar_today),
      _RangeOption(_GrowthRange.year, 'سنة', Icons.calendar_month),
    ];
    return Column(
      children: [
        Glass(
          radius: 20,
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: options.map((opt) {
              final isActive = opt.value == active;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChange(opt.value),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: isActive
                        ? BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(14),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.icon,
                          size: 15,
                          color:
                              isActive ? Colors.white : AppColors.muted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isActive ? Colors.white : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onCustomTap,
          behavior: HitTestBehavior.opaque,
          child: Glass(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 14,
                  color: active == _GrowthRange.custom
                      ? AppColors.accentB
                      : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customLabel,
                    style: TextStyle(
                      color: active == _GrowthRange.custom
                          ? AppColors.text
                          : AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_left,
                  size: 16,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeOption {
  final _GrowthRange value;
  final String label;
  final IconData icon;
  const _RangeOption(this.value, this.label, this.icon);
}

class _GrowthBody extends StatelessWidget {
  final int current;
  final List<Map<String, dynamic>> series;
  final _GrowthRange range;
  const _GrowthBody({
    required this.current,
    required this.series,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const _EmptyCard(
        message:
            'لا تتوفر بيانات نمو من Instagram لهذه الفترة. قد يكون حسابك جديداً أو لم يُفعّل الرؤى بعد.',
      );
    }
    final first = series.first['value'] as int? ?? current;
    final last = series.last['value'] as int? ?? current;
    final delta = last - first;
    final pct = first == 0 ? 0.0 : (delta / first) * 100;
    final maxV =
        series.map((e) => e['value'] as int? ?? 0).reduce(math.max);
    final minV =
        series.map((e) => e['value'] as int? ?? 0).reduce(math.min);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Glass(
          radius: 24,
          gradient: true,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _periodLabel(range, series.length),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GradientText(
                    (delta >= 0 ? '+' : '') + delta.toString(),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 0.9,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'متابع',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GlassChip(
                    color: delta >= 0 ? AppColors.good : AppColors.bad,
                    child: Text(
                      '${delta >= 0 ? '↑' : '↓'} ${pct.abs().toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ChartPainter(
                    points: series
                        .map((e) => (e['value'] as int? ?? 0).toDouble())
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$minV متابع',
                    style: const TextStyle(
                      color: AppColors.mutedSoft,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '$maxV متابع',
                    style: const TextStyle(
                      color: AppColors.mutedSoft,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _KeyValue(
                icon: Icons.vertical_align_top,
                color: AppColors.good,
                label: 'أعلى نقطة',
                value: '$maxV',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KeyValue(
                icon: Icons.vertical_align_bottom,
                color: AppColors.warn,
                label: 'أدنى نقطة',
                value: '$minV',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KeyValue(
                icon: Icons.timeline,
                color: AppColors.accentB,
                label: 'متوسط يومي',
                value:
                    (series.length <= 1 ? '0' : (delta / series.length).toStringAsFixed(1)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KeyValue(
                icon: Icons.stacked_line_chart,
                color: AppColors.accentA,
                label: 'عدد نقاط البيانات',
                value: '${series.length}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _periodLabel(_GrowthRange r, int n) {
    switch (r) {
      case _GrowthRange.day:
        return 'آخر يوم';
      case _GrowthRange.week:
        return 'آخر ${n > 7 ? 7 : n} أيام';
      case _GrowthRange.month:
        return 'آخر ${n > 30 ? 30 : n} يوم';
      case _GrowthRange.year:
        return 'آخر ${n > 365 ? 365 : n} يوم';
      case _GrowthRange.custom:
        return 'المدى المخصص';
    }
  }
}

class _KeyValue extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _KeyValue({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> points;
  _ChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final minV = points.reduce(math.min);
    final maxV = points.reduce(math.max);
    final range = maxV - minV == 0 ? 1.0 : maxV - minV;
    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1).clamp(1, 10000));
      final y = size.height - ((points[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accentB.withValues(alpha: 0.35),
          AppColors.accentB.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.accentA, AppColors.accentB],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    if (points.isNotEmpty) {
      final lastX = size.width;
      final lastY = size.height -
          ((points.last - minV) / range) * size.height;
      canvas.drawCircle(
        Offset(lastX, lastY),
        5,
        Paint()..color = AppColors.accentB,
      );
      canvas.drawCircle(
        Offset(lastX, lastY),
        2.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.points != points;
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.accentB.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.insights, size: 32, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
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
