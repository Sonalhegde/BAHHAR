import '../../shared/widgets/legal_status_badge.dart';

class HotspotModel {
  final String id;
  final String name;
  final String nameAr;
  final String region; // Muscat, Musandam, Al Batinah, Ash Sharqiyah, Al Wusta, Dhofar
  final double latitude;
  final double longitude;
  final double distanceNm;
  final int depthMeters;
  final List<String> targetSpecies;
  final int probability; // 0 - 100
  final LegalStatus legalStatus;
  final String bestWindow;
  final String description;
  final String legalNotice;

  const HotspotModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.distanceNm,
    required this.depthMeters,
    required this.targetSpecies,
    required this.probability,
    required this.legalStatus,
    required this.bestWindow,
    required this.description,
    this.legalNotice = '',
  });
}
