import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/models/hotspot_model.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/widgets/legal_status_badge.dart';

/// MapLibre fishing chart rendering keyless OpenFreeMap "positron" tiles
/// (Master Build Prompt v3 §2/§3.5 — no Google Maps SDK, no API key).
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

  /// OpenFreeMap "positron" — closest keyless preset to the Premium White
  /// direction (v3 §3.5). No API key, no billing.
  static const String _openFreeMapStyleUrl =
      'https://tiles.openfreemap.org/styles/positron';

  MapLibreMapController? _controller;
  bool _styleLoaded = false;
  HotspotModel? _selectedHotspot;

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

    final signature = _current.map((h) => h.id).join('|');
    if (signature == _lastDrawnSignature) return;
    _lastDrawnSignature = signature;

    await controller.clearCircles();
    _byGeoKey.clear();
    if (_current.isEmpty) return;

    final options = <CircleOptions>[];
    for (final h in _current) {
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
    final availableSpeciesAsync = ref.watch(availableSpeciesProvider);

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
                  onMapClick: (point, coordinates) => _clearSelection(),
                ),
              ),

              // Floating Filter Controls (wired to the filter providers)
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: availableSpeciesAsync.maybeWhen(
                    data: (species) => Row(
                      children: [
                        _FilterChip(
                          label: 'All Spots',
                          isSelected: selectedSpecies == null,
                          onTap: () => ref
                              .read(selectedSpeciesFilterProvider.notifier)
                              .state = null,
                        ),
                        const SizedBox(width: 8),
                        ...species.map((s) {
                          final isOn = selectedSpecies == s;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: s,
                              isSelected: isOn,
                              onTap: () => ref
                                  .read(selectedSpeciesFilterProvider.notifier)
                                  .state = isOn ? null : s,
                            ),
                          );
                        }),
                      ],
                    ),
                    orElse: () => const SizedBox(),
                  ),
                ),
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
                    '${selectedSpecies != null ? ' • $selectedSpecies' : ''}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textPrimary),
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
                                    '${_selectedHotspot!.nameAr} • ${_selectedHotspot!.region}',
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.oceanNavy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    GlassTokens.radiusMedium),
                                side: BorderSide(
                                    color: AppColors.cyanAccent
                                        .withValues(alpha: 0.5),
                                    width: 1.2),
                              ),
                            ),
                            onPressed: () => context
                                .push('/hotspots/${_selectedHotspot!.id}'),
                            child: Text(
                              'Inspect Bathymetry & Plan Trip',
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
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
                fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.oceanNavy
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
          border: Border.all(
            color: isSelected
                ? AppColors.cyanAccent
                : const Color(0xFFD6E6F7),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
