import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../config/instagram_config.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

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
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPurple.withValues(alpha: 0.3),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 24),
              // Title
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'InstaInsight',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 8),
              const Text(
                'حلل حسابك على إنستغرام بالذكاء الاصطناعي',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
              const Spacer(flex: 2),
              // Features list
              _FeatureItem(
                icon: Icons.analytics_outlined,
                title: 'تحليل متقدم',
                subtitle: 'تحليل شامل لأداء حسابك ومنشوراتك',
                delay: 500,
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.auto_awesome,
                title: 'اقتراحات ذكية',
                subtitle: 'أفكار محتوى مخصصة بالذكاء الاصطناعي',
                delay: 600,
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.public,
                title: 'تحليل جغرافي',
                subtitle: 'اعرف من أين جمهورك وأفضل أوقات النشر',
                delay: 700,
              ),
              const Spacer(flex: 2),
              // Login button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPurple.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'تسجيل الدخول بإنستغرام',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 500.ms).slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 800.ms,
                    duration: 500.ms,
                  ),
              const SizedBox(height: 16),
              // Permission note
              Text(
                InstagramConfig.hasTestToken
                    ? '🔧 وضع الاختبار — سيتم استخدام Test Token مباشرة'
                    : 'سيتم توجيهك لصفحة إنستغرام الرسمية لتسجيل الدخول.\nالتطبيق لا يرى كلمة المرور أبداً.',
                style: TextStyle(
                  color: InstagramConfig.hasTestToken
                      ? AppColors.accentAmber
                      : AppColors.muted,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accentPurple, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms).slideX(
          begin: 0.2,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        );
  }
}
