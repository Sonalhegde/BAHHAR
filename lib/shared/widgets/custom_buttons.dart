import 'package:flutter/material.dart';
import '../polymorphic/soft_button.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SoftButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      style: SoftButtonStyle.primary,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SoftButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      style: SoftButtonStyle.glass,
    );
  }
}

class BahharPrimaryButton extends PrimaryButton {
  const BahharPrimaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.isLoading,
    super.icon,
  });
}

class BahharSecondaryButton extends SecondaryButton {
  const BahharSecondaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
  });
}
