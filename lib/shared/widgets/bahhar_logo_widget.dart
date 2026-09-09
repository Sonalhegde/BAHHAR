import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BahharLogoWidget extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showSubtitle;

  const BahharLogoWidget({
    super.key,
    this.size = 48,
    this.color,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppColors.accentNavy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: logoColor,
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.sailing_outlined, size: size * 0.5, color: Colors.white),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 6),
          Text(
            'بحّار',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
