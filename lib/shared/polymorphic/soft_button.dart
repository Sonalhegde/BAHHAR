import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/glass_tokens.dart';

enum SoftButtonStyle {
  primary,
  glass,
  secondary,
  danger,
}

class SoftButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SoftButtonStyle style;
  final bool isLoading;
  final double height;
  final double? width;

  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = SoftButtonStyle.primary,
    this.isLoading = false,
    this.height = 52.0,
    this.width = double.infinity,
  });

  @override
  State<SoftButton> createState() => _SoftButtonState();
}

class _SoftButtonState extends State<SoftButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color bg;
    Color textColor = Colors.white;
    List<BoxShadow> shadows;
    Border? border;

    switch (widget.style) {
      case SoftButtonStyle.primary:
        bg = isDisabled ? const Color(0xFF93C5FD) : AppColors.primaryBlue;
        border = Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.0);
        shadows = _isPressed
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.25),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.38),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ];
        break;

      case SoftButtonStyle.glass:
        bg = Colors.white.withValues(alpha: 0.85);
        border = Border.all(color: const Color(0xFFBFDBFE), width: 1.0);
        textColor = AppColors.oceanNavy;
        shadows = _isPressed
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ];
        break;

      case SoftButtonStyle.secondary:
        bg = AppColors.primaryBlueLight;
        border = Border.all(color: const Color(0xFFD6E6F7), width: 1.0);
        textColor = AppColors.primaryBlue;
        shadows = [];
        break;

      case SoftButtonStyle.danger:
        bg = AppColors.signalAlert.withValues(alpha: 0.12);
        border = Border.all(color: AppColors.signalAlert.withValues(alpha: 0.35), width: 1.0);
        textColor = AppColors.signalAlert;
        shadows = [];
        break;
    }

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
            border: border,
            boxShadow: shadows,
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (widget.icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(widget.icon, size: 18, color: textColor),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
