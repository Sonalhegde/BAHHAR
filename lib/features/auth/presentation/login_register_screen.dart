import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../shared/widgets/bahhar_logo_widget.dart';
import '../../../../shared/widgets/custom_buttons.dart';

class LoginRegisterScreen extends ConsumerStatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  ConsumerState<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends ConsumerState<LoginRegisterScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isRegister = false;
  bool _otpSent = false;
  bool _isLoading = false;
  String _selectedGov = 'Muscat';

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
    super.dispose();
  }

  void _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
  }

  void _verifyAndProceed() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ref.read(authNotifierProvider.notifier).mockSignIn(
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '+968 9123 4567',
      governorate: _selectedGov,
    );
    context.go('/home');
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const BahharLogoWidget(size: 64, showSubtitle: false),
                        const SizedBox(height: 16),
                        Text(
                          isArabic ? 'بَحّار' : 'BAHHAR',
                          style: AppTextStyles.screenTitle.copyWith(letterSpacing: 2.0),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isArabic ? 'الرفيق الذكي للصيد في عُمان' : 'Oman Smart Marine & Fishing Companion',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Mode Toggle
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                  const SizedBox(height: 28),

                  if (_isRegister) ...[
                    Text(
                      isArabic ? 'المحافظة الساحلية الرئيسية' : 'HOME GOVERNORATE',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 20),
                  ],

                  Text(
                    isArabic ? 'رقم الهاتف العُماني' : 'OMAN MOBILE NUMBER',
                    style: AppTextStyles.sectionHeader,
                  ),
                  const SizedBox(height: 8),
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
                    const SizedBox(height: 20),
                    Text(
                      isArabic ? 'رمز التحقق (OTP)' : 'VERIFICATION CODE (OTP)',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 8),
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

                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _otpSent
                        ? (isArabic ? 'تأكيد ودخول' : 'Verify & Continue')
                        : (isArabic ? 'إرسال الرمز' : 'Send Verification Code'),
                    isLoading: _isLoading,
                    onPressed: _otpSent ? _verifyAndProceed : _sendOtp,
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: SecondaryButton(
                      label: isArabic ? 'دخول كزائر / استكشاف' : 'Explore as Guest',
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).mockSignIn();
                        context.go('/home');
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
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
}\n