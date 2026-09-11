import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Simple loading skeleton. Part 3 replaces the flat grey with a shimmer
/// sweep; the shape API stays identical.
class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonBox({super.key, required this.height, this.width, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Skeleton matching HotspotCard's shape: score square + two text lines +
/// species chip row. [height] is a soft hint kept for API symmetry.
class SkeletonCard extends StatelessWidget {
  final double? height;
  const SkeletonCard({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            height: 46,
            width: 46,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 15, width: 180),
                SizedBox(height: 8),
                SkeletonBox(height: 11, width: 230),
                SizedBox(height: 10),
                Row(
                  children: [
                    SkeletonBox(height: 20, width: 72),
                    SizedBox(width: 6),
                    SkeletonBox(height: 20, width: 72),
                    SizedBox(width: 6),
                    SkeletonBox(height: 20, width: 72),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
