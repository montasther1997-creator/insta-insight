import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../models/suggestion_model.dart';
import '../providers/analysis_provider.dart';
import '../widgets/glass.dart';
import '../widgets/shimmer_loader.dart';

/// Full trending-audio catalogue: animated hero, rising-only filter,
/// per-track cover + rank + country badges, plus a "why this matters" tip.
class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  bool _risingOnly = false;
  final AudioPlayer _player = AudioPlayer();
  String? _playingId;
  String? _loadingId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _audioError;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        setState(() {
          _playingId = null;
          _position = Duration.zero;
        });
      }
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle(TrendingAudio audio) async {
    final url = audio.previewUrl;
    if (url == null || url.isEmpty) {
      setState(() => _audioError = 'لا يوجد مقطع صوتي متاح لهذه الأغنية');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _audioError = null);
      });
      return;
    }
    if (_playingId == audio.id) {
      await _player.pause();
      setState(() => _playingId = null);
      return;
    }
    setState(() {
      _loadingId = audio.id;
      _audioError = null;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
      if (!mounted) return;
      setState(() {
        _playingId = audio.id;
        _loadingId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingId = null;
        _playingId = null;
        _audioError = 'تعذر تشغيل المقطع';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _audioError = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(trendingAudioProvider);

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBlobs(opacity: 0.7)),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  onRefresh: () => ref.invalidate(trendingAudioProvider),
                ),
                Expanded(
                  child: audioState.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.all(16),
                      child: ShimmerCardList(count: 6, cardHeight: 90),
                    ),
                    error: (e, _) => _ErrorState(message: '$e'),
                    data: (list) {
                      final filtered =
                          _risingOnly ? list.where((a) => a.isRising).toList() : list;
                      return RefreshIndicator(
                        color: AppColors.accentGold,
                        onRefresh: () async {
                          ref.invalidate(trendingAudioProvider);
                          await ref.read(trendingAudioProvider.future);
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          children: [
                            _HeroBanner(total: list.length, rising: list.where((a) => a.isRising).length),
                            const SizedBox(height: 14),
                            _FilterChips(
                              risingOnly: _risingOnly,
                              onChanged: (v) => setState(() => _risingOnly = v),
                              total: list.length,
                              rising:
                                  list.where((a) => a.isRising).length,
                            ),
                            const SizedBox(height: 12),
                            if (_audioError != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warn
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.warn
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline,
                                          size: 14, color: AppColors.warn),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _audioError!,
                                          style: const TextStyle(
                                            color: AppColors.warn,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (filtered.isEmpty)
                              _EmptyState()
                            else
                              ...filtered.asMap().entries.map((e) => _TrackTile(
                                    audio: e.value,
                                    rank: e.key + 1,
                                    isPlaying: _playingId == e.value.id,
                                    isLoading: _loadingId == e.value.id,
                                    progress: _playingId == e.value.id &&
                                            _duration.inMilliseconds > 0
                                        ? _position.inMilliseconds /
                                            _duration.inMilliseconds
                                        : 0,
                                    onPlayTap: () => _toggle(e.value),
                                  ).animate().fadeIn(
                                        delay: Duration(
                                            milliseconds: e.key * 60),
                                        duration: 350.ms,
                                      ).slideX(begin: 0.04, end: 0)),
                            const SizedBox(height: 16),
                            const _TipCard(),
                          ],
                        ),
                      );
                    },
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

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const Icon(Icons.music_note, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الأغاني الترند',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'الأصوات الصاعدة على إنستغرام وتيك توك',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          HeaderIconBtn(icon: Icons.refresh, onTap: onRefresh),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final int total;
  final int rising;
  const _HeroBanner({required this.total, required this.rising});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGold.withValues(alpha: 0.24),
            AppColors.accentB.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LIVE',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'آخر تحديث',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'ما الذي يصعد الآن؟',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 12,
                      height: 1.6,
                    ),
                    children: [
                      TextSpan(
                        text: '$total',
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: ' صوت ترند، منها '),
                      TextSpan(
                        text: '$rising',
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: ' صاعد بسرعة.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withValues(alpha: 0.5),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.trending_up, color: Colors.black, size: 28),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _FilterChips extends StatelessWidget {
  final bool risingOnly;
  final ValueChanged<bool> onChanged;
  final int total;
  final int rising;
  const _FilterChips({
    required this.risingOnly,
    required this.onChanged,
    required this.total,
    required this.rising,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(
          label: 'الكل ($total)',
          selected: !risingOnly,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: 8),
        _chip(
          label: 'الصاعد فقط ($rising)',
          selected: risingOnly,
          onTap: () => onChanged(true),
          icon: Icons.trending_up,
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentGold.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.accentGold.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 12,
                  color: selected ? AppColors.accentGold : AppColors.muted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.accentGold : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final TrendingAudio audio;
  final int rank;
  final bool isPlaying;
  final bool isLoading;
  final double progress;
  final VoidCallback onPlayTap;

  const _TrackTile({
    required this.audio,
    required this.rank,
    required this.isPlaying,
    required this.isLoading,
    required this.progress,
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? AppColors.accentGold
        : rank == 2
            ? AppColors.accentGoldBright
            : rank == 3
                ? AppColors.accentAluminum
                : AppColors.muted;
    final hasPreview =
        audio.previewUrl != null && audio.previewUrl!.isNotEmpty;
    final highlight = isPlaying || audio.isRising;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentGold
                      .withValues(alpha: isPlaying ? 0.18 : 0.12),
                  Colors.transparent,
                ],
              )
            : null,
        color: highlight ? null : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPlaying
              ? AppColors.accentGold.withValues(alpha: 0.6)
              : audio.isRising
                  ? AppColors.accentGold.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.06),
          width: isPlaying ? 1.3 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: rankColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PlayCover(
            url: audio.coverUrl ?? '',
            rising: audio.isRising,
            isPlaying: isPlaying,
            isLoading: isLoading,
            hasPreview: hasPreview,
            onTap: onPlayTap,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  audio.audioName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  audio.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.people_outline,
                        size: 10, color: AppColors.mutedSoft),
                    const SizedBox(width: 3),
                    Text(
                      '${_fmt(audio.usageCount)} استخدام',
                      style: const TextStyle(
                        color: AppColors.mutedSoft,
                        fontSize: 10,
                      ),
                    ),
                    if (audio.countryCodes.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.public,
                          size: 10, color: AppColors.accentGoldBright),
                      const SizedBox(width: 3),
                      Text(
                        audio.countryCodes.take(3).join(' · '),
                        style: const TextStyle(
                          color: AppColors.accentGoldBright,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: audio.isRising
                      ? AppColors.accentGold.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      audio.isRising
                          ? Icons.trending_up
                          : Icons.trending_flat,
                      size: 11,
                      color: audio.isRising
                          ? AppColors.accentGold
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '+${audio.growthRate.toStringAsFixed(0)}٪',
                      style: GoogleFonts.jetBrainsMono(
                        color: audio.isRising
                            ? AppColors.accentGold
                            : AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (audio.duration != null && audio.duration! > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${audio.duration}s',
                  style: const TextStyle(
                    color: AppColors.mutedSoft,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
          if (isPlaying) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentGold),
              ),
            ),
          ],
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

class _PlayCover extends StatelessWidget {
  final String url;
  final bool rising;
  final bool isPlaying;
  final bool isLoading;
  final bool hasPreview;
  final VoidCallback onTap;
  const _PlayCover({
    required this.url,
    required this.rising,
    required this.isPlaying,
    required this.isLoading,
    required this.hasPreview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasPreview ? onTap : null,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: (rising || isPlaying) ? AppColors.goldGradient : null,
          color: (rising || isPlaying)
              ? null
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          boxShadow: (rising || isPlaying)
              ? [
                  BoxShadow(
                    color: AppColors.accentGold
                        .withValues(alpha: isPlaying ? 0.55 : 0.35),
                    blurRadius: isPlaying ? 14 : 10,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => _fallback(rising || isPlaying),
                  placeholder: (_, _) => _fallback(rising || isPlaying),
                )
              else
                _fallback(rising || isPlaying),
              if (hasPreview)
                Container(color: Colors.black.withValues(alpha: 0.35)),
              if (hasPreview)
                Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(bool active) {
    return Container(
      color: active
          ? Colors.black.withValues(alpha: 0.15)
          : Colors.white.withValues(alpha: 0.04),
      child: Icon(
        Icons.music_note,
        color: active ? Colors.black : AppColors.muted,
        size: 20,
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tips_and_updates_outlined,
                  size: 14, color: AppColors.accentB),
              SizedBox(width: 6),
              Text(
                'كيف تستفيد؟',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...const [
            'استخدم الأصوات الصاعدة خلال 3-5 أيام من صعودها — الخوارزمية تدفعها أكثر.',
            'أربط الصوت بمحتوى يناسب جمهورك، مو فقط تقليد أعمى.',
            'راقب الأعلام (AE، SA، IQ) لتعرف هل الصوت قريب من جمهورك.',
          ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: AppColors.accentB)),
                    Expanded(
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.music_off,
              size: 52, color: AppColors.muted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'لا توجد أصوات في هذا الفلتر',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.warn, size: 48),
            const SizedBox(height: 12),
            Text(
              'خطأ في التحميل',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
