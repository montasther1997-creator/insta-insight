import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      loading: () {
        // Wait and retry
        Future.delayed(const Duration(seconds: 1), _checkAuth);
      },
      error: (e, st) {
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 60,
                color: Colors.white,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            // App name
            ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                'InstaInsight',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            const Text(
              'محلل حسابات إنستغرام الذكي',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 600.ms),
            const SizedBox(height: 48),
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accentPurple.withValues(alpha: 0.6),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 900.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
