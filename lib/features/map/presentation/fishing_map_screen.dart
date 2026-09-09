import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/models/hotspot_model.dart';
import '../../../shared/widgets/legal_status_badge.dart';

class FishingMapScreen extends ConsumerStatefulWidget {
  const FishingMapScreen({super.key});

  @override
  ConsumerState<FishingMapScreen> createState() => _FishingMapScreenState();
}

class _FishingMapScreenState extends ConsumerState<FishingMapScreen> {
  String _activeLayer = 'all'; // all, pelagic, bottom, protected
  HotspotModel? _selectedHotspot;

  @override
  Widget build(BuildContext context) {
    final hotspotsAsync = ref.watch(hotspotsListProvider);

    return Scaffold(
      backgroundColor: AppColors.mapWater,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePure,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Oman Marine Chart', style: AppTextStyles.subhead),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderHairline, height: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, size: 20, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Muted editorial nautical map view simulation
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE5E9EC), // soft nautical gray-water
              child: CustomPaint(
                painter: _EditorialChartPainter(),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedHotspot = null);
                  },
                ),
              ),
            ),
          ),

          // Layer selector bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfacePure,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Row(
                children: [
                  _buildLayerFilter('all', 'All Spots'),
                  _buildLayerFilter('pelagic', 'Pelagic'),
                  _buildLayerFilter('bottom', 'Bottom/Reef'),
                  _buildLayerFilter('reserves', 'Reserves'),
                ],
              ),
            ),
          ),

          // Interactive Map Markers (simulated accurate coordinates projection)
          hotspotsAsync.when(
            data: (hotspots) {
              return Stack(
                children: [
                  // Dimaniyat Reserve boundary overlay
                  Positioned(
                    left: 90,
                    top: 170,
                    child: Container(
                      width: 140,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.legalRestricted.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.legalRestricted, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: AppColors.legalRestricted),
                          const SizedBox(height: 2),
                          Text(
                            'Daymaniyat Marine Reserve\nPermit Required',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              color: AppColors.legalRestricted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hotspot pins
                  ...hotspots.map((h) {
                    final isSelected = _selectedHotspot?.id == h.id;
                    return Positioned(
                      left: h.longitude > 58 ? 240 : (h.longitude > 57 ? 160 : 70),
                      top: h.latitude > 23.8 ? 220 : (h.latitude > 23 ? 310 : 420),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedHotspot = h);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentNavy : AppColors.surfacePure,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? AppColors.accentNavy : AppColors.borderHairline,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: h.isProtectedReserve
                                      ? AppColors.legalRestricted
                                      : (h.rating >= 85 ? AppColors.signalGood : AppColors.signalCaution),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${h.name} (${h.rating})',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const SizedBox(),
          ),

          // Bottom Detail Card if selected
          if (_selectedHotspot != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfacePure,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderHairline),
                ),
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
                              Text(_selectedHotspot!.name, style: AppTextStyles.cardTitle),
                              Text(
                                '${_selectedHotspot!.nameArabic} • ${_selectedHotspot!.governorate}',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        LegalStatusBadge(isRestricted: _selectedHotspot!.isProtectedReserve),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderHairline),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn('DEPTH', '${_selectedHotspot!.depthMeters} m'),
                        _buildInfoColumn('DISTANCE', '${_selectedHotspot!.distanceNmi} nmi'),
                        _buildInfoColumn('SCORE', '${_selectedHotspot!.rating}/100'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.accentNavy,
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          context.push('/hotspots/${_selectedHotspot!.id}');
                        },
                        child: Text('Inspect Hotspot Details', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayerFilter(String id, String label) {
    final isSelected = _activeLayer == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeLayer = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(letterSpacing: 0.8, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EditorialChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final landPaint = Paint()
      ..color = const Color(0xFFF4F2EC) // muted editorial landmass
      ..style = PaintingStyle.fill;

    final coastlinePaint = Paint()
      ..color = const Color(0xFFD6D3C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final gridPaint = Paint()
      ..color = const Color(0xFFD5DBDF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Bathymetry grid
    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Oman coastline polygon simulation
    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.25, size.width * 0.6, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.7, size.width * 0.5, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, landPaint);
    canvas.drawPath(path, coastlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}\n