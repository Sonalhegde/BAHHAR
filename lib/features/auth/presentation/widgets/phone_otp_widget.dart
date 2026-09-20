import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bahhar/core/constants/app_constants.dart';
import 'package:bahhar/core/providers/auth_provider.dart';
import 'package:bahhar/core/providers/preferences_provider.dart';
import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/core/theme/app_text_styles.dart';
import 'package:bahhar/core/theme/glass_tokens.dart';
import 'package:bahhar/core/utils/validators.dart';
import 'package:bahhar/shared/polymorphic/glass_input.dart';
import 'package:bahhar/shared/polymorphic/soft_button.dart';

/// +968 phone-number entry and 6-digit OTP verification, as a self-contained
/// two-step control.
///
/// Step 1 collects an Omani mobile number (validated with
/// [Validators.validateOmanPhone]) and requests a code; step 2 collects the
/// 6-digit code and confirms it. The real flows run through
/// [AuthNotifier.sendOtp] / [AuthNotifier.verifyOtp]; [onSendOtp] and
/// [onVerifyOtp] let tests and non-standard hosts inject their own action.
/// The auth provider is read lazily on tap so this widget builds safely even
/// when Firebase is not configured.
class PhoneOtpWidget extends ConsumerStatefulWidget {
  const PhoneOtpWidget({
    super.key,
    this.onSendOtp,
    this.onVerifyOtp,
    this.onVerified,
    this.initialPhone = '',
  });

  /// Injected "send code" action. Returns true when the code was dispatched.
  final Future<bool> Function(String phoneE164)? onSendOtp;

  /// Injected "verify code" action. Returns true when the code was accepted.
  final Future<bool> Function(String code)? onVerifyOtp;

  /// Called after a successful verification (e.g. to navigate onward).
  final VoidCallback? onVerified;

  /// Pre-fills the national number (without the +968 prefix).
  final String initialPhone;

  @override
  ConsumerState<PhoneOtpWidget> createState() => _PhoneOtpWidgetState();
}

class _PhoneOtpWidgetState extends ConsumerState<PhoneOtpWidget> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _otp = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String? _phoneError;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _phone.text = widget.initialPhone;
  }

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');
  String get _phoneE164 => '${AppConstants.omanCountryCode}$_digits';

  bool get _phoneLooksValid =>
      _digits.length >= AppConstants.omanMobileMinLength &&
      Validators.validateOmanPhone(_phoneE164) == null;

  Future<void> _send() async {
    if (!_phoneLooksValid) {
      setState(() => _phoneError =
          ref.read(isArabicProvider) ? 'رقم غير صحيح' : 'Enter a valid Omani number.');
      return;
    }
    setState(() {
      _busy = true;
      _phoneError = null;
    });
    final isArabic = ref.read(isArabicProvider);
    bool sent = false;
    try {
      if (widget.onSendOtp != null) {
        sent = await widget.onSendOtp!(_phoneE164);
      } else {
        await ref
            .read(authNotifierProvider.notifier)
            .sendOtp(phoneE164: _phoneE164, isArabic: isArabic);
        sent = ref.read(authNotifierProvider).error == null;
      }
    } catch (e) {
      sent = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeSent = sent;
      if (!sent) {
        _phoneError = isArabic
            ? 'تعذر إرسال الرمز، حاول مجدداً'
            : 'Could not send the code. Please retry.';
      }
    });
  }

  Future<void> _verify() async {
    final code = _otp.text.trim();
    if (code.length < AppConstants.otpLength) {
      setState(() => _otpError = ref.read(isArabicProvider)
          ? 'أدخل الرمز المكوّن من ٦ أرقام'
          : 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _otpError = null;
    });
    final isArabic = ref.read(isArabicProvider);
    bool ok = false;
    try {
      ok = widget.onVerifyOtp != null
          ? await widget.onVerifyOtp!(code)
          : await ref
              .read(authNotifierProvider.notifier)
              .verifyOtp(code, isArabic: isArabic);
    } catch (e) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) {
        _otpError = isArabic
            ? 'رمز التحقق غير صحيح'
            : 'Invalid verification code.';
      }
    });
    if (ok) widget.onVerified?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(isArabicProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step 1 — phone number with the fixed +968 country-code chip.
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
                AppConstants.omanCountryCode,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyanBright,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassInput(
                key: const Key('phone_input'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                hintText: '9123 4567',
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
              ),
            ),
          ],
        ),
        if (_phoneError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _phoneError!,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.signalAlert),
            ),
          ),

        // Step 2 — appears once a code has been dispatched.
        if (_codeSent) ...[
          const SizedBox(height: 14),
          GlassInput(
            key: const Key('otp_input'),
            controller: _otp,
            labelText:
                isArabic ? 'رمز التحقق (OTP)' : 'VERIFICATION CODE (OTP)',
            hintText: '••••••',
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_otpError != null) setState(() => _otpError = null);
            },
          ),
          const SizedBox(height: 6),
          Text(
            isArabic ? 'أرسلنا رمزاً إلى $_phoneE164' : 'We sent a code to $_phoneE164',
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
          if (_otpError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _otpError!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.signalAlert),
              ),
            ),
        ],

        const SizedBox(height: 20),
        SoftButton(
          key: const Key('phone_otp_action'),
          label: _codeSent
              ? (isArabic ? 'تأكيد ودخول' : 'Verify & Continue')
              : (isArabic ? 'إرسال الرمز' : 'Send Verification Code'),
          isLoading: _busy,
          onPressed: _busy ? null : (_codeSent ? _verify : _send),
        ),
      ],
    );
  }
}
