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
  final double? estimatedFuelLiters;

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
    this.estimatedFuelLiters,
  });

  HotspotModel copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? region,
    double? latitude,
    double? longitude,
    double? distanceNm,
    int? depthMeters,
    List<String>? targetSpecies,
    int? probability,
    LegalStatus? legalStatus,
    String? bestWindow,
    String? description,
    String? legalNotice,
    double? estimatedFuelLiters,
  }) {
    return HotspotModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      region: region ?? this.region,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceNm: distanceNm ?? this.distanceNm,
      depthMeters: depthMeters ?? this.depthMeters,
      targetSpecies: targetSpecies ?? this.targetSpecies,
      probability: probability ?? this.probability,
      legalStatus: legalStatus ?? this.legalStatus,
      bestWindow: bestWindow ?? this.bestWindow,
      description: description ?? this.description,
      legalNotice: legalNotice ?? this.legalNotice,
      estimatedFuelLiters: estimatedFuelLiters ?? this.estimatedFuelLiters,
    );
  }

  factory HotspotModel.fromJson(Map<String, dynamic> json) {
    return HotspotModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      region: json['region'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceNm: (json['distanceNm'] as num?)?.toDouble() ?? 0.0,
      depthMeters: (json['depthMeters'] as num?)?.toInt() ?? 0,
      targetSpecies: (json['targetSpecies'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      probability: (json['probability'] as num?)?.toInt() ?? 0,
      legalStatus: legalStatusFromString(json['legalStatus'] as String?),
      bestWindow: json['bestWindow'] as String? ?? '',
      description: json['description'] as String? ?? '',
      legalNotice: json['legalNotice'] as String? ?? '',
      estimatedFuelLiters: (json['estimatedFuelLiters'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
      'distanceNm': distanceNm,
      'depthMeters': depthMeters,
      'targetSpecies': targetSpecies,
      'probability': probability,
      'legalStatus': legalStatus.name,
      'bestWindow': bestWindow,
      'description': description,
      'legalNotice': legalNotice,
      if (estimatedFuelLiters != null) 'estimatedFuelLiters': estimatedFuelLiters,
    };
  }
}

LegalStatus legalStatusFromString(String? value) {
  switch (value) {
    case 'protected':
      return LegalStatus.protected;
    case 'restricted':
      return LegalStatus.restricted;
    default:
      return LegalStatus.permitted;
  }
}
