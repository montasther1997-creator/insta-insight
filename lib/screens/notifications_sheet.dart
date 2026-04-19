import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/analysis_provider.dart';
import '../providers/instagram_provider.dart';
import '../utils/tap_feedback.dart';
import '../widgets/glass.dart';

/// Opens a glass bottom-sheet listing the most actionable updates about the
/// user's Instagram account — pulled live from the analysis, growth and
/// trending-audio providers that already back the home screen.
void showNotificationsSheet(BuildContext context) {
  TapFeedback.light();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _NotificationsSheet(),
  );
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = _buildAlerts(ref);
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollCtrl) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Glass(
            radius: 28,
            strong: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Grabber(),
                _Header(count: alerts.length),
                Expanded(
                  child: alerts.isEmpty
                      ? _EmptyState()
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: alerts.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _AlertTile(alert: alerts[i]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Grabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.glassBorder,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          const GlassIconBadge(
            icon: Icons.notifications_active_outlined,
            color: AppColors.accentGold,
            size: 38,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التحديثات',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'أبرز ما يهمك في حسابك',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GlassChip(
            color: AppColors.accentGold,
            child: Text('$count جديد'),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final _Alert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      borderColor: alert.tint.withValues(alpha: 0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassIconBadge(
            icon: alert.icon,
            color: alert.tint,
            size: 34,
            iconSize: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: TextStyle(
                          color: alert.tint,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      alert.when,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.body,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 12,
                    height: 1.55,
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read_outlined,
                size: 48, color: AppColors.muted.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
            const Text(
              'لا توجد تحديثات جديدة',
              style: TextStyle(color: AppColors.textSoft, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'سنخبرك فور ظهور أي تغير مهم في حسابك',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Alert {
  final IconData icon;
  final String title;
  final String body;
  final Color tint;
  final String when;
  const _Alert({
    required this.icon,
    required this.title,
    required this.body,
    required this.tint,
    required this.when,
  });
}

List<_Alert> _buildAlerts(WidgetRef ref) {
  final out = <_Alert>[];
  final analysis = ref.watch(aiAnalysisProvider).valueOrNull ?? {};
  final weekly = ref.watch(weeklyGrowthProvider).valueOrNull ?? 0;
  final engagement = ref.watch(engagementRateProvider);
  final audio = ref.watch(trendingAudioProvider).valueOrNull ?? [];
  final media = ref.watch(mediaProvider).valueOrNull ?? [];

  final alertText = analysis['alert'] as String?;
  if (alertText != null && alertText.trim().isNotEmpty) {
    out.add(_Alert(
      icon: Icons.priority_high_rounded,
      title: 'تنبيه ذكي',
      body: alertText.trim(),
      tint: AppColors.warn,
      when: 'الآن',
    ));
  }

  if (weekly != 0) {
    out.add(_Alert(
      icon: weekly > 0 ? Icons.trending_up : Icons.trending_down,
      title: weekly > 0 ? 'نمو في المتابعين' : 'تراجع في المتابعين',
      body: weekly > 0
          ? 'اكتسبت $weekly متابع هذا الأسبوع — واصل النشر بنفس الجودة.'
          : 'فقدت ${weekly.abs()} متابع هذا الأسبوع — نوّع المحتوى وراجع آخر المنشورات.',
      tint: weekly > 0 ? AppColors.good : AppColors.bad,
      when: 'هذا الأسبوع',
    ));
  }

  if (engagement > 0) {
    out.add(_Alert(
      icon: Icons.favorite_outline,
      title: 'نسبة التفاعل',
      body: engagement >= 3
          ? 'نسبة تفاعلك ${engagement.toStringAsFixed(1)}٪ — أعلى من متوسط السوق.'
          : 'نسبة تفاعلك ${engagement.toStringAsFixed(1)}٪ — جرّب عناوين أقوى وسؤال مباشر لجمهورك.',
      tint: engagement >= 3 ? AppColors.good : AppColors.warn,
      when: 'آخر 30 يوم',
    ));
  }

  final strengths = (analysis['strengths'] as List?)?.cast<String>() ?? const [];
  if (strengths.isNotEmpty) {
    out.add(_Alert(
      icon: Icons.check_circle_outline,
      title: 'نقطة قوة',
      body: strengths.first,
      tint: AppColors.good,
      when: 'من تحليل الـ AI',
    ));
  }

  final weaknesses = (analysis['weaknesses'] as List?)?.cast<String>() ?? const [];
  if (weaknesses.isNotEmpty) {
    out.add(_Alert(
      icon: Icons.lightbulb_outline,
      title: 'فرصة تحسين',
      body: weaknesses.first,
      tint: AppColors.warn,
      when: 'من تحليل الـ AI',
    ));
  }

  if (media.isNotEmpty) {
    final best = media.reduce(
        (a, b) => a.totalEngagement > b.totalEngagement ? a : b);
    out.add(_Alert(
      icon: Icons.auto_awesome,
      title: 'أفضل منشور حالياً',
      body:
          '${_fmt(best.viewsCount)} مشاهدة · ${_fmt(best.likesCount)} لايك · ${_fmt(best.commentsCount)} تعليق',
      tint: AppColors.accentB,
      when: 'من آخر المنشورات',
    ));
  }

  final rising = audio.where((a) => a.isRising).length;
  if (rising > 0) {
    out.add(_Alert(
      icon: Icons.music_note,
      title: '$rising صوت صاعد',
      body:
          'أصوات صاعدة تستحق التجربة قبل يضعف ترندها — شوفها في شاشة الأغاني.',
      tint: AppColors.accentC,
      when: 'تحديث يومي',
    ));
  }

  return out;
}

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

/// Lightweight count used to drive the header badge. Kept cheap so the
/// dashboard can watch it without triggering extra work.
int notificationsCount(WidgetRef ref) => _buildAlerts(ref).length;
