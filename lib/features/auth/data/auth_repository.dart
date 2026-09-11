import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/user_model.dart';

/// Real Firebase Auth data source for the phone-OTP, Google and Apple flows.
///
/// Every method throws [FirebaseUnavailableException] when Firebase is not
/// configured, and surfaces FirebaseAuthException messages verbatim so the
/// login screen can show actionable errors (invalid code, too many attempts…).
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  /// Sends an SMS OTP to [phoneE164] (e.g. '+96891234567').
  ///
  /// [onCodeSent] receives the verification id needed by [verifyOtp].
  /// [onAutoVerified] fires when Android auto-retrieves the code.
  Future<void> sendOtp({
    required String phoneE164,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(UserProfile user) onAutoVerified,
    required void Function(String message) onError,
  }) async {
    _ensureConfigured();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        try {
          final user = await _signInWithCredential(cred);
          onAutoVerified(user);
        } catch (e) {
          onError(_friendlyError(e));
        }
      },
      verificationFailed: (e) => onError(_friendlyError(e)),
      codeSent: (verificationId, resendToken) =>
          onCodeSent(verificationId, resendToken),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Exchanges the SMS code for a signed-in user session.
  Future<UserProfile> verifyOtp({
    required String verificationId,
    required String code,
    String? preferredLocale,
  }) async {
    _ensureConfigured();
    if (code.trim().length < 6) {
      throw Exception('invalid-code');
    }
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code.trim(),
    );
    return _signInWithCredential(cred, preferredLocale: preferredLocale);
  }

  Future<UserProfile> signInWithGoogle({String? preferredLocale}) async {
    _ensureConfigured();
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('google-signin-cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _signInWithCredential(cred, preferredLocale: preferredLocale);
  }

  Future<UserProfile> signInWithApple({String? preferredLocale}) async {
    _ensureConfigured();
    final appleCred = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.fullName,
        AppleIDAuthorizationScopes.email,
      ],
    );
    final oauthCred = OAuthProvider('apple.com').credential(
      idToken: appleCred.identityToken,
      accessToken: appleCred.authorizationCode,
    );
    return _signInWithCredential(oauthCred, preferredLocale: preferredLocale);
  }

  /// Maps a Firebase [User] to the BAHHAR domain profile and upserts the
  /// Firestore users/{uid} document (displayName, phone/email, createdAt,
  /// preferredLocale).
  Future<UserProfile> _signInWithCredential(
    AuthCredential cred, {
    String? preferredLocale,
  }) async {
    final result = await _auth.signInWithCredential(cred);
    final user = result.user;
    if (user == null) {
      throw Exception('auth-null-user');
    }
    try {
      await _firestore.upsertUserOnLogin(user, preferredLocale: preferredLocale);
    } catch (e) {
      // Profile sync must not block the signed-in session; surface it but
      // keep the login successful.
      debugPrint('BAHHAR: users/{uid} upsert failed: $e');
    }
    return _mapUser(user, preferredLocale: preferredLocale);
  }

  UserProfile _mapUser(User user, {String? preferredLocale}) {
    return UserProfile(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      preferredLocale: preferredLocale ?? 'en',
    );
  }

  Stream<UserProfile?> authStateChanges() {
    if (!FirebaseService.isConfigured) return const Stream.empty();
    return _auth
        .authStateChanges()
        .map((user) => user == null ? null : _mapUser(user));
  }

  Future<void> signOut() async {
    if (!FirebaseService.isConfigured) return;
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Not signed in with Google — nothing to sign out there.
    }
    await _auth.signOut();
  }

  void _ensureConfigured() {
    if (!FirebaseService.isConfigured) {
      throw const FirebaseUnavailableException();
    }
  }

  String _friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-verification-code':
          return 'The verification code is incorrect. Please check and retry.';
        case 'code-expired':
          return 'The verification code expired. Request a new one.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait before retrying.';
        case 'invalid-phone-number':
          return 'That phone number is not valid.';
        case 'network-request-failed':
          return 'Network error. Check your connection and retry.';
        default:
          return e.message ?? 'Authentication failed (${e.code}).';
      }
    }
    if (e is FirebaseUnavailableException) return e.message;
    return e.toString();
  }
}
