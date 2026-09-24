import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../core/providers/flow_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/services/geofence_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/models/flow_field.dart';
import '../../../core/models/hotspot_model.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/polymorphic/soft_button.dart';
import '../../../shared/widgets/legal_status_badge.dart';
import 'widgets/flow_overlay_widget.dart';
import 'widgets/layer_toggles_widget.dart';
import 'widgets/species_filter_chips.dart';

/// MapLibre fishing chart rendering keyless OpenFreeMap "positron" tiles
/// (Master Build Prompt v3 Â§2/Â§3.5 â€” no Google Maps SDK, no API key).
/// Hotspots are drawn as circles colored by
/// AppColors.getProbabilityColor(hotspot.probability); the species chips
/// filter them through selectedSpeciesFilterProvider. Tapping a circle opens
/// the inspector card, whose button pushes the same Hotspot Details screen
/// used by the home list.
class FishingMapScreen extends ConsumerStatefulWidget {
  const FishingMapScreen({super.key});

  @override
  ConsumerState<FishingMapScreen> createState() => _FishingMapScreenState();
}

class _FishingMapScreenState extends ConsumerState<FishingMapScreen> {
  static const CameraPosition _muscatSeeb = CameraPosition(
    target: LatLng(23.6143, 58.5453), // Muscat/Seeb coastal waters
    zoom: 8.2,
  );

  /// OpenFreeMap "positron" â€” closest keyless preset to the Premium White
  /// direction (v3 Â§3.5). No API key, no billing.
  static const String _openFreeMapStyleUrl =
      'https://tiles.openfreemap.org/styles/positron';

  MapLibreMapController? _controller;
  bool _styleLoaded = false;
  HotspotModel? _selectedHotspot;

  /// True once the camera has been thrown to the user's resolved position this
  /// session, so a late GPS fix recentres exactly once and never yanks a map the
  /// fisherman has already started exploring.
  bool _didAutoCenter = false;

  /// Chart overlay layers, driven by the floating [LayerTogglesWidget].
  /// Wind streaks are on by default â€” the layer is the chart's headline
  /// feature; depth contours are omitted because no contour source exists.
  MapLayers _layers = const MapLayers(flow: FlowMode.wind);
  static const List<MapLayerKind> _screenKinds = [
    MapLayerKind.windFlow,
    MapLayerKind.currentFlow,
    MapLayerKind.hotspots,
    MapLayerKind.protectedAreas,
    MapLayerKind.myLocation,
  ];

  /// Tilt/rotation breaks the overlay's linear geoâ†’screen projection, so the
  /// flow layer hides itself until the camera is upright again.
  bool _cameraUpright = true;

  /// Latest filtered hotspots; (re)drawn as circles once the style is ready.
  List<HotspotModel> _current = const [];
  String _lastDrawnSignature = '';
  final Map<String, HotspotModel> _byGeoKey = {};

  @override
  void dispose() {
    _controller?.onCircleTapped.remove(_onCircleTapped);
    super.dispose();
  }

  void _onStyleLoaded() {
    _styleLoaded = true;
    _redrawCircles();
    _redrawReserves();
    _applyUserLocationIfNeeded();
  }

  /// Moves the camera to the fisherman's resolved position once the map is ready
  /// and a real (non-fallback) fix has arrived. The Muscat default is intentionally
  /// NOT auto-centred: with no fix the map simply stays where it opened.
  void _applyUserLocationIfNeeded() {
    if (_didAutoCenter) return;
    final controller = _controller;
    if (controller == null || !_styleLoaded) return;
    final loc = ref.read(locationProvider).asData?.value;
    if (loc == null || !loc.isReal) return;
    _didAutoCenter = true;
    controller
        .moveCamera(CameraUpdate.newLatLngZoom(LatLng(loc.latitude, loc.longitude), 9.5));
  }

  /// Recentres on the user's current position, re-resolving if permission was just
  /// granted. Powers the "recenter on me" control.
  Future<void> _recenterOnMe() async {
    final controller = _controller;
    if (controller == null) return;
    final loc = await ref.read(locationProvider.future);
    controller.moveCamera(
        CameraUpdate.newLatLngZoom(LatLng(loc.latitude, loc.longitude), 10.5));
    _didAutoCenter = true;
  }

  void _onCircleTapped(Circle circle) {
    final controller = _controller;
    if (controller == null) return;
    final pos = controller.getCircleLatLng(circle);
    final hotspot = _byGeoKey['${pos.latitude},${pos.longitude}'];
    if (hotspot != null) setState(() => _selectedHotspot = hotspot);
  }

