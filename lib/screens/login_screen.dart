import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../config/instagram_config.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/glass.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  Map<String, String>? _lastLoginHint;

  @override
  void initState() {
    super.initState();
    _loadLastLoginHint();
  }

  Future<void> _loadLastLoginHint() async {
    final hint = await AuthService().getLastLoginHint();
    if (!mounted) return;
    setState(() => _lastLoginHint = hint);
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authStateProvider.notifier).loginWithInstagram();
      if (!mounted) return;

      final authState = ref.read(authStateProvider);
      if (authState.valueOrNull != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تسجيل الدخول: $e'),
          backgroundColor: AppColors.bad,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBlobs()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Mini logo + brand name.
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentB.withValues(alpha: 0.67),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              GradientText(
                                'Insta',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'Insight',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 44),
                      const Text(
                        'أهلاً بك',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                          color: AppColors.text,
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      Row(
                        children: [
                          GradientText(
                            'في المستقبل',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const Text(
                            ' ✨',
                            style: TextStyle(fontSize: 28),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                      const SizedBox(height: 12),
                      const Text(
                        'سجّل الدخول وشاهد حسابك ينطلق بتحليلات ذكية مخصّصة لك.',
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                      const SizedBox(height: 32),

                      // Primary CTA — gradient pill.
                      _PrimaryInstaButton(
                        isLoading: _isLoading,
                        onTap: _isLoading ? null : _handleLogin,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.2, end: 0),

                      if (_lastLoginHint != null) ...[
                        const SizedBox(height: 28),
                        _OrDivider(label: 'تسجيلات دخول سابقة')
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 400.ms),
                        const SizedBox(height: 12),
                        _LastLoginRow(
                          hint: _lastLoginHint!,
                          onTap: _isLoading ? null : _handleLogin,
                        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                      ],

                      const SizedBox(height: 24),

                      // Perks glass panel.
                      Glass(
                        radius: 22,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _PerkRow(
                              icon: Icons.auto_awesome,
                              text: 'تحليل بالذكاء الاصطناعي',
                            ),
                            SizedBox(height: 10),
                            _PerkRow(
                              icon: Icons.local_fire_department,
                              text: 'اكتشف أفضل أوقات النشر',
                            ),
                            SizedBox(height: 10),
                            _PerkRow(
                              icon: Icons.lightbulb_outline,
                              text: 'اقتراحات مخصّصة لك',
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                      const Spacer(),
                      const SizedBox(height: 16),
                      Text(
                        InstagramConfig.hasTestToken
                            ? 'وضع الاختبار — سيتم استخدام Test Token مباشرة'
                            : 'بمتابعتك، فإنك توافق على الشروط وسياسة الخصوصية',
                        style: TextStyle(
                          color: InstagramConfig.hasTestToken
                              ? AppColors.accentA
                              : AppColors.mutedSoft,
                          fontSize: 11,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryInstaButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  const _PrimaryInstaButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.85 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentB.withValues(alpha: 0.67),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: -10,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.camera_alt_outlined,
                          size: 22, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'متابعة باستخدام إنستغرام',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _LastLoginRow extends StatelessWidget {
  final Map<String, String> hint;
  final VoidCallback? onTap;
  const _LastLoginRow({required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final username = hint['username'] ?? '';
    final fullName = hint['fullName'] ?? '';
    final profileUrl = hint['profileUrl'] ?? '';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: profileUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profileUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const ColoredBox(
                          color: AppColors.bg2,
                          child: Icon(Icons.person,
                              color: AppColors.muted, size: 18),
                        ),
                      )
                    : const ColoredBox(
                        color: AppColors.bg2,
                        child: Icon(Icons.person,
                            color: AppColors.muted, size: 18),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (fullName.isNotEmpty)
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Row(
                    children: [
                      const Text(
                        '@',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.login, size: 16, color: AppColors.accentB),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.line, height: 1)),
      ],
    );
  }
}

class _PerkRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PerkRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassIconBadge(icon: icon, size: 28, iconSize: 14),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
