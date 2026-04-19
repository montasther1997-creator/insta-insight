import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/analysis_provider.dart';
import '../services/cache_service.dart';
import '../widgets/suggestion_card.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/neumorphic.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  String _filter = 'all';

  Future<void> _generateNewIdeas() async {
    final cache = await CacheService.getInstance();
    await cache.clear(CacheService.keySuggestions);
    ref.invalidate(suggestionsProvider);
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> all) {
    if (_filter == 'all') return all;
    return all.where((s) => (s['priority'] as String? ?? 'medium') == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsState = ref.watch(suggestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('30 فكرة محتوى', style: TextStyle(color: AppColors.text)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: NeumorphicButton(
              onPressed: suggestionsState.isLoading ? null : _generateNewIdeas,
              gold: true,
              radius: 20,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (suggestionsState.isLoading)
                    const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.auto_awesome,
                        size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    suggestionsState.isLoading
                        ? 'جاري التوليد...'
                        : 'ولّد 30 فكرة جديدة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildContentGapAlert(),
          _buildFilters(),
          const SizedBox(height: 4),
          Expanded(
            child: suggestionsState.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: ShimmerCardList(count: 5, cardHeight: 100),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.muted, size: 48),
                    const SizedBox(height: 12),
                    Text('خطأ: $e', style: const TextStyle(color: AppColors.muted, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _generateNewIdeas,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (suggestions) {
                if (suggestions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 60,
                            color: AppColors.muted.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text('لا توجد اقتراحات بعد',
                            style: TextStyle(color: AppColors.muted, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text(
                          'اضغط "ولّد 30 فكرة" لتوليد اقتراحات بالذكاء الاصطناعي',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _applyFilter(suggestions);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('لا توجد أفكار في هذه الفئة',
                        style: TextStyle(color: AppColors.muted, fontSize: 14)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return SuggestionCard(
                      title: s['title'] as String? ?? '',
                      description: s['description'] as String? ?? '',
                      reason: s['reason'] as String?,
                      priority: s['priority'] as String? ?? 'medium',
                      hashtags: s['hashtags'] as String?,
                      estimatedViews: s['estimated_views'] as String?,
                      index: index,
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: index * 40),
                          duration: 400.ms,
                        );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = const [
      {'key': 'all', 'label': 'الكل', 'color': AppColors.accentGold},
      {'key': 'high', 'label': 'عالي', 'color': AppColors.accentGold},
      {'key': 'medium', 'label': 'متوسط', 'color': AppColors.accentGoldBright},
      {'key': 'low', 'label': 'منخفض', 'color': AppColors.accentAluminum},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: filters.map((f) {
          final selected = _filter == f['key'];
          final color = f['color'] as Color;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f['key'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: selected
                      ? NeumorphicDecoration.pressed(radius: 14)
                      : NeumorphicDecoration.raised(radius: 14, offset: 3, blur: 6),
                  child: Text(
                    f['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? color : AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentGapAlert() {
    final aiAnalysis = ref.watch(aiAnalysisProvider);

    return aiAnalysis.when(
      data: (data) {
        final contentIdeas = data['content_ideas'] as List<dynamic>?;
        if (contentIdeas == null || contentIdeas.isEmpty) return const SizedBox.shrink();

        final highPriority = contentIdeas.where(
            (i) => (i as Map<String, dynamic>)['priority'] == 'high').length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: NeumorphicDecoration.raised(radius: 18, offset: 4, blur: 10),
            child: Row(
              children: [
                const NeumorphicIconBadge(
                  icon: Icons.auto_awesome,
                  color: AppColors.accentGold,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'الذكاء الاصطناعي يقترح $highPriority أفكار بأولوية عالية لتحسين حسابك',
                    style: const TextStyle(
                      color: AppColors.text, fontSize: 12, height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