  Future<void> _redrawCircles() async {
    final controller = _controller;
    if (controller == null || !_styleLoaded) return;

    final visible = _layers.hotspots ? _current : const <HotspotModel>[];
    final signature =
        '${_layers.hotspots ? 'h' : '-'}:${visible.map((h) => h.id).join('|')}';
    if (signature == _lastDrawnSignature) return;
    _lastDrawnSignature = signature;

    await controller.clearCircles();
    _byGeoKey.clear();
    if (visible.isEmpty) return;

    final options = <CircleOptions>[];
    for (final h in visible) {
      final color = h.legalStatus != LegalStatus.permitted
          ? AppColors.legalRestricted
          : AppColors.getProbabilityColor(h.probability);
      options.add(CircleOptions(
        geometry: LatLng(h.latitude, h.longitude),
        circleColor: _hex(color),
        circleRadius: 9,
        circleStrokeWidth: 2,
        circleStrokeColor: '#FFFFFF',
        circleOpacity: 0.95,
      ));
      _byGeoKey['${h.latitude},${h.longitude}'] = h;
    }
    await controller.addCircles(options);
  }

  String _hex(Color c) {
    final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  /// Protected zones from the same static geofence catalogue the safety
  /// checklist uses, drawn as translucent reserve discs (circle geometry is
  /// pixel-radius in this plugin, so a 48-gon in geo space stands in).
  Future<void> _redrawReserves() async {
    final controller = _controller;
    if (controller == null || !_styleLoaded) return;
    await controller.clearFills();
    if (!_layers.protectedAreas) return;
    for (final area in GeofenceService.omaniReserves) {
      final ring = <LatLng>[];
      final dLat = area.radiusKm / 111.32;
      final dLon =
          area.radiusKm / (111.32 * math.cos(area.centerLat * math.pi / 180));
      for (var i = 0; i <= 48; i++) {
        final a = 2 * math.pi * i / 48;
        ring.add(LatLng(
          area.centerLat + dLat * math.sin(a),
          area.centerLon + dLon * math.cos(a),
        ));
      }
      await controller.addFill(
        FillOptions(
          geometry: [ring],
          fillColor: _hex(AppColors.legalRestricted),
          fillOpacity: 0.10,
          fillOutlineColor: _hex(AppColors.legalRestricted),
        ),
      );
    }
  }

  void _onLayersChanged(MapLayers next) {
    final flowWasOff = _layers.flow == FlowMode.off;
    setState(() => _layers = next);
    _scheduleRedraw();
    _redrawReserves();
    if (next.flow != FlowMode.off && flowWasOff) {
      final field = ref.read(flowFieldProvider).asData?.value;
      if (field == null || field.isStale()) ref.invalidate(flowFieldProvider);
    }
    final controller = _controller;
    if (controller != null && _styleLoaded) {
      try {
        controller.updateMyLocationTrackingMode(next.myLocation
            ? MyLocationTrackingMode.tracking
            : MyLocationTrackingMode.none);
      } catch (_) {
        // Platform without tracking-mode support: the initial flag stands.
      }
    }
  }

  void _scheduleRedraw() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _redrawCircles());
  }

  void _clearSelection() {
    if (_selectedHotspot != null) {
      setState(() => _selectedHotspot = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotspotsAsync = ref.watch(filteredHotspotsProvider);
    final selectedSpecies = ref.watch(selectedSpeciesFilterProvider);
    final flowField = ref.watch(flowFieldProvider).asData?.value;
    final location = ref.watch(locationProvider);
    final loc = location.asData?.value;
    // A fix that lands after the tiles are already up still recentres, exactly once.
    ref.listen(locationProvider, (_, __) => _applyUserLocationIfNeeded());

    return Scaffold(
      backgroundColor: AppColors.mapWater,
      body: hotspotsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 36, color: AppColors.signalAlert),
                const SizedBox(height: 10),
                Text(
                  'Failed to load hotspots.\nCheck your connection.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(hotspotsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (hotspots) {
          _current = hotspots;
          _scheduleRedraw();

          return Stack(
            children: [
              // Live MapLibre map rendering keyless OpenFreeMap tiles.
              Positioned.fill(
                child: MapLibreMap(
                  styleString: _openFreeMapStyleUrl,
                  initialCameraPosition: _muscatSeeb,
                  compassEnabled: true,
                  myLocationEnabled: true,
                  onStyleLoadedCallback: _onStyleLoaded,
                  onMapCreated: (controller) {
                    _controller = controller;
                    controller.onCircleTapped.add(_onCircleTapped);
                  },
                  onCameraMove: (position) {
                    final upright = position.tilt.abs() < 0.5 &&
                        position.bearing.abs() < 0.5;
                    if (upright != _cameraUpright) {
                      setState(() => _cameraUpright = upright);
                    }
                  },
                  onMapClick: (point, coordinates) => _clearSelection(),
                ),
              ),

              // Nullschool-style wind/current streaks above the tiles.
              Positioned.fill(
                child: FlowOverlay(
                  key: const Key('flow_overlay'),
                  field: flowField,
                  mode: _layers.flow,
                  viewport: () => maplibreViewport(_controller,
                      upright: () => _cameraUpright),
                ),
              ),

              // Floating chart layer toggles (flow, hotspots, reserves, GPS).
              Positioned(
                right: 12,
                top: 120,
                child: LayerTogglesWidget(
                  layers: _layers,
                  kinds: _screenKinds,
                  compact: true,
                  onChanged: _onLayersChanged,
                ),
              ),

              // Floating Filter Controls (wired to the filter providers)
              const Positioned(
                top: 50,
                left: 16,
                right: 68,
                child: MapSpeciesFilterChips(),
              ),

              // Result count hint
              Positioned(
                top: 96,
                left: 16,
                child: GlassContainer(
                  level: GlassLevel.standard,
                  borderRadius: GlassTokens.radiusPill,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    '${hotspots.length} spots'
                    '${selectedSpecies != null ? ' â€¢ $selectedSpecies' : ''}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),

              // Flow speed key + provenance, under the layer toggles.
              if (_layers.flow != FlowMode.off)
                Positioned(
                  right: 12,
                  top: 330,
                  child: GlassContainer(
                    level: GlassLevel.standard,
                    borderRadius: GlassTokens.radiusMedium,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: _FlowLegend(mode: _layers.flow, field: flowField),
                  ),
                ),

              // Recenter-on-me control, wired to the same locationProvider the
              // weather/marine cards and the auto-centre already use.
              Positioned(
                right: 12,
                bottom: 40,
                child: GlassContainer(
                  level: GlassLevel.prominent,
                  borderRadius: GlassTokens.radiusPill,
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    key: const Key('recenter_button'),
                    onPressed: _recenterOnMe,
                    tooltip: loc == null || loc.isFallback
                        ? 'Center on my location'
                        : 'Back to my position',
                    icon: const Icon(Icons.my_location_rounded,
                        color: AppColors.primaryBlue),
                  ),
                ),
              ),

              // Honesty chip: the app never lets the Muscat default pass for a real
              // position. Shown only when we are actually on the fallback coordinate.
              if (loc != null && loc.isFallback)
                Positioned(
                  bottom: 44,
                  left: 16,
                  right: 76,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GlassContainer(
                      level: GlassLevel.standard,
                      borderRadius: GlassTokens.radiusPill,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_off_outlined,
                              size: 15, color: AppColors.signalCaution),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Showing Muscat â€” location unavailable',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Floating Selected Hotspot Inspector Card
              if (_selectedHotspot != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 96,
                  child: GlassContainer(
                    level: GlassLevel.prominent,
                    borderRadius: GlassTokens.radiusLarge,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedHotspot!.name,
                                      style: AppTextStyles.cardTitle
                                          .copyWith(fontSize: 16)),
                                  Text(
                                    '${_selectedHotspot!.nameAr} â€¢ ${_selectedHotspot!.region}',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            LegalStatusBadge(
                              isRestricted: _selectedHotspot!.legalStatus !=
                                  LegalStatus.permitted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatCol('DEPTH',
                                '${_selectedHotspot!.depthMeters} m'),
                            _buildStatCol('DISTANCE',
                                '${_selectedHotspot!.distanceNm} nmi'),
                            _buildStatCol('BITE SCORE',
                                '${_selectedHotspot!.probability}/100'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // One shared CTA definition (SoftButton) replaces the
                        // hand-tuned ElevatedButton.styleFrom block, so this button
                        // matches every other primary action in the app.
                        SoftButton(
                          label: 'Inspect & Plan Trip',
                          icon: Icons.explore_outlined,
                          style: SoftButtonStyle.primary,
                          onPressed: () => context
                              .push('/hotspots/${_selectedHotspot!.id}'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.sectionHeader.copyWith(fontSize: 9.5)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}

/// Speedâ†’colour key for the active flow layer, plus the honest provenance
/// line (live Open-Meteo grid vs. the offline replay) â€” the app twin of the
/// website sidebar's scale + note, kept tiny for a phone chart.
class _FlowLegend extends StatelessWidget {
  const _FlowLegend({required this.mode, required this.field});

  final FlowMode mode;
  final FlowField? field;

  @override
  Widget build(BuildContext context) {
    final stops = FlowColors.stopsFor(
        mode == FlowMode.current ? FlowMode.current : FlowMode.wind);
    final colors = stops
        .map((s) => FlowColors.forKt(
            mode == FlowMode.current ? FlowMode.current : FlowMode.wind,
            s[0].toDouble()))
        .toList();
    final hi = mode == FlowMode.current ? '4 kt' : '30+ kt';
    final source = field == null
        ? 'loading flowâ€¦'
        : 'Open-Meteo Â· ${field!.cached ? 'cached' : 'live'} Â· '
            '${field!.generatedAt.toLocal().formatHm()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 132,
          height: 7,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white70, width: 1),
          ),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('calm',
                  style: AppTextStyles.caption.copyWith(fontSize: 9)),
              const SizedBox(width: 5),
              Text(hi,
                  style: AppTextStyles.caption.copyWith(fontSize: 9)),
            ],
          ),
        ),
        Text(source,
            style: AppTextStyles.caption
                .copyWith(fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }
}

extension on DateTime {
  String formatHm() => '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}