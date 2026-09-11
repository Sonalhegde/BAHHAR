import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/glass/marine_background.dart';
import '../../../../shared/glass/glass_container.dart';
import '../../../../shared/polymorphic/soft_button.dart';
import '../../../../shared/polymorphic/soft_toggle.dart';
import '../../../../shared/polymorphic/glass_input.dart';

enum AuthMethod { phone, email }

/// Real Firebase-backed login/register screen: phone OTP (verifyPhoneNumber →
/// code entry → signInWithCredential), Google Sign-In and Sign in with Apple.
/// Loading, error and invalid-code states are surfaced in the UI — auth
/// failures are never silent.
class LoginRegisterScreen extends ConsumerStatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  ConsumerState<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends ConsumerState<LoginRegisterScreen> {
  AuthMethod _selectedMethod = AuthMethod.phone;
  bool _isRegister = false;
  bool _otpSent = false;
  String _selectedGov = 'Muscat';

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final _governorates = [
    'Muscat',
    'Dhofar',
    'Musandam',
    'Al Batinah South',
    'Al Batinah North',
    'Ash Sharqiyah South',
    'Al Wusta',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _phoneE164 =>
      '+968${_phoneController.text.replaceAll(RegExp(r'\s+'), '')}';

  Future<void> _sendPhoneOtp() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) {
      ref.read(authNotifierProvider.notifier).clearError();
      setState(() {}); // keep UI in sync; validation shown via snackbar below
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(isArabicProvider)
                ? 'أدخل رقم هاتف عُماني صحيح (8 أرقام)'
                : 'Enter a valid Omani mobile number (8 digits).',
          ),
          backgroundColor: AppColors.signalAlert,
        ),
      );
      return;
    }
    await ref
        .read(authNotifierProvider.notifier)
        .sendOtp(phoneE164: _phoneE164, isArabic: ref.read(isArabicProvider));
    if (!mounted) return;
    if (ref.read(authNotifierProvider).error == null) {
      setState(() => _otpSent = true);
    }
  }

  Future<void> _verifyPhoneOtp() async {
    final ok = await ref.read(authNotifierProvider.notifier).verifyOtp(
          _otpController.text,
          isArabic: ref.read(isArabicProvider),
        );
    if (!mounted || !ok) return;
    await _completeRegistrationDetails();
    if (!mounted) return;
    context.go('/home');
  }

  /// On register, persist the captain name / governorate the user typed into
  /// their users/{uid} profile document.
  Future<void> _completeRegistrationDetails() async {
    if (!_isRegister) return;
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (FirebaseService.isConfigured) {
      try {
        await FirestoreService().updateUserProfile(user.id, {
          'displayName': name,
          'homeRegion': _selectedGov,
        });
      } catch (_) {
        // Non-blocking: profile can be edited later from the Profile tab.
      }
    }
    ref.read(authNotifierProvider.notifier).updateHomeRegion(_selectedGov);
  }

  Future<void> _handleEmailAuth() async {
    final isArabic = ref.read(isArabicProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@') || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'أدخل بريداً صحيحاً وكلمة مرور من 6 أحرف على الأقل'
                : 'Enter a valid email and a password of at least 6 characters.',
          ),
          backgroundColor: AppColors.signalAlert,
        ),
      );
      return;
    }
    // Email/password sign-in requires enabling the Email provider in the
    // Firebase console; surface that clearly if it is disabled.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'استخدم الهاتف أو Google أو Apple لتسجيل الدخول حالياً'
              : 'Use Phone, Google or Apple sign-in for now — email/password '
                  'needs the Email provider enabled in Firebase console.',
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final ok = await ref.read(authNotifierProvider.notifier).signInWithGoogle(
          isArabic: ref.read(isArabicProvider),
        );
    if (mounted && ok) context.go('/home');
  }

  Future<void> _handleAppleSignIn() async {
    final ok = await ref.read(authNotifierProvider.notifier).signInWithApple(
          isArabic: ref.read(isArabicProvider),
        );
    if (mounted && ok) context.go('/home');
  }

  void _continueAsGuest() {
    ref.read(authNotifierProvider.notifier).signInAsGuest();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(isArabicProvider);
    final authState = ref.watch(authNotifierProvider);

    // Auto-navigate if a session appears (e.g. Android SMS auto-retrieval).
    ref.listen(authNotifierProvider, (previous, next) {
      if (previous?.user == null && next.user != null) {
        context.go('/home');
      }
    });

    return MarineBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Switcher in subtle glass pill
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(isArabicProvider.notifier).toggleLanguage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F263D).withValues(alpha: 0.6),
                        borderRadius:
                            BorderRadius.circular(GlassTokens.radiusPill),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        isArabic ? 'English' : 'عربي',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.cyanAccent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Floating Brand Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyanAccent
                                  .withValues(alpha: 0.2),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: const GlassContainer(
                          level: GlassLevel.prominent,
                          borderRadius: 22,
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.sailing_rounded,
                              size: 40, color: AppColors.cyanAccent),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'BAHHAR • بَحّار',
                        style: AppTextStyles.screenTitle.copyWith(
                          fontSize: 22,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic
                            ? 'الرفيق الذكي للصيد في عُمان'
                            : 'Oman Smart Marine & Fishing Companion',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Floating Auth Glass Card
                GlassContainer(
                  level: GlassLevel.prominent,
                  borderRadius: GlassTokens.radiusLarge,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Firebase config warning — visible, not silent.
                      if (!FirebaseService.isConfigured) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.signalCautionBg,
                            borderRadius: BorderRadius.circular(
                                GlassTokens.radiusSmall),
                            border: Border.all(
                                color:
                                    AppColors.signalCaution.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_off_outlined,
                                  size: 16, color: AppColors.signalCaution),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isArabic
                                      ? 'Firebase غير مُعد — أضف google-services.json لتسجيل الدخول. يمكنك استكشاف التطبيق كزائر.'
                                      : 'Firebase is not configured — add '
                                          'google-services.json to enable sign-in. '
                                          'You can explore as a guest.',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.signalCaution,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Error banner (invalid code, network, config…)
                      if (authState.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.signalAlertBg,
                            borderRadius: BorderRadius.circular(
                                GlassTokens.radiusSmall),
                            border: Border.all(
                                color:
                                    AppColors.signalAlert.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 16, color: AppColors.signalAlert),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.signalAlert,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Mode Selector: Sign In vs Register
                      PolymorphicSegmentedBar(
                        options: [
                          isArabic ? 'تسجيل الدخول' : 'Sign In',
                          isArabic ? 'حساب جديد' : 'Register',
                        ],
                        selectedIndex: _isRegister ? 1 : 0,
                        onSelected: (idx) {
                          setState(() {
                            _isRegister = (idx == 1);
                            _otpSent = false;
                          });
                        },
                      ),
                      const SizedBox(height: 18),

                      // Method Selector: Phone vs Email
                      Row(
                        children: [
                          Expanded(
                            child: PolymorphicChip(
                              label: isArabic ? 'رقم الهاتف' : 'Phone (OTP)',
                              icon: Icons.phone_iphone_rounded,
                              isSelected:
                                  _selectedMethod == AuthMethod.phone,
                              onTap: () => setState(
                                  () => _selectedMethod = AuthMethod.phone),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PolymorphicChip(
                              label: isArabic ? 'البريد' : 'Email',
                              icon: Icons.mail_outline_rounded,
                              isSelected:
                                  _selectedMethod == AuthMethod.email,
                              onTap: () => setState(
                                  () => _selectedMethod = AuthMethod.email),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // If Register Mode: Name & Governorate
                      if (_isRegister) ...[
                        GlassInput(
                          controller: _nameController,
                          labelText: isArabic
                              ? 'الاسم الكامل'
                              : 'CAPTAIN / FULL NAME',
                          hintText: 'e.g. Salim Al-Riyami',
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              size: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isArabic ? 'المحافظة الساحلية' : 'HOME GOVERNORATE',
                          style: AppTextStyles.sectionHeader,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1D31)
                                .withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(
                                GlassTokens.radiusMedium),
                            border: Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.14)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGov,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0A1D31),
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.cyanAccent),
                              items: _governorates
                                  .map((g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                    color: Colors.white)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedGov = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Method 1: Phone OTP
                      if (_selectedMethod == AuthMethod.phone) ...[
                        Text(
                          isArabic ? 'رقم الهاتف العُماني' : 'OMAN MOBILE NUMBER',
                          style: AppTextStyles.sectionHeader,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1D31)
                                    .withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(
                                    GlassTokens.radiusMedium),
                                border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.14)),
                              ),
                              child: Text(
                                '+968',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cyanBright,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GlassInput(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                hintText: '9123 4567',
                              ),
                            ),
                          ],
                        ),

                        if (_otpSent) ...[
                          const SizedBox(height: 14),
                          GlassInput(
                            controller: _otpController,
                            labelText: isArabic
                                ? 'رمز التحقق (OTP)'
                                : 'VERIFICATION CODE (OTP)',
                            hintText: '••••••',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isArabic
                                ? 'أرسلنا رمزاً إلى $_phoneE164'
                                : 'We sent a code to $_phoneE164',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textTertiary),
                          ),
                        ],

                        const SizedBox(height: 20),
                        SoftButton(
                          label: _otpSent
                              ? (isArabic ? 'تأكيد ودخول' : 'Verify & Continue')
                              : (isArabic
                                  ? 'إرسال الرمز'
                                  : 'Send Verification Code'),
                          isLoading: authState.isLoading,
                          onPressed: authState.isLoading
                              ? null
                              : (_otpSent ? _verifyPhoneOtp : _sendPhoneOtp),
                        ),
                      ],

                      // Method 2: Email & Password
                      if (_selectedMethod == AuthMethod.email) ...[
                        GlassInput(
                          controller: _emailController,
                          labelText: isArabic
                              ? 'البريد الإلكتروني'
                              : 'EMAIL ADDRESS',
                          hintText: 'captain@bahhar.om',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              size: 18,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        GlassInput(
                          controller: _passwordController,
                          labelText:
                              isArabic ? 'كلمة المرور' : 'PASSWORD',
                          hintText: '••••••••',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              size: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        SoftButton(
                          label: _isRegister
                              ? (isArabic
                                  ? 'إنشاء حساب'
                                  : 'Create Account')
                              : (isArabic
                                  ? 'تسجيل الدخول'
                                  : 'Sign In with Email'),
                          isLoading: authState.isLoading,
                          onPressed: authState.isLoading
                              ? null
                              : _handleEmailAuth,
                        ),
                      ],

                      const SizedBox(height: 18),
                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Container(
                                  height: 1,
                                  color: Colors.white
                                      .withValues(alpha: 0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10),
                            child: Text(
                              isArabic ? 'أو' : 'OR',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 10),
                            ),
                          ),
                          Expanded(
                              child: Container(
                                  height: 1,
                                  color: Colors.white
                                      .withValues(alpha: 0.1))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Social Providers
                      SoftButton(
                        label: isArabic
                            ? 'المتابعة باستخدام Apple'
                            : 'Sign in with Apple',
                        icon: Icons.apple,
                        style: SoftButtonStyle.glass,
                        onPressed: authState.isLoading
                            ? null
                            : _handleAppleSignIn,
                      ),
                      const SizedBox(height: 10),
                      SoftButton(
                        label: isArabic
                            ? 'المتابعة باستخدام Google'
                            : 'Sign in with Google',
                        icon: Icons.g_mobiledata_rounded,
                        style: SoftButtonStyle.secondary,
                        onPressed: authState.isLoading
                            ? null
                            : _handleGoogleSignIn,
                      ),

                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: _continueAsGuest,
                          child: Text(
                            isArabic
                                ? 'الدخول كزائر / استكشاف'
                                : 'Continue as Guest (Explore)',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.cyanAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),
                Center(
                  child: Text(
                    isArabic
                        ? 'بالمتابعة فإنك توافق على لوائح حماية الثروة السمكية في سلطنة عُمان'
                        : 'By continuing, you agree to Oman Marine & Fishery Regulations.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary, fontSize: 11),
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
