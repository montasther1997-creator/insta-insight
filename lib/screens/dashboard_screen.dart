import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/instagram_provider.dart';
import '../providers/analysis_provider.dart';
import '../utils/tap_feedback.dart';
import '../widgets/stat_card.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/glass.dart';
import 'analysis_screen.dart';
import 'videos_screen.dart';
import 'suggestions_screen.dart';
import 'planner_screen.dart';
import 'caption_screen.dart';
import 'score_detail_screen.dart';
import 'followers_detail_screen.dart';
import 'engagement_detail_screen.dart';
import 'growth_detail_screen.dart';
import 'reach_detail_screen.dart';
import 'notifications_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  late final AnimationController _transition;

  static const _curve = Cubic(0.25, 0.8, 0.3, 1.0);

  final List<Widget> _screens = const [
    _DashboardHome(),
    AnalysisScreen(),
    VideosScreen(),
    SuggestionsScreen(),
    PlannerScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _transition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  void _onTabSelected(int i) {
    if (i == _currentIndex) return;
    TapFeedback.light();
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = i;
    });
    _transition.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final dir = (_currentIndex - _previousIndex).sign; // -1, 0, 1
    final sign = rtl ? -1 : 1;
    // In LTR, moving right means the new screen enters from the right.
    // In RTL, logical "next" is visually left, so flip.
    final startOffset = 0.08 * dir * sign;

    return Scaffold(
      backgroundColor: AppColors.bg1,
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBlobs(opacity: 0.85)),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _transition,
              builder: (context, child) {
                final t = _curve.transform(_transition.value);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(
                      (1 - t) * startOffset *
                          MediaQuery.of(context).size.width,
                      0,
                    ),
                    child: Transform.scale(
                      scale: 0.96 + 0.04 * t,
                      alignment: Alignment.center,
                      child: child,
                    ),
                  ),
                );
              },
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _FloatingTabBar(
        active: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

/// Floating glass tab bar with a sliding animated pill indicator.
/// The pill glides between tabs via AnimatedAlign; active icons bounce
/// (scale + glow) while labels cross-fade.
class _FloatingTabBar extends StatelessWidget {
  final int active;
  final ValueChanged<int> onTap;

  const _FloatingTabBar({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      _TabSpec(icon: Icons.home_outlined, label: 'الرئيسية'),
      _TabSpec(icon: Icons.bar_chart_rounded, label: 'التحليل'),
      _TabSpec(icon: Icons.play_circle_outline, label: 'فيديوهات'),
      _TabSpec(icon: Icons.auto_awesome, label: 'الاقتراحات'),
      _TabSpec(icon: Icons.event_note_outlined, label: 'خطة'),
    ];
    final count = tabs.length;
    // AnimatedAlign x ranges from -1 (leftmost) to 1 (rightmost); pill width
    // is 2/count of the track. Convert the active index into the matching x.
    final alignX = count == 1 ? 0.0 : (active * 2.0 / (count - 1)) - 1.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Glass(
          radius: 28,
          strong: true,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: SizedBox(
            height: 52,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth = constraints.maxWidth / count;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sliding gold pill indicator — design spec: 650ms slide.
                    // AlignmentDirectional respects RTL (start = right in AR).
                    AnimatedAlign(
                      alignment: AlignmentDirectional(alignX, 0),
                      duration: const Duration(milliseconds: 650),
                      curve: const Cubic(0.25, 0.8, 0.3, 1.0),
                      child: Container(
                        width: slotWidth - 8,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accentGold.withValues(alpha: 0.55),
                            width: 0.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGold.withValues(alpha: 0.35),
                              blurRadius: 22,
                              spreadRadius: -6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tabs above the pill.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(count, (i) {
                        final isActive = i == active;
                        final t = tabs[i];
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTap(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TabIcon(icon: t.icon, active: isActive),
                                  const SizedBox(height: 2),
                                  AnimatedDefaultTextStyle(
                                    duration:
                                        const Duration(milliseconds: 320),
                                    curve: Curves.easeOut,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isActive
                                          ? const Color(0xFF2A0F05)
                                          : AppColors.muted,
                                    ),
                                    child: Text(t.label),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab icon that bounces (scale overshoot) and gains a glow when activated.
class _TabIcon extends StatefulWidget {
  final IconData icon;
  final bool active;
  const _TabIcon({required this.icon, required this.active});

  @override
  State<_TabIcon> createState() => _TabIconState();
}

class _TabIconState extends State<_TabIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _bounce = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _ctl, curve: Curves.elasticOut),
    );
    if (widget.active) _ctl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _TabIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _ctl.forward(from: 0);
    } else if (!widget.active && oldWidget.active) {
      _ctl.reverse();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, _) {
        // Scale ease: elasticOut goes 1→past-end→settles. Wrap so inactive
        // icons just sit at scale 1 and active ones overshoot gently.
        final scale = widget.active
            ? 1.0 + (_bounce.value - 1.0) * 0.6 // dampen the overshoot
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Icon(
            widget.icon,
            size: 20,
            // Dark icon on the gold pill reads cleaner than a brand color.
            color: widget.active
                ? const Color(0xFF2A0F05)
                : AppColors.muted,
            shadows: widget.active
                ? [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}

class _TabSpec {
  final IconData icon;
  final String label;
  const _TabSpec({required this.icon, required this.label});
}

class _DashboardHome extends ConsumerWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final engagement = ref.watch(engagementRateProvider);
    final aiAnalysis = ref.watch(aiAnalysisProvider);
    final weeklyGrowth = ref.watch(weeklyGrowthProvider);

    return authState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accentB),
      ),
      error: (e, _) => Center(
        child: Text('خطأ: $e',
            style: const TextStyle(color: AppColors.bad)),
      ),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final score = aiAnalysis
                .whenOrNull(data: (d) => d['score'])
                ?.toString() ??
            '-';
        final summary =
            aiAnalysis.whenOrNull(data: (d) => d['summary'] as String?);
        final strengths = (aiAnalysis.whenOrNull(
                    data: (d) => d['strengths'] as List<dynamic>?) ??
                const [])
            .cast<String>();
        final weaknesses = (aiAnalysis.whenOrNull(
                    data: (d) => d['weaknesses'] as List<dynamic>?) ??
                const [])
            .cast<String>();
        final alert = aiAnalysis.whenOrNull(
          data: (d) => d['alert'] as String?,
        );

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _DashboardHeader(
                  name: user.fullName,
                  username: '@${user.username}',
                  avatarUrl: user.profilePictureUrl,
                  notifCount: notificationsCount(ref),
                  onCaption: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CaptionScreen()),
                  ),
                  onNotifications: () => showNotificationsSheet(context),
                  onLogout: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroScoreCard(
                      score: score,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ScoreDetailScreen()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        StatCard(
                          title: 'المتابعون',
                          value: _formatNumber(user.followersCount),
                          icon: Icons.person_outline,
                          color: AppColors.accentB,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const FollowersDetailScreen()),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.1),
                        StatCard(
                          title: 'التفاعل',
                          value: '${engagement.toStringAsFixed(1)}%',
                          icon: Icons.favorite_outline,
                          color: AppColors.accentB,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const EngagementDetailScreen()),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideX(begin: 0.1),
                        StatCard(
                          title: 'النمو الأسبوعي',
                          value: weeklyGrowth.when(
                            data: (g) => g >= 0 ? '+$g' : '$g',
                            loading: () => '...',
                            error: (_, _) => '+0',
                          ),
                          subtitle: 'متابع جديد',
                          icon: Icons.trending_up,
                          color: AppColors.accentA,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const GrowthDetailScreen()),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideX(begin: -0.1),
                        _ReachStatCard(
                          followers: user.followersCount,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ReachDetailScreen()),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms)
                            .slideX(begin: 0.1),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (alert != null && alert.isNotEmpty) ...[
                      _AlertStrip(alert: alert),
                      const SizedBox(height: 16),
                    ],

                    // AI summary header.
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome,
                            size: 13, color: AppColors.accentB),
                        SizedBox(width: 6),
                        Text(
                          'ملخّص ذكي',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    aiAnalysis.when(
                      loading: () => const ShimmerCardList(
                          count: 1, cardHeight: 150),
                      error: (e, st) => const SizedBox.shrink(),
                      data: (_) => _SummaryCard(
                        summary: summary ??
                            'حسابك في نمو صحي. استمر في النشر بانتظام.',
                        strengths: strengths.take(2).toList(),
                        weaknesses: weaknesses.take(2).toList(),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ────────── Dashboard header ──────────
class _DashboardHeader extends StatelessWidget {
  final String name;
  final String username;
  final String avatarUrl;
  final int notifCount;
  final VoidCallback onCaption;
  final VoidCallback onNotifications;
  final VoidCallback onLogout;

  const _DashboardHeader({
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.notifCount,
    required this.onCaption,
    required this.onNotifications,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _GradientAvatar(url: avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً مجدداً',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  name.isEmpty ? username : name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          HeaderIconBtn(icon: Icons.edit_note, onTap: onCaption),
          const SizedBox(width: 8),
          HeaderIconBtn(
            icon: Icons.notifications_none_rounded,
            badge: notifCount > 0 ? '$notifCount' : null,
            onTap: onNotifications,
          ),
          const SizedBox(width: 8),
          HeaderIconBtn(icon: Icons.logout, onTap: onLogout),
        ],
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  final String url;
  const _GradientAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: AppColors.bg1,
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          backgroundColor: AppColors.bg3,
          backgroundImage:
              url.isNotEmpty ? CachedNetworkImageProvider(url) : null,
          child: url.isEmpty
              ? const Icon(Icons.person,
                  size: 20, color: AppColors.muted)
              : null,
        ),
      ),
    );
  }
}

// ────────── Hero rating card ──────────
class _HeroScoreCard extends StatelessWidget {
  final String score;
  final VoidCallback? onTap;
  const _HeroScoreCard({required this.score, this.onTap});

  @override
  Widget build(BuildContext context) {
    final percent = double.tryParse(score) ?? 0;
    final progress = (percent / 10).clamp(0.0, 1.0);
    final card = Glass(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 14, color: AppColors.accentB),
              const SizedBox(width: 6),
              const Text(
                'تقييم AI',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.accentB,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (onTap != null)
                const Icon(Icons.chevron_left,
                    size: 18, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  GradientText(
                    score,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 0.9,
                    ),
                  ),
                  const Text(
                    '/10',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'أداء ممتاز',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'محتواك يتفوق على 82٪ من الحسابات المشابهة',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSoft,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress == 0 ? 0.84 : progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accentB),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GlassChip(
                color: AppColors.good,
                child: const Text('↑ نقطة عن الشهر الماضي'),
              ),
              const SizedBox(width: 6),
              GlassChip(child: const Text('طيران إلى 9.0')),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

// ────────── Alert strip ──────────
class _AlertStrip extends StatelessWidget {
  final String alert;
  const _AlertStrip({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassIconBadge(
            icon: Icons.auto_awesome,
            size: 34,
            iconSize: 16,
            color: AppColors.accentA,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────── AI Summary Card ──────────
class _SummaryCard extends StatelessWidget {
  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;

  const _SummaryCard({
    required this.summary,
    required this.strengths,
    required this.weaknesses,
  });

  @override
  Widget build(BuildContext context) {
    final bullets = <Widget>[
      ...strengths.map((s) => _MiniBullet(color: AppColors.good, text: s)),
      ...weaknesses.map((w) => _MiniBullet(color: AppColors.warn, text: w)),
    ];

    return Glass(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13.5,
              height: 1.8,
            ),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bullets
                  .map((w) => SizedBox(width: 140, child: w))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ────────── Enhanced reach tile with gradient glow + mini sparkline ──────────
class _ReachStatCard extends StatelessWidget {
  final int followers;
  final VoidCallback onTap;
  const _ReachStatCard({required this.followers, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Estimated reach: 3.2x followers (non-follower discovery boost).
    final reach = (followers * 3.2).round();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        children: [
          Glass(
            radius: 20,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            gradient: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: const LinearGradient(
                          colors: [AppColors.accentA, AppColors.accentB],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentA.withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.podcasts,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const GlassChip(
                      color: AppColors.good,
                      child: Text('+12%'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 20,
                  child: CustomPaint(
                    painter: _SparkPainter(),
                    size: const Size(double.infinity, 20),
                  ),
                ),
                const SizedBox(height: 4),
                GradientText(
                  _format(reach),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'الوصول',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 10,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pts = const [0.35, 0.5, 0.42, 0.6, 0.55, 0.72, 0.65, 0.85, 0.78, 0.92];
    final dx = size.width / (pts.length - 1);

    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = i * dx;
      final y = size.height * (1 - pts[i]);
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
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [AppColors.accentA, AppColors.accentB],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniBullet extends StatelessWidget {
  final Color color;
  final String text;
  const _MiniBullet({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 11.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
