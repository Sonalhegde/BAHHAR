import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bahhar/core/providers/auth_provider.dart';
import 'package:bahhar/core/providers/preferences_provider.dart';
import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/core/theme/app_text_styles.dart';
import 'package:bahhar/shared/polymorphic/soft_button.dart';

/// Sign in with Apple button.
///
/// Mirrors [GoogleSignInButton]: drives [AuthNotifier.signInWithApple]
/// (ASAuthorizationController → OAuthProvider('apple.com') credential exchange
/// lives in AuthRepository), disables while in flight, shows errors inline and
/// calls [onSignedIn] on success. [onPressed] injects a custom action for
/// tests / non-standard hosts; the auth provider is only read on tap, so this
/// widget is safe to build on platforms without Firebase configured.
class AppleSignInButton extends ConsumerStatefulWidget {
  const AppleSignInButton({
    super.key,
    this.onPressed,
    this.onSignedIn,
    this.label,
    this.isLoading = false,
  });

  /// Optional override for the sign-in action. Returns whether it succeeded.
  final Future<bool> Function()? onPressed;

  /// Called after a successful sign-in (e.g. to navigate to Home).
  final VoidCallback? onSignedIn;

  /// Overrides the automatic bilingual label.
  final String? label;

  /// External loading flag, ORed with the in-flight state below.
  final bool isLoading;

  @override
  ConsumerState<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends ConsumerState<AppleSignInButton> {
  bool _busy = false;
  String? _error;

  Future<void> _handleTap() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final isArabic = ref.read(isArabicProvider);
    bool ok = false;
    try {
      ok = widget.onPressed != null
          ? await widget.onPressed!()
          : await ref
              .read(authNotifierProvider.notifier)
              .signInWithApple(isArabic: isArabic);
    } catch (e) {
      ok = false;
      if (mounted) setState(() => _error = '$e');
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onSignedIn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(isArabicProvider);
    final label = widget.label ??
        (isArabic ? 'المتابعة باستخدام Apple' : 'Sign in with Apple');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SoftButton(
          key: const Key('apple_sign_in_button'),
          label: label,
          icon: Icons.apple,
          style: SoftButtonStyle.glass,
          isLoading: _busy || widget.isLoading,
          onPressed: (_busy || widget.isLoading) ? null : _handleTap,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.signalAlert, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
