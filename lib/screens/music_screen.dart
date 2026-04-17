import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/analysis_provider.dart';
import '../models/suggestion_model.dart';
import '../widgets/shimmer_loader.dart';

class MusicScreen extends ConsumerWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(trendingAudioProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('الأغاني الترند', style: TextStyle(color: AppColors.text)),
        automaticallyImplyLeading: false,
      ),
      body: audioState.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: ShimmerCardList(count: 6, cardHeight: 100),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.muted, size: 48),
              const SizedBox(height: 12),
              Text('خطأ: $e',
                  style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            ],
          ),
        ),
        data: (audioList) {
          if (audioList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, size: 60,
                      color: AppColors.muted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد أغاني ترند حالياً',
                    style: TextStyle(color: AppColors.muted, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ستتوفر الأغاني الترند قريباً',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: audioList.length,
            itemBuilder: (context, index) {
              final audio = audioList[index];
              return _AudioCard(
                audio: audio,
                index: index,
              ).animate().fadeIn(
                    delay: Duration(milliseconds: index * 80),
                    duration: 400.ms,
                  ).slideX(begin: 0.05);
            },
          );
        },
      ),
    );
  }
}

class _AudioCard extends StatelessWidget {
  final TrendingAudio audio;
  final int index;

  const _AudioCard({
    required this.audio,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: audio.isRising ? AppColors.primaryGradient : null,
                  color: audio.isRising ? null : AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.music_note,
                    color: audio.isRising ? Colors.white : AppColors.muted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio.audioName,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      audio.artistName,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: audio.isRising
                      ? AppColors.accentGreen.withValues(alpha: 0.15)
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      audio.isRising ? Icons.trending_up : Icons.trending_flat,
                      size: 14,
                      color: audio.isRising ? AppColors.accentGreen : AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${audio.growthRate.toStringAsFixed(0)}%',
                      style: GoogleFonts.jetBrainsMono(
                        color: audio.isRising ? AppColors.accentGreen : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              const Icon(Icons.people_outline, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                '${_formatNumber(audio.usageCount)} استخدام',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              if (audio.countryCodes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public, size: 10, color: AppColors.accentBlue),
                      const SizedBox(width: 4),
                      Text(
                        audio.countryCodes.take(3).join(', '),
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
