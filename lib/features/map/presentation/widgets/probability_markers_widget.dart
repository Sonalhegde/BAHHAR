import 'package:flutter/material.dart';

import 'package:bahhar/core/models/hotspot_model.dart';
import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/shared/widgets/legal_status_badge.dart' show LegalStatus;

/// Coloured hotspot markers reflecting ML strike probability.
///
/// A declarative overlay layer that mirrors the imperative circle drawing in
/// [FishingMapScreen]: each hotspot becomes a disc whose fill colour encodes
/// its 0–100 strike probability via [AppColors.getProbabilityColor] (green =
/// optimal bite, amber = moderate, red = low) and whose radius grows with that
/// probability. Protected / restricted spots are forced to the reserve purple
/// so an illegal anchor is never mistaken for a productive one.
///
/// The layer is projection-agnostic: the host supplies [project] to map a
/// hotspot to a pixel offset in the overlay's coordinate space (e.g. from the
/// MapLibre controller's `toScreenLocation`). Tapping a marker reports the
/// hotspot through [onMarkerTap].
class ProbabilityMarkersWidget extends StatelessWidget {
  const ProbabilityMarkersWidget({
    super.key,
    required this.hotspots,
    required this.project,
    this.onMarkerTap,
    this.baseRadius = 10,
    this.showLabels = true,
  });

  /// Hotspots to draw (already filtered by the caller).
  final List<HotspotModel> hotspots;

  /// Maps a hotspot to an offset within this widget's box.
  final Offset Function(HotspotModel hotspot) project;

  /// Invoked when a marker is tapped.
  final ValueChanged<HotspotModel>? onMarkerTap;

  /// Radius (px) of a 0-probability marker; scales up to 2× at probability 100.
  final double baseRadius;

  /// Whether to print the numeric probability inside each marker.
  final bool showLabels;

  /// Colour used for a given hotspot (protected areas override the score band).
  static Color colorFor(HotspotModel hotspot) =>
      hotspot.legalStatus != LegalStatus.permitted
          ? AppColors.legalRestricted
          : AppColors.getProbabilityColor(hotspot.probability);

  /// Diameter (px) used for a given hotspot's marker.
  double diameterFor(HotspotModel hotspot) =>
      (baseRadius * 2) * (1 + hotspot.probability / 100).clamp(1.0, 2.0);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [for (final h in hotspots) _buildMarker(h)],
    );
  }

  Widget _buildMarker(HotspotModel h) {
    final offset = project(h);
    final color = colorFor(h);
    final d = diameterFor(h);
    return Positioned(
      left: offset.dx - d / 2,
      top: offset.dy - d / 2,
      child: GestureDetector(
        onTap: onMarkerTap == null ? null : () => onMarkerTap!(h),
        behavior: HitTestBehavior.opaque,
        child: Container(
          key: Key('probability_marker_${h.id}'),
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.92),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8),
            ],
          ),
          alignment: Alignment.center,
          child: showLabels
              ? Text(
                  '${h.probability}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    height: 1.0,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
