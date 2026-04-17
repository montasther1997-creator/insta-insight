import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/instagram_provider.dart';
import '../providers/analysis_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/shimmer_loader.dart';
import 'analysis_screen.dart';
import 'geo_screen.dart';
import 'videos_screen.dart';
import 'music_screen.dart';
import 'suggestions_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardHome(),
    AnalysisScreen(),
    GeoScreen(),
    VideosScreen(),
    MusicScreen(),
    SuggestionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surface2, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.accentPurple,
          unselectedItemColor: AppColors.muted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'تحليل',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.public_outlined),
              activeIcon: Icon(Icons.public),
              label: 'جغرافي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline),
              activeIcon: Icon(Icons.play_circle),
              label: 'فيديوهات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note_outlined),
              activeIcon: Icon(Icons.music_note),
              label: 'أغاني',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb_outline),
              activeIcon: Icon(Icons.lightbulb),
              label: 'اقتراحات',
            ),
          ],
        ),
      ),
    );
  }
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.bg,
              title: ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'InstaInsight',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.muted),
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Profile card
                  _buildProfileCard(user.profilePictureUrl, user.fullName,
                      '@${user.username}', user.followersCount),
                  const SizedBox(height: 20),

                  // AI Alert
                  aiAnalysis.when(
                    data: (data) {
                      final alert = data['alert'] as String?;
                      if (alert == null) return const SizedBox.shrink();
                      return _buildAiAlert(alert);
                    },
                    loading: () => const ShimmerLoader(height: 60),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),

                  // Stats grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      StatCard(
                        title: 'المتابعون',
                        value: _formatNumber(user.followersCount),
                        icon: Icons.people_outline,
                        color: AppColors.accentPurple,
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                      StatCard(
                        title: 'نسبة التفاعل',
                        value: '${engagement.toStringAsFixed(2)}%',
                        icon: Icons.favorite_outline,
                        color: AppColors.accentPink,
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: 0.1),
                      StatCard(
                        title: 'النمو الأسبوعي',
                        value: weeklyGrowth.when(
                          data: (g) => g >= 0 ? '+$g' : '$g',
                          loading: () => '...',
                          error: (_, __) => '+0',
                        ),
                        subtitle: 'متابع جديد',
                        icon: Icons.trending_up,
                        color: AppColors.accentGreen,
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.1),
                      StatCard(
                        title: 'التقييم',
                        value: aiAnalysis.whenOrNull(
                              data: (d) => '${d['score'] ?? '-'}/10',
                            ) ??
                            '-/10',
                        icon: Icons.star_outline,
                        color: AppColors.accentAmber,
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: 0.1),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // AI Summary
                  aiAnalysis.when(
                    data: (data) => _buildAiSummary(data),
                    loading: () => const ShimmerCardList(count: 1, cardHeight: 150),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileCard(
      String imageUrl, String name, String username, int followers) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentPurple.withValues(alpha: 0.15),
            AppColors.accentPink.withValues(alpha: 0.1),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.surface2,
            backgroundImage:
                imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
            child: imageUrl.isEmpty
                ? const Icon(Icons.person, size: 35, color: AppColors.muted)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  username,
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, size: 14, color: AppColors.accentPurple),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatNumber(followers)} متابع',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.accentPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  Widget _buildAiAlert(String alert) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.accentAmber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alert,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildAiSummary(Map<String, dynamic> data) {
    final summary = data['summary'] as String?;
    final strengths = (data['strengths'] as List<dynamic>?)?.cast<String>() ?? [];
    final weaknesses = (data['weaknesses'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'تحليل Gemini AI',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 12),
            Text(
              summary,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'نقاط القوة',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ...strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('  +  ',
                          style: TextStyle(color: AppColors.accentGreen, fontSize: 13)),
                      Expanded(
                        child: Text(s,
                            style: const TextStyle(
                                color: AppColors.text, fontSize: 12, height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
          if (weaknesses.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'نقاط الضعف',
              style: TextStyle(
                color: AppColors.accentPink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ...weaknesses.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('  -  ',
                          style: TextStyle(color: AppColors.accentPink, fontSize: 13)),
                      Expanded(
                        child: Text(w,
                            style: const TextStyle(
                                color: AppColors.text, fontSize: 12, height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  static String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}
