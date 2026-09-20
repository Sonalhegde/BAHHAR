import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bahhar/core/providers/auth_provider.dart';
import 'package:bahhar/core/providers/preferences_provider.dart';
import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/core/theme/app_text_styles.dart';
import 'package:bahhar/shared/polymorphic/soft_button.dart';

/// Google Sign-In button.
///
/// Presentation + trigger widget for the OAuth flow owned by
/// [AuthNotifier.signInWithGoogle]. Tapping starts the sign-in, disables the
/// button while it is in flight, surfaces any error inline and calls
/// [onSignedIn] on success so the host screen can navigate.
///
/// [onPressed] allows injecting a custom action (used by tests and by hosts
/// that drive authentication differently); when null the real provider flow
/// runs. The provider is read lazily on tap so building this widget never
/// initialises Firebase.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({
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
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
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
              .signInWithGoogle(isArabic: isArabic);
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
        (isArabic ? 'المتابعة باستخدام Google' : 'Sign in with Google');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SoftButton(
          key: const Key('google_sign_in_button'),
          label: label,
          icon: Icons.g_mobiledata_rounded,
          style: SoftButtonStyle.secondary,
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
