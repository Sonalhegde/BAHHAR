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
import '../../../../shared/animations/app_animations.dart';

/// Real Firebase-backed login/register screen: email/password, Google Sign-In and
/// Sign in with Apple. Loading, error and invalid-credential states are surfaced in
/// the UI — auth failures are never silent.
///
/// Phone OTP is not offered here. It has needed the Blaze (billing) plan since
/// September 2024 and this project carries no card; the flow stays implemented in
/// auth_repository.dart and phone_otp_widget.dart, dormant, so enabling it later is
/// a UI change rather than a rewrite.
class LoginRegisterScreen extends ConsumerStatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  ConsumerState<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends ConsumerState<LoginRegisterScreen> {
  bool _isRegister = false;
  String _selectedGov = 'Muscat';

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
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
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

  /// Email/password sign-in, and account creation while in register mode.
  ///
  /// This used to be a stub: it validated the fields and then apologised that the
  /// Email provider was not enabled, leaving a full email/password form on screen
  /// whose buttons did nothing. It calls real FirebaseAuth now. If the provider is
  /// still switched off in the console, `operation-not-allowed` comes back through
  /// [AuthNotifier] as an error banner naming that switch.
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
    final notifier = ref.read(authNotifierProvider.notifier);
    final ok = _isRegister
        ? await notifier.registerWithEmail(
            email: email,
            password: password,
            isArabic: isArabic,
          )
        : await notifier.signInWithEmail(
            email: email,
            password: password,
            isArabic: isArabic,
          );
    if (!mounted || !ok) return;
    await _completeRegistrationDetails();
    if (!mounted) return;
    context.go('/home');
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
          child: SlideFadeReveal(
            delay: const Duration(milliseconds: 80),
            duration: const Duration(milliseconds: 700),
            offsetY: 28,
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
                          });
                        },
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

                      // Email and password — the credential sign-in this build offers.
                      // Phone OTP is not on screen: see the class doc for why.
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
                        labelText: isArabic ? 'كلمة المرور' : 'PASSWORD',
                        hintText: '••••••••',
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            size: 18, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      SoftButton(
                        label: _isRegister
                            ? (isArabic ? 'إنشاء حساب' : 'Create Account')
                            : (isArabic
                                ? 'تسجيل الدخول'
                                : 'Sign In with Email'),
                        isLoading: authState.isLoading,
                        onPressed: authState.isLoading
                            ? null
                            : _handleEmailAuth,
                      ),

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
      ),
    );
  }
}
