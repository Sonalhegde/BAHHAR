import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BahharLogoWidget extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showWordmark;
  final bool showSubtitle;
  final bool useAssetImage;

  const BahharLogoWidget({
    super.key,
    this.size = 64,
    this.color,
    this.showWordmark = true,
    this.showSubtitle = false,
    this.useAssetImage = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppColors.accentNavy;

    Widget iconBox;
    if (useAssetImage) {
      iconBox = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(color: AppColors.borderHairline, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/images/app_icon.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to stylized vector emblem
            return Container(
              color: logoColor,
              alignment: Alignment.center,
              child: Icon(Icons.sailing_outlined, size: size * 0.52, color: Colors.white),
            );
          },
        ),
      );
    } else {
      iconBox = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: logoColor,
          borderRadius: BorderRadius.circular(size * 0.22),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.sailing_outlined, size: size * 0.52, color: Colors.white),
      );
    }

    if (!showWordmark && !showSubtitle) {
      return iconBox;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconBox,
        if (showWordmark) ...[
          const SizedBox(height: 12),
          Text(
            'BAHHAR',
            style: AppTextStyles.screenTitle.copyWith(
              fontSize: size * 0.32,
              letterSpacing: 3.0,
              fontWeight: FontWeight.w700,
              color: AppColors.accentNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'بَحّار',
            style: TextStyle(
              fontSize: size * 0.26,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'sans-serif',
            ),
          ),
        ],
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            'Oman Smart Marine Companion',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
