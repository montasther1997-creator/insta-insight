import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/analysis_provider.dart';
import '../widgets/suggestion_card.dart';
import '../widgets/shimmer_loader.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  Future<void> _generateNewIdeas() async {
    // Invalidate cache and refetch
    ref.invalidate(suggestionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsState = ref.watch(suggestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('اقتراحات المحتوى', style: TextStyle(color: AppColors.text)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Generate button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: suggestionsState.isLoading ? null : _generateNewIdeas,
                icon: suggestionsState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.accentPurple),
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(suggestionsState.isLoading ? 'جاري التوليد...' : 'ولّد أفكار جديدة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentPurple,
                  side: BorderSide(
                    color: AppColors.accentPurple.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          // AI analysis content gap
          _buildContentGapAlert(),
          const SizedBox(height: 8),
          // Suggestions list
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
                    Text('خطأ: $e',
                        style: const TextStyle(color: AppColors.muted, fontSize: 14)),
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
                        const Text(
                          'لا توجد اقتراحات بعد',
                          style: TextStyle(color: AppColors.muted, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'اضغط "ولّد أفكار جديدة" لتوليد اقتراحات بالذكاء الاصطناعي',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final s = suggestions[index];
                    return SuggestionCard(
                      title: s['title'] as String? ?? '',
                      description: s['description'] as String? ?? '',
                      reason: s['reason'] as String?,
                      priority: s['priority'] as String? ?? 'medium',
                      index: index,
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: index * 60),
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

  Widget _buildContentGapAlert() {
    final aiAnalysis = ref.watch(aiAnalysisProvider);

    return aiAnalysis.when(
      data: (data) {
        final contentIdeas = data['content_ideas'] as List<dynamic>?;
        if (contentIdeas == null || contentIdeas.isEmpty) return const SizedBox.shrink();

        final highPriority = contentIdeas.where(
            (i) => (i as Map<String, dynamic>)['priority'] == 'high').length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accentBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الذكاء الاصطناعي يقترح $highPriority أفكار بأولوية عالية لتحسين حسابك',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
