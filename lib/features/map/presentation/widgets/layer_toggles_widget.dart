import 'package:flutter/material.dart';

import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/core/theme/glass_tokens.dart';
import 'flow_overlay_widget.dart' show FlowMode;

/// The toggleable overlay layers of the nautical chart.
@immutable
class MapLayers {
  final bool hotspots;
  final bool protectedAreas;
  final bool myLocation;

  /// Which medium the particle-flow layer is drawing (none when [FlowMode.off]).
  final FlowMode flow;

  const MapLayers({
    this.hotspots = true,
    this.protectedAreas = true,
    this.myLocation = true,
    this.flow = FlowMode.off,
  });

  /// A layer set with nothing but location enabled.
  static const MapLayers minimal = MapLayers(
      hotspots: false, protectedAreas: false);

  MapLayers copyWith({
    bool? hotspots,
    bool? protectedAreas,
    bool? myLocation,
    FlowMode? flow,
  }) {
    return MapLayers(
      hotspots: hotspots ?? this.hotspots,
      protectedAreas: protectedAreas ?? this.protectedAreas,
      myLocation: myLocation ?? this.myLocation,
      flow: flow ?? this.flow,
    );
  }

  /// Flips a single layer, returning a new immutable set.
  MapLayers toggle(MapLayerKind kind) {
    switch (kind) {
      case MapLayerKind.hotspots:
        return copyWith(hotspots: !hotspots);
      case MapLayerKind.protectedAreas:
        return copyWith(protectedAreas: !protectedAreas);
      case MapLayerKind.myLocation:
        return copyWith(myLocation: !myLocation);
      case MapLayerKind.windFlow:
        // The flow layer is one medium at a time; wind replaces current/off.
        return copyWith(flow: flow == FlowMode.wind ? FlowMode.off : FlowMode.wind);
      case MapLayerKind.currentFlow:
        return copyWith(flow: flow == FlowMode.current ? FlowMode.off : FlowMode.current);
    }
  }

  bool isEnabled(MapLayerKind kind) {
    switch (kind) {
      case MapLayerKind.hotspots:
        return hotspots;
      case MapLayerKind.protectedAreas:
        return protectedAreas;
      case MapLayerKind.myLocation:
        return myLocation;
      case MapLayerKind.windFlow:
        return flow == FlowMode.wind;
      case MapLayerKind.currentFlow:
        return flow == FlowMode.current;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is MapLayers &&
      other.hotspots == hotspots &&
      other.protectedAreas == protectedAreas &&
      other.myLocation == myLocation &&
      other.flow == flow;

  @override
  int get hashCode =>
      Object.hash(hotspots, protectedAreas, myLocation, flow);
}

/// The individual map layers a toggle controls.
enum MapLayerKind {
  hotspots,
  protectedAreas,
  myLocation,
  windFlow,
  currentFlow,
}

/// Floating chart layer toggles.
///
/// A vertical glass pill of icon-buttons for the map's overlay layers. Fully
/// controlled: the host owns a [MapLayers] value and receives updates through
/// [onChanged], so this widget stays stateless, testable and reusable across
/// the map and the trip-planner previews. Every control is keyboard-focusable
/// and carries a bilingual tooltip + semantic label.
class LayerTogglesWidget extends StatelessWidget {
  const LayerTogglesWidget({
    super.key,
    required this.layers,
    required this.onChanged,
    this.isArabic = false,
    this.compact = false,
    this.kinds,
  });

  final MapLayers layers;
  final ValueChanged<MapLayers> onChanged;
  final bool isArabic;
  final bool compact;

  /// Which layers to show — hosts omit kinds their map cannot render.
  final List<MapLayerKind>? kinds;

  static const List<MapLayerKind> _kinds = MapLayerKind.values;

  IconData _icon(MapLayerKind kind) {
    switch (kind) {
      case MapLayerKind.hotspots:
        return Icons.pin_drop_rounded;
      case MapLayerKind.protectedAreas:
        return Icons.shield_outlined;
      case MapLayerKind.myLocation:
        return Icons.my_location_rounded;
      case MapLayerKind.windFlow:
        return Icons.air;
      case MapLayerKind.currentFlow:
        return Icons.water_rounded;
    }
  }

  String _label(MapLayerKind kind) {
    switch (kind) {
      case MapLayerKind.hotspots:
        return isArabic ? 'المواقع' : 'Hotspots';
      case MapLayerKind.protectedAreas:
        return isArabic ? 'المحميات' : 'Protected areas';
      case MapLayerKind.myLocation:
        return isArabic ? 'موقعي' : 'My location';
      case MapLayerKind.windFlow:
        return isArabic ? 'الرياح' : 'Wind flow';
      case MapLayerKind.currentFlow:
        return isArabic ? 'التيارات' : 'Current flow';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 6, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(GlassTokens.radiusLarge),
        border: Border.all(color: const Color(0xFFD6E6F7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in (kinds ?? _kinds))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _Toggle(
                key: Key('layer_toggle_${kind.name}'),
                icon: _icon(kind),
                tooltip: _label(kind),
                semanticLabel: _label(kind),
                selected: layers.isEnabled(kind),
                onPressed: () => onChanged(layers.toggle(kind)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.semanticLabel,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryBlue : AppColors.textSecondary;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: semanticLabel,
        toggled: selected,
        button: true,
        child: InkResponse(
          onTap: onPressed,
          radius: 22,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryBlueLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
