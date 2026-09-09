import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/models/catch_model.dart';

class CatchListItem extends StatelessWidget {
  final CatchModel catchItem;
  final VoidCallback? onTap;

  const CatchListItem({super.key, required this.catchItem, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfacePure,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderHairline),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.set_meal_outlined, size: 20, color: AppColors.accentNavy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catchItem.species, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(
                    '${catchItem.weightKg.toStringAsFixed(1)} kg • ${catchItem.lengthCm.toStringAsFixed(0)} cm',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    catchItem.locationName,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (catchItem.released)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.signalGood.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Released',
                  style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.signalGood),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
