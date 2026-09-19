import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../animations/app_animations.dart';

/// Loading skeleton with a soft shimmer sweep travelling across the block.
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonBox({super.key, required this.height, this.width, this.borderRadius});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
        ..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(8);

    final block = Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: radius,
      ),
    );

    if (reduceMotionOf(context) || !TickerMode.of(context)) return block;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shimmer,
        child: block,
        builder: (context, child) {
          // Sweep highlight from off-left to off-right, with a soft pause.
          final t = Curves.easeInOut.transform(_shimmer.value);
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(-2.2 + 3.4 * t, -0.3),
              end: Alignment(-1.2 + 3.4 * t, 0.3),
              colors: const [
                AppColors.skeletonBase,
                AppColors.skeletonHighlight,
                AppColors.skeletonBase,
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds),
            child: child,
          );
        },
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
