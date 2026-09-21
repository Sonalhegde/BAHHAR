import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/user_model.dart';
import '../services/firebase_service.dart';

/// Full auth UI state: signed-in profile + in-flight flag + last error.
class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository = AuthRepository();
  String? _pendingVerificationId;

  AuthNotifier() : super(const AuthState());

  /// True when Firebase is usable; drives the login screen's hints.
  bool get firebaseAvailable => FirebaseService.isConfigured;

  /// OTP step the phone flow is currently in, for UI transitions.
  bool get otpSent => _pendingVerificationId != null;

  Future<void> sendOtp({
    required String phoneE164,
    required bool isArabic,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.sendOtp(
        phoneE164: phoneE164,
        onCodeSent: (verificationId, resendToken) {
          _pendingVerificationId = verificationId;
          state = state.copyWith(isLoading: false, clearError: true);
        },
        onAutoVerified: (user) {
          _pendingVerificationId = null;
          state = AuthState(user: user);
        },
        onError: (message) {
          state = state.copyWith(isLoading: false, error: message);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _message(e, isArabic),
      );
    }
  }

  Future<bool> verifyOtp(String code, {required bool isArabic}) async {
    final verificationId = _pendingVerificationId;
    if (verificationId == null) {
      state = state.copyWith(
          error: isArabic ? 'أرسل رمز التحقق أولاً' : 'Request a code first.');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.verifyOtp(
        verificationId: verificationId,
        code: code,
      );
      _pendingVerificationId = null;
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().contains('invalid-code')
            ? (isArabic ? 'رمز التحقق غير صحيح' : 'Invalid verification code.')
            : _message(e, isArabic),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle({required bool isArabic}) =>
      _attemptSignIn(() => _repository.signInWithGoogle(), isArabic);

  Future<bool> signInWithApple({required bool isArabic}) =>
      _attemptSignIn(() => _repository.signInWithApple(), isArabic);

  /// Email/password sign-in and registration. Same state machine as the social
  /// flows; unlike Google/Apple nothing can be cancelled here, so a failed attempt
  /// always leaves a message on screen rather than silently returning false.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    required bool isArabic,
  }) =>
      _attemptSignIn(
        () => _repository.signInWithEmail(email: email, password: password),
        isArabic,
      );

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required bool isArabic,
  }) =>
      _attemptSignIn(
        () => _repository.registerWithEmail(email: email, password: password),
        isArabic,
      );

  Future<bool> _attemptSignIn(
    Future<UserProfile> Function() action,
    bool isArabic,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await action();
      state = AuthState(user: user);
      return true;
    } catch (e) {
      final cancelled = e.toString().contains('cancelled');
      state = state.copyWith(
        isLoading: false,
        error:
            cancelled ? null : _message(e, isArabic),
      );
      return false;
    }
  }

  /// Local exploration session without Firebase; never written to Firestore.
  void signInAsGuest() {
    state = AuthState(
      user: UserProfile(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        email: '',
        displayName: 'Guest Explorer',
        isGuest: true,
      ),
    );
  }

  void updateHomeRegion(String region) {
    final user = state.user;
    if (user != null) state = AuthState(user: user.copyWith(homeRegion: region));
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _message(Object e, bool isArabic) {
    final fallback =
        isArabic ? 'تعذر تسجيل الدخول، حاول مجدداً' : 'Sign-in failed, please retry.';
    final text = e.toString();
    if (text.contains('FirebaseUnavailableException') ||
        text.contains('Firebase is not configured')) {
      return isArabic
          ? 'Firebase غير مُعد في هذا الإصدار — أضف ملفات الإعداد للمتابعة.'
          : 'Firebase is not configured in this build — add the config files to continue.';
    }
    if (text.contains('network')) {
      return isArabic ? 'خطأ في الشبكة' : 'Network error.';
    }
    // FirebaseAuthException messages are already user-friendly English.
    final cleaned = text.replaceFirst('Exception: ', '');
    return cleaned.length < 160 ? cleaned : fallback;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

/// Convenience alias for screens that only need the signed-in profile.
final authProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authNotifierProvider).user;
});
