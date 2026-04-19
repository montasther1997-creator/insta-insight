import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/instagram_provider.dart';
import '../widgets/glass.dart';

class ReachDetailScreen extends ConsumerWidget {
  const ReachDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final posts = ref.watch(mediaProvider).valueOrNull ?? [];
    final followers = user?.followersCount ?? 0;

    final totalViews = posts.fold<int>(0, (s, p) => s + p.viewsCount);
    final avgViews = posts.isEmpty ? 0 : (totalViews / posts.length).round();
    final bestPost = posts.isEmpty
        ? null
        : posts.reduce((a, b) => a.viewsCount > b.viewsCount ? a : b);
    final reachRatio = followers == 0
        ? 0.0
        : ((avgViews / followers) * 100).clamp(0, 1000).toDouble();

    final byType = <String, List<int>>{
      'REELS': [],
      'VIDEO': [],
      'IMAGE': [],
      'CAROUSEL_ALBUM': [],
    };
    for (final p in posts) {
      final key = byType.containsKey(p.mediaType) ? p.mediaType : 'IMAGE';
      byType[key]!.add(p.viewsCount);
    }

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBlobs(opacity: 0.7)),
          SafeArea(
            child: Column(
              children: [
                const _AppBar(
                  title: 'الوصول والانتشار',
                  subtitle: 'كم شخصاً رأى محتواك؟',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      _HeroReach(
                        totalViews: totalViews,
                        avgViews: avgViews,
                        reachRatio: reachRatio,
                        followers: followers,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ReachStat(
                              icon: Icons.visibility,
                              color: AppColors.accentB,
                              label: 'متوسط المشاهدات',
                              value: _fmt(avgViews),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ReachStat(
                              icon: Icons.trending_up,
                              color: AppColors.accentA,
                              label: 'أعلى منشور',
                              value: bestPost == null
                                  ? '-'
                                  : _fmt(bestPost.viewsCount),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ReachStat(
                              icon: Icons.group,
                              color: AppColors.good,
                              label: 'نسبة الوصول',
                              value: '${reachRatio.toStringAsFixed(1)}%',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ReachStat(
                              icon: Icons.view_carousel,
                              color: AppColors.accentC,
                              label: 'منشورات محلّلة',
                              value: '${posts.length}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _Label(
                          icon: Icons.pie_chart,
                          text: 'الوصول حسب نوع المحتوى'),
                      const SizedBox(height: 8),
                      _TypeBreakdown(byType: byType),
                      const SizedBox(height: 16),
                      const _Label(
                          icon: Icons.lightbulb_outline,
                          text: 'كيف تزيد الوصول؟'),
                      const SizedBox(height: 8),
                      const _ReachTips(),
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

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _HeroReach extends StatelessWidget {
  final int totalViews;
  final int avgViews;
  final double reachRatio;
  final int followers;

  const _HeroReach({
    required this.totalViews,
    required this.avgViews,
    required this.reachRatio,
    required this.followers,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 26,
      gradient: true,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.public, size: 14, color: AppColors.accentB),
              SizedBox(width: 6),
              Text(
                'إجمالي الوصول',
                style: TextStyle(
                  color: AppColors.accentB,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GradientText(
                _fmt(totalViews),
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 0.9,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'مشاهدة',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: CustomPaint(
              size: Size.infinite,
              painter: _WavePainter(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            reachRatio > 100
                ? 'كل منشور يصل لأكثر من ${reachRatio.toStringAsFixed(0)}٪ من حجم متابعيك — انتشار قوي.'
                : reachRatio > 30
                    ? 'وصولك ضمن الممتاز — ${reachRatio.toStringAsFixed(0)}٪ من متابعيك يرون كل منشور.'
                    : 'الوصول منخفض نسبياً — جرّب ريلز أقصر وهاشتاقات أدق.',
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 12.5,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const points = 24;
    final rand = math.Random(42);
    final ys = List<double>.generate(points, (i) {
      return 0.3 + (rand.nextDouble() * 0.7);
    });
    for (var i = 0; i < points; i++) {
      final x = size.width * (i / (points - 1));
      final y = size.height * (1 - ys[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accentB.withValues(alpha: 0.35),
            AppColors.accentB.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [AppColors.accentA, AppColors.accentB],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) => false;
}

class _ReachStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _ReachStat({
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
          GlassIconBadge(icon: icon, size: 30, iconSize: 13, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBreakdown extends StatelessWidget {
  final Map<String, List<int>> byType;
  const _TypeBreakdown({required this.byType});

  @override
  Widget build(BuildContext context) {
    final rows = <_TypeRow>[];
    byType.forEach((type, list) {
      if (list.isEmpty) return;
      final avg = (list.reduce((a, b) => a + b) / list.length).round();
      rows.add(
        _TypeRow(
          label: _arLabel(type),
          icon: _icon(type),
          color: _color(type),
          count: list.length,
          avg: avg,
          total: list.reduce((a, b) => a + b),
        ),
      );
    });
    rows.sort((a, b) => b.avg.compareTo(a.avg));
    if (rows.isEmpty) {
      return const _Empty(message: 'لا توجد بيانات محتوى حالياً.');
    }
    final maxAvg = rows.map((r) => r.avg).reduce(math.max);

    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: rows.map((r) {
          final ratio = maxAvg == 0 ? 0.0 : r.avg / maxAvg;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GlassIconBadge(
                      icon: r.icon,
                      size: 26,
                      iconSize: 12,
                      color: r.color,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.label,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${_fmt(r.avg)} متوسط',
                      style: TextStyle(
                        color: r.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(r.color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${r.count} منشور • إجمالي ${_fmt(r.total)}',
                  style: const TextStyle(
                    color: AppColors.mutedSoft,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _arLabel(String type) {
    switch (type) {
      case 'REELS':
      case 'VIDEO':
        return 'ريلز / فيديو';
      case 'IMAGE':
        return 'صور';
      case 'CAROUSEL_ALBUM':
        return 'كاروسيل';
      default:
        return type;
    }
  }

  static IconData _icon(String type) {
    switch (type) {
      case 'REELS':
      case 'VIDEO':
        return Icons.play_circle_fill;
      case 'IMAGE':
        return Icons.image;
      case 'CAROUSEL_ALBUM':
        return Icons.view_carousel;
      default:
        return Icons.grid_view;
    }
  }

  static Color _color(String type) {
    switch (type) {
      case 'REELS':
      case 'VIDEO':
        return AppColors.accentB;
      case 'IMAGE':
        return AppColors.accentA;
      case 'CAROUSEL_ALBUM':
        return AppColors.accentC;
      default:
        return AppColors.muted;
    }
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _TypeRow {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final int avg;
  final int total;

  _TypeRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.avg,
    required this.total,
  });
}

class _ReachTips extends StatelessWidget {
  const _ReachTips();
  @override
  Widget build(BuildContext context) {
    const tips = [
      'استخدم 3 هاشتاقات دقيقة بدلاً من 30 هاشتاق عشوائي.',
      'ريلز أقل من 15 ثانية تصل لأعداد أكبر من الجمهور الجديد.',
      'أضف نص على الغلاف يشرح محتوى الفيديو.',
      'جرّب التعاون مع حساب من نفس المجال — يفتح جمهوراً جديداً.',
    ];
    return Glass(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tips
            .map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accentA,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12.5,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Label({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.accentB),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});
  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
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
