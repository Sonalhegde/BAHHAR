import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/models/hotspot_model.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/polymorphic/soft_toggle.dart';
import '../../../shared/widgets/legal_status_badge.dart';

class FishingMapScreen extends ConsumerStatefulWidget {
  const FishingMapScreen({super.key});

  @override
  ConsumerState<FishingMapScreen> createState() => _FishingMapScreenState();
}

class _FishingMapScreenState extends ConsumerState<FishingMapScreen> {
  String _activeFilter = 'all';
  HotspotModel? _selectedHotspot;

  @override
  Widget build(BuildContext context) {
    final hotspotsAsync = ref.watch(hotspotsListProvider);

    return Scaffold(
      backgroundColor: AppColors.mapWater,
      body: Stack(
        children: [
          // Interactive Nautical Bathymetry Simulation
          Positioned.fill(
            child: CustomPaint(
              painter: _MarineChartCanvasPainter(),
              child: GestureDetector(
                onTap: () => setState(() => _selectedHotspot = null),
              ),
            ),
          ),

          // Protected Marine Reserve Boundary Overlay (Daymaniyat)
          Positioned(
            left: 80,
            top: 180,
            child: Container(
              width: 150,
              height: 94,
              decoration: BoxDecoration(
                color: AppColors.legalRestricted.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.legalRestricted, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.legalRestricted.withValues(alpha: 0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.legalRestricted),
                  const SizedBox(height: 3),
                  Text(
                    'Daymaniyat Marine Reserve\nPermit Required',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9.5,
                      color: AppColors.legalRestricted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Glass Filter Controls
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PolymorphicChip(
                    label: 'All Spots',
                    isSelected: _activeFilter == 'all',
                    onTap: () => setState(() => _activeFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  PolymorphicChip(
                    label: 'Pelagic (Kingfish/Tuna)',
                    isSelected: _activeFilter == 'pelagic',
                    onTap: () => setState(() => _activeFilter = 'pelagic'),
                  ),
                  const SizedBox(width: 8),
                  PolymorphicChip(
                    label: 'Bottom / Reef',
                    isSelected: _activeFilter == 'bottom',
                    onTap: () => setState(() => _activeFilter = 'bottom'),
                  ),
                  const SizedBox(width: 8),
                  PolymorphicChip(
                    label: 'Nature Reserves',
                    isSelected: _activeFilter == 'reserves',
                    onTap: () => setState(() => _activeFilter = 'reserves'),
                  ),
                ],
              ),
            ),
          ),

          // Hotspot Map Markers
          hotspotsAsync.when(
            data: (hotspots) {
              return Stack(
                children: hotspots.map((h) {
                  final isSelected = _selectedHotspot?.id == h.id;
                  final left = h.longitude > 58 ? 250.0 : (h.longitude > 57 ? 170.0 : 80.0);
                  final top = h.latitude > 23.8 ? 230.0 : (h.latitude > 23 ? 320.0 : 440.0);

                  return Positioned(
                    left: left,
                    top: top,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedHotspot = h),
                      child: AnimatedScale(
                        scale: isSelected ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        child: GlassContainer(
                          level: isSelected ? GlassLevel.prominent : GlassLevel.standard,
                          borderRadius: GlassTokens.radiusSmall,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          customColor: isSelected
                              ? AppColors.oceanNavy.withValues(alpha: 0.9)
                              : const Color(0xFF071B2D).withValues(alpha: 0.65),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: h.isProtectedReserve
                                      ? AppColors.legalRestricted
                                      : AppColors.getProbabilityColor(h.rating),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.getProbabilityColor(h.rating).withValues(alpha: 0.8),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${h.name} (${h.rating})',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
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
                              Text(_selectedHotspot!.name, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
                              Text(
                                '${_selectedHotspot!.nameArabic} • ${_selectedHotspot!.governorate}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        LegalStatusBadge(isRestricted: _selectedHotspot!.isProtectedReserve),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCol('DEPTH', '${_selectedHotspot!.depthMeters} m'),
                        _buildStatCol('DISTANCE', '${_selectedHotspot!.distanceNmi} nmi'),
                        _buildStatCol('BITE SCORE', '${_selectedHotspot!.rating}/100'),
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
                            borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
                            side: BorderSide(color: AppColors.cyanAccent.withValues(alpha: 0.5), width: 1.2),
                          ),
                        ),
                        onPressed: () => context.push('/hotspots/${_selectedHotspot!.id}'),
                        child: Text(
                          'Inspect Bathymetry & Plan Trip',
                          style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
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

  Widget _buildStatCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionHeader.copyWith(fontSize: 9.5)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}

class _MarineChartCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final landPaint = Paint()
      ..color = const Color(0xFF0C2134)
      ..style = PaintingStyle.fill;

    final coastlinePaint = Paint()
      ..color = const Color(0xFF1E4B72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Bathymetry Grid
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Coastal landmass polygon
    final path = Path();
    path.moveTo(0, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.22, size.width * 0.62, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.72, size.height * 0.75, size.width * 0.5, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, landPaint);
    canvas.drawPath(path, coastlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
