import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/models/hotspot_model.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/widgets/legal_status_badge.dart';

/// Real Google Maps fishing chart. Markers are colored by
/// AppColors.getProbabilityColor(hotspot.probability); the species chips
/// filter markers through selectedSpeciesFilterProvider. Tapping a marker
/// opens the same full-screen Hotspot Details push used by the home list.
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

  final Map<String, Marker> _markersById = {};
  HotspotModel? _selectedHotspot;

  /// Kept for future camera animations (e.g. fly-to-hotspot from search);
  /// referenced on dispose to satisfy the controller lifecycle.
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<HotspotModel> hotspots) {
    _markersById.clear();
    final bitmapCache = <Color, BitmapDescriptor>{};

    for (final h in hotspots) {
      final color = h.legalStatus != LegalStatus.permitted
          ? AppColors.legalRestricted
          : AppColors.getProbabilityColor(h.probability);
      final descriptor = bitmapCache.putIfAbsent(
        color,
        () => BitmapDescriptor.defaultMarkerWithHue(
          _hueForColor(color),
        ),
      );
      final marker = Marker(
        markerId: MarkerId(h.id),
        position: LatLng(h.latitude, h.longitude),
        icon: descriptor,
        infoWindow: InfoWindow(
          title: h.name,
          snippet: 'Bite probability ${h.probability}% • ${h.bestWindow}',
        ),
        onTap: () => setState(() => _selectedHotspot = h),
      );
      _markersById[h.id] = marker;
    }
    return _markersById.values.toSet();
  }

  double _hueForColor(Color c) {
    final hsv = HSVColor.fromColor(c);
    return hsv.hue;
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
          final markers = _buildMarkers(hotspots);

          return Stack(
            children: [
              // Real interactive Google Map
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: _muscatSeeb,
                  markers: markers,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (_) => setState(() => _selectedHotspot = null),
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
