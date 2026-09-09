import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../shared/widgets/hotspot_card.dart';
import '../../../shared/widgets/legal_status_badge.dart';

class FishingMapScreen extends ConsumerStatefulWidget {
  const FishingMapScreen({super.key});

  @override
  ConsumerState<FishingMapScreen> createState() => _FishingMapScreenState();
}

class _FishingMapScreenState extends ConsumerState<FishingMapScreen> {
  bool _showHeatmap = true;
  bool _showProtectedAreas = true;
  String? _selectedHotspotId;

  final List<String> _regions = ['All Regions', 'Muscat', 'Musandam', 'Al Batinah South', 'Ash Sharqiyah South', 'Dhofar'];

  @override
  Widget build(BuildContext context) {
    final hotspots = ref.watch(filteredHotspotsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oman Fishing Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            onPressed: () => _openLayerBottomSheet(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Simulated Marine Chart / Google Maps View
          Container(
            color: isDark ? const Color(0xFF031625) : const Color(0xFFE3F2FD),
            child: Stack(
              children: [
                // Stylized Coastline Water Gradient
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MarineChartPainter(isDark: isDark),
                  ),
                ),
                // Hotspot Markers placed across Omani Coastline
                ...hotspots.map((h) {
                  // Coordinate normalization onto screen bounds
                  final x = ((h.longitude - 54.0) / 6.0) * MediaQuery.of(context).size.width;
                  final y = (1.0 - (h.latitude - 16.5) / 10.0) * (MediaQuery.of(context).size.height * 0.7);

                  final probColor = AppColors.getProbabilityColor(h.probability);
                  final isProtected = h.legalStatus == LegalStatus.protected;

                  return Positioned(
                    left: x.clamp(30.0, MediaQuery.of(context).size.width - 70.0),
                    top: y.clamp(80.0, MediaQuery.of(context).size.height - 240.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedHotspotId = h.id);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsetsDirectional.all(6),
                            decoration: BoxDecoration(
                              color: isProtected ? AppColors.protectedArea : probColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isProtected ? AppColors.protectedArea : probColor).withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              isProtected ? Icons.shield : Icons.phishing,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${h.name.split(" ").first} (${h.probability}%)',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Top Region Filter Bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _regions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final region = _regions[index];
                  final isSelected = (region == 'All Regions' && ref.watch(selectedRegionFilterProvider) == null) ||
                      (ref.watch(selectedRegionFilterProvider) == region);

                  return ChoiceChip(
                    label: Text(region, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    selectedColor: AppColors.deepSea,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    onSelected: (_) {
                      ref.read(selectedRegionFilterProvider.notifier).state =
                          region == 'All Regions' ? null : region;
                    },
                  );
                },
              ),
            ),
          ),

          // Bottom Selected Hotspot Preview Card
          if (_selectedHotspotId != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Builder(
                builder: (context) {
                  final selected = hotspots.firstWhere((h) => h.id == _selectedHotspotId);
                  return HotspotCard(
                    name: selected.name,
                    probability: selected.probability,
                    distanceNm: selected.distanceNm,
                    primarySpecies: selected.targetSpecies.first,
                    legalStatus: selected.legalStatus,
                    onTap: () => context.push('/hotspot/${selected.id}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openLayerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsetsDirectional.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Map Layers', style: AppTextStyles.h2),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Fishing Probability Heatmap'),
                    value: _showHeatmap,
                    activeColor: AppColors.aquaTeal,
                    onChanged: (val) {
                      setModalState(() => _showHeatmap = val);
                      setState(() => _showHeatmap = val);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Protected Marine Reserves (Violet Overlay)'),
                    subtitle: const Text('Nature reserves & sanctuary boundaries'),
                    value: _showProtectedAreas,
                    activeColor: AppColors.protectedArea,
                    onChanged: (val) {
                      setModalState(() => _showProtectedAreas = val);
                      setState(() => _showProtectedAreas = val);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MarineChartPainter extends CustomPainter {
  final bool isDark;
  _MarineChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bathymetryPaint = Paint()
      ..color = (isDark ? const Color(0xFF0F3652) : const Color(0xFFBBDEFB)).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw depth contour lines
    for (int i = 1; i <= 5; i++) {
      final path = Path();
      path.moveTo(0, size.height * (0.2 * i));
      path.quadraticBezierTo(
        size.width * 0.4,
        size.height * (0.2 * i - 0.05),
        size.width,
        size.height * (0.2 * i + 0.05),
      );
      canvas.drawPath(path, bathymetryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
