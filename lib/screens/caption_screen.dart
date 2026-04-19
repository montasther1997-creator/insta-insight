import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/analysis_provider.dart';
import '../widgets/neumorphic.dart';

class CaptionScreen extends ConsumerStatefulWidget {
  const CaptionScreen({super.key});

  @override
  ConsumerState<CaptionScreen> createState() => _CaptionScreenState();
}

class _CaptionScreenState extends ConsumerState<CaptionScreen> {
  final _ideaController = TextEditingController();
  String _tone = 'ودود';
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  final _tones = const ['ودود', 'مرح', 'جاد', 'تحفيزي', 'قصصي', 'تعليمي'];

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_ideaController.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final aiAnalysis = ref.read(aiAnalysisProvider).valueOrNull ?? {};
      final niche = (aiAnalysis['niche'] as String?) ?? 'عام';
      final gemini = ref.read(geminiServiceProvider);
      final result = await gemini.generateCaption(
        postIdea: _ideaController.text.trim(),
        niche: niche,
        tone: _tone,
      );
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذر توليد الكابشن: $e';
        _loading = false;
      });
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم النسخ'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('مولد الكابشن', style: TextStyle(color: AppColors.text)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputCard(),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: NeumorphicDecoration.raised(radius: 16, offset: 4, blur: 10),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.accentPink, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: const TextStyle(color: AppColors.accentPink, fontSize: 12))),
                ]),
              ),
            if (_result != null) _buildResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: NeumorphicDecoration.raised(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('فكرة المنشور',
              style: TextStyle(
                color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 8),
          Container(
            decoration: NeumorphicDecoration.pressed(radius: 14, offset: 3, blur: 6),
            child: TextField(
              controller: _ideaController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.text, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'مثال: وصفة كيكة سريعة بدون فرن',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 12),
                filled: false,
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('أسلوب الكابشن',
              style: TextStyle(
                color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tones.map((t) {
              final selected = _tone == t;
              return GestureDetector(
                onTap: () => setState(() => _tone = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: selected
                      ? BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGold.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        )
                      : NeumorphicDecoration.raised(radius: 16, offset: 3, blur: 6),
                  child: Text(t,
                      style: TextStyle(
                        color: selected ? Colors.black : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: NeumorphicButton(
              onPressed: _loading ? null : _generate,
              gold: true,
              radius: 18,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accentGoldBright),
                    )
                  else
                    const Icon(Icons.auto_awesome, size: 18, color: AppColors.accentGoldBright),
                  const SizedBox(width: 8),
                  Text(_loading ? 'جاري التوليد...' : 'ولّد كابشن',
                      style: const TextStyle(
                        color: AppColors.accentGoldBright,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final short = r['caption_short'] as String?;
    final medium = r['caption_medium'] as String?;
    final long = r['caption_long'] as String?;
    final hashtags = r['hashtags'] as String?;
    final cta = r['cta'] as String?;
    final hooks = (r['hook_variations'] as List<dynamic>?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (short != null) _captionBlock('قصير', short, AppColors.accentGold),
        if (medium != null) _captionBlock('متوسط', medium, AppColors.accentGoldBright),
        if (long != null) _captionBlock('طويل قصصي', long, AppColors.accentAluminum),
        if (hooks.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Text('هوكات مقترحة',
              style: TextStyle(
                color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 8),
          ...hooks.map((h) => _captionBlock('هوك', h, AppColors.accentGold, small: true)),
        ],
        if (hashtags != null) _captionBlock('هاشتاقات', hashtags, AppColors.accentGoldBright),
        if (cta != null) _captionBlock('دعوة للتفاعل', cta, AppColors.accentGold),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _captionBlock(String label, String text, Color color, {bool small = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: NeumorphicDecoration.raised(radius: 18, offset: 4, blur: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label,
                style: TextStyle(
                  color: color,
                  fontSize: small ? 11 : 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                )),
            const Spacer(),
            GestureDetector(
              onTap: () => _copy(text),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: NeumorphicDecoration.raised(radius: 10, offset: 2, blur: 4),
                child: Icon(Icons.copy, size: 14, color: color),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          SelectableText(text,
              style: TextStyle(
                color: AppColors.text,
                fontSize: small ? 12 : 13,
                height: 1.5,
              )),
        ],
      ),
    );
  }
}
