import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/glass_tokens.dart';

enum SoftButtonStyle {
  /// Primary filled oceanic button with subtle glow and tactile press
  primary,

  /// Frosted glass action button with translucent depth
  glass,

  /// Subtle secondary recessed button
  secondary,

  /// Dangerous / warning action button
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
    this.height = 50.0,
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
        bg = isDisabled ? const Color(0xFF1B3854) : AppColors.oceanNavy;
        border = Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4), width: 1.2);
        shadows = _isPressed
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.cyanAccent.withValues(alpha: 0.22),
                  offset: const Offset(0, 4),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  offset: const Offset(0, 6),
                  blurRadius: 12,
                ),
              ];
        break;

      case SoftButtonStyle.glass:
        bg = const Color(0xFF0F2C49).withValues(alpha: 0.55);
        border = Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.0);
        shadows = _isPressed
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ];
        break;

      case SoftButtonStyle.secondary:
        bg = Colors.transparent;
        border = Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0);
        textColor = AppColors.textSecondary;
        shadows = [];
        break;

      case SoftButtonStyle.danger:
        bg = AppColors.signalAlert.withValues(alpha: 0.16);
        border = Border.all(color: AppColors.signalAlert.withValues(alpha: 0.45), width: 1.0);
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
            borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
            border: border,
            boxShadow: shadows,
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyanAccent),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: textColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
