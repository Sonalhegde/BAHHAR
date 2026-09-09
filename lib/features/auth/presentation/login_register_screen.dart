import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../shared/widgets/bahhar_logo_widget.dart';
import '../../../../shared/widgets/custom_buttons.dart';

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

  // Controllers
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
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your Oman phone number');
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
  }

  void _verifyPhoneOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showError('Please enter the 6-digit verification code');
      return;
    }
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
    final pass = _passwordController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }
    if (pass.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.signalAlert,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(isArabicProvider);

    return Scaffold(
      backgroundColor: AppColors.surfacePure,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePure,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(isArabicProvider.notifier).toggleLanguage();
            },
            child: Text(
              isArabic ? 'English' : 'عربي',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.accentNavy),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introductory Logo & Brand Header
                  Center(
                    child: Column(
                      children: [
                        const BahharLogoWidget(
                          size: 72,
                          showWordmark: true,
                          showSubtitle: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Mode Toggle: Sign In vs Register
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderHairline),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() { _isRegister = false; _otpSent = false; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: !_isRegister ? AppColors.surfacePure : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: !_isRegister ? Border.all(color: AppColors.borderHairline) : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isArabic ? 'تسجيل الدخول' : 'Sign In',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: !_isRegister ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: !_isRegister ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() { _isRegister = true; _otpSent = false; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _isRegister ? AppColors.surfacePure : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: _isRegister ? Border.all(color: AppColors.borderHairline) : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isArabic ? 'حساب جديد' : 'Register',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: _isRegister ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: _isRegister ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Method Switcher: Phone vs Email
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() { _selectedMethod = AuthMethod.phone; _otpSent = false; }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedMethod == AuthMethod.phone ? AppColors.accentNavy : AppColors.borderHairline,
                                  width: _selectedMethod == AuthMethod.phone ? 2.0 : 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_iphone_rounded,
                                  size: 16,
                                  color: _selectedMethod == AuthMethod.phone ? AppColors.accentNavy : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isArabic ? 'رقم الهاتف' : 'Phone Number',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: _selectedMethod == AuthMethod.phone ? AppColors.accentNavy : AppColors.textSecondary,
                                    fontWeight: _selectedMethod == AuthMethod.phone ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedMethod = AuthMethod.email),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedMethod == AuthMethod.email ? AppColors.accentNavy : AppColors.borderHairline,
                                  width: _selectedMethod == AuthMethod.email ? 2.0 : 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mail_outline_rounded,
                                  size: 16,
                                  color: _selectedMethod == AuthMethod.email ? AppColors.accentNavy : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isArabic ? 'البريد الإلكتروني' : 'Email',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: _selectedMethod == AuthMethod.email ? AppColors.accentNavy : AppColors.textSecondary,
                                    fontWeight: _selectedMethod == AuthMethod.email ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Registration Full Name (If register mode)
                  if (_isRegister) ...[
                    Text(
                      isArabic ? 'الاسم الكامل' : 'CAPTAIN / FULL NAME',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: isArabic ? 'مثال: سالم الريامي' : 'e.g. Salim Al-Riyami',
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      isArabic ? 'المحافظة الساحلية الرئيسية' : 'HOME GOVERNORATE',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfacePure,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderHairline),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGov,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary),
                          items: _governorates.map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g, style: AppTextStyles.bodyMedium),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGov = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // METHOD 1: PHONE NUMBER + OTP
                  if (_selectedMethod == AuthMethod.phone) ...[
                    Text(
                      isArabic ? 'رقم الهاتف العُماني' : 'OMAN MOBILE NUMBER',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          width: 76,
                          child: Text('+968', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        hintText: '9123 4567',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      ),
                    ),

                    if (_otpSent) ...[
                      const SizedBox(height: 16),
                      Text(
                        isArabic ? 'رمز التحقق (OTP)' : 'VERIFICATION CODE (OTP)',
                        style: AppTextStyles.sectionHeader,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subhead.copyWith(letterSpacing: 8),
                        decoration: const InputDecoration(
                          hintText: '••••••',
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _otpSent
                          ? (isArabic ? 'تأكيد ودخول' : 'Verify & Continue')
                          : (isArabic ? 'إرسال رمز التحقق' : 'Send Verification Code'),
                      isLoading: _isLoading,
                      onPressed: _otpSent ? _verifyPhoneOtp : _sendPhoneOtp,
                    ),
                  ],

                  // METHOD 2: EMAIL & PASSWORD
                  if (_selectedMethod == AuthMethod.email) ...[
                    Text(
                      isArabic ? 'البريد الإلكتروني' : 'EMAIL ADDRESS',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                        hintText: isArabic ? 'captain@bahhar.om' : 'captain@bahhar.om',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      isArabic ? 'كلمة المرور' : 'PASSWORD',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
                        hintText: '••••••••',
                      ),
                    ),

                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _isRegister
                          ? (isArabic ? 'إنشاء حساب' : 'Create Account')
                          : (isArabic ? 'تسجيل الدخول' : 'Sign In with Email'),
                      isLoading: _isLoading,
                      onPressed: _handleEmailAuth,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Divider with "OR"
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.borderHairline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          isArabic ? 'أو' : 'OR',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontSize: 11),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.borderHairline)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // SOCIAL / NATIVE PROVIDERS: APPLE ID & GOOGLE
                  // Sign in with Apple (Mandatory for iOS with Social Auth)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _handleAppleSignIn,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.apple, size: 22, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            isArabic ? 'المتابعة باستخدام Apple' : 'Sign in with Apple',
                            style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sign in with Google
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfacePure,
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderHairline, width: 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google G Icon representation
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: const Text('G', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF4285F4))),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isArabic ? 'المتابعة باستخدام Google' : 'Sign in with Google',
                            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Continue as Guest / Explore
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).mockSignIn();
                        context.go('/home');
                      },
                      child: Text(
                        isArabic ? 'تصفح التطبيق كزائر' : 'Continue as Guest',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.accentNavy),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
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
      ),
    );
  }
}
