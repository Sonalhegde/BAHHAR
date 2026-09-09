import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../shared/glass/marine_background.dart';
import '../../../../shared/glass/glass_container.dart';
import '../../../../shared/polymorphic/soft_button.dart';
import '../../../../shared/polymorphic/soft_toggle.dart';
import '../../../../shared/polymorphic/glass_input.dart';

enum AuthMethod { phone, email }

class LoginRegisterScreen extends ConsumerStatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  ConsumerState<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends ConsumerState<LoginRegisterScreen> {
  AuthMethod _selectedMethod = AuthMethod.phone;
  bool _isRegister = false;
  bool _otpSent = false;
  bool _isLoading = false;
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

  void _sendPhoneOtp() async {
    if (_phoneController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
  }

  void _verifyPhoneOtp() async {
    if (_otpController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ref.read(authNotifierProvider.notifier).mockSignIn(
      phone: '+968 ${_phoneController.text.trim()}',
      governorate: _selectedGov,
    );
    context.go('/home');
  }

  void _handleEmailAuth() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ref.read(authNotifierProvider.notifier).mockSignIn(
      phone: email,
      governorate: _selectedGov,
    );
    context.go('/home');
  }

  void _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    ref.read(authNotifierProvider.notifier).mockSignIn(
      phone: 'apple.user@icloud.com',
      governorate: _selectedGov,
    );
    context.go('/home');
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    ref.read(authNotifierProvider.notifier).mockSignIn(
      phone: 'google.user@gmail.com',
      governorate: _selectedGov,
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(isArabicProvider);

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
                    onTap: () => ref.read(isArabicProvider.notifier).toggleLanguage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F263D).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        isArabic ? 'English' : 'عربي',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.cyanAccent),
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
                              color: AppColors.cyanAccent.withValues(alpha: 0.2),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: GlassContainer(
                          level: GlassLevel.prominent,
                          borderRadius: 22,
                          padding: const EdgeInsets.all(16),
                          child: const Icon(Icons.sailing_rounded, size: 40, color: AppColors.cyanAccent),
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
                        isArabic ? 'الرفيق الذكي للصيد في عُمان' : 'Oman Smart Marine & Fishing Companion',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
                              isSelected: _selectedMethod == AuthMethod.phone,
                              onTap: () => setState(() => _selectedMethod = AuthMethod.phone),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PolymorphicChip(
                              label: isArabic ? 'البريد' : 'Email',
                              icon: Icons.mail_outline_rounded,
                              isSelected: _selectedMethod == AuthMethod.email,
                              onTap: () => setState(() => _selectedMethod = AuthMethod.email),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // If Register Mode: Name & Governorate
                      if (_isRegister) ...[
                        GlassInput(
                          controller: _nameController,
                          labelText: isArabic ? 'الاسم الكامل' : 'CAPTAIN / FULL NAME',
                          hintText: 'e.g. Salim Al-Riyami',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          isArabic ? 'المحافظة الساحلية' : 'HOME GOVERNORATE',
                          style: AppTextStyles.sectionHeader,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1D31).withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGov,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0A1D31),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanAccent),
                              items: _governorates.map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedGov = val);
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1D31).withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
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
                            labelText: isArabic ? 'رمز التحقق (OTP)' : 'VERIFICATION CODE (OTP)',
                            hintText: '••••••',
                            keyboardType: TextInputType.number,
                          ),
                        ],

                        const SizedBox(height: 20),
                        SoftButton(
                          label: _otpSent
                              ? (isArabic ? 'تأكيد ودخول' : 'Verify & Continue')
                              : (isArabic ? 'إرسال الرمز' : 'Send Verification Code'),
                          isLoading: _isLoading,
                          onPressed: _otpSent ? _verifyPhoneOtp : _sendPhoneOtp,
                        ),
                      ],

                      // Method 2: Email & Password
                      if (_selectedMethod == AuthMethod.email) ...[
                        GlassInput(
                          controller: _emailController,
                          labelText: isArabic ? 'البريد الإلكتروني' : 'EMAIL ADDRESS',
                          hintText: 'captain@bahhar.om',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        GlassInput(
                          controller: _passwordController,
                          labelText: isArabic ? 'كلمة المرور' : 'PASSWORD',
                          hintText: '••••••••',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        SoftButton(
                          label: _isRegister
                              ? (isArabic ? 'إنشاء حساب' : 'Create Account')
                              : (isArabic ? 'تسجيل الدخول' : 'Sign In with Email'),
                          isLoading: _isLoading,
                          onPressed: _handleEmailAuth,
                        ),
                      ],

                      const SizedBox(height: 18),
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              isArabic ? 'أو' : 'OR',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontSize: 10),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Social Providers
                      SoftButton(
                        label: isArabic ? 'المتابعة باستخدام Apple' : 'Sign in with Apple',
                        icon: Icons.apple,
                        style: SoftButtonStyle.glass,
                        onPressed: _handleAppleSignIn,
                      ),
                      const SizedBox(height: 10),

                      SoftButton(
                        label: isArabic ? 'المتابعة باستخدام Google' : 'Sign in with Google',
                        icon: Icons.g_mobiledata_rounded,
                        style: SoftButtonStyle.secondary,
                        onPressed: _handleGoogleSignIn,
                      ),

                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            ref.read(authNotifierProvider.notifier).mockSignIn();
                            context.go('/home');
                          },
                          child: Text(
                            isArabic ? 'الدخول كزائر / استكشاف' : 'Continue as Guest (Explore)',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.cyanAccent),
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
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontSize: 11),
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
