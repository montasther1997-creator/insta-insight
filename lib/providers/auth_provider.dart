import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final notifier = AuthNotifier(ref.read(authServiceProvider));
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  Timer? _tokenRefreshTimer;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        await _authService.refreshTokenIfNeeded(user);
        _startTokenRefreshTimer(user);
        // Re-fetch user after potential token refresh
        final refreshedUser = await _authService.getCurrentUser();
        state = AsyncValue.data(refreshedUser ?? user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _startTokenRefreshTimer(UserModel user) {
    _tokenRefreshTimer?.cancel();
    // Check token every 6 hours
    _tokenRefreshTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) async {
        final currentUser = state.valueOrNull;
        if (currentUser != null) {
          try {
            await _authService.refreshTokenIfNeeded(currentUser);
            final refreshedUser = await _authService.getCurrentUser();
            if (refreshedUser != null && mounted) {
              state = AsyncValue.data(refreshedUser);
            }
          } catch (e) {
            debugPrint('Token refresh failed: $e');
          }
        }
      },
    );
  }

  Future<void> loginWithInstagram() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.loginWithInstagram();
      if (user != null) {
        _startTokenRefreshTimer(user);
      }
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    _tokenRefreshTimer?.cancel();
    await _authService.logout();
    state = const AsyncValue.data(null);
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}
