class VesselModel {
  final String id;
  final String name;
  final String nameArabic;
  final String registrationNumber;
  final String type;             // e.g. 'Dhow', 'Motorboat', 'Fishing Vessel'
  final String typeArabic;
  final double? lengthMeters;
  final int? engineHp;
  final int? capacityPersons;
  final String? color;
  final String? colorArabic;
  // Licences / dates
  final String? navLicenceNumber;
  final DateTime? navLicenceExpiry;
  final DateTime? lastInspectionDate;
  final DateTime? nextInspectionDate;
  final String? insurancePolicyNumber;
  final DateTime? insuranceExpiry;
  // Meta
  final bool isActive;
  final String? photoUrl;

  const VesselModel({
    required this.id,
    required this.name,
    this.nameArabic = '',
    required this.registrationNumber,
    required this.type,
    this.typeArabic = '',
    this.lengthMeters,
    this.engineHp,
    this.capacityPersons,
    this.color,
    this.colorArabic,
    this.navLicenceNumber,
    this.navLicenceExpiry,
    this.lastInspectionDate,
    this.nextInspectionDate,
    this.insurancePolicyNumber,
    this.insuranceExpiry,
    this.isActive = true,
    this.photoUrl,
  });

  bool get navLicenceExpiringSoon {
    if (navLicenceExpiry == null) return false;
    final days = navLicenceExpiry!.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 30;
  }

  bool get navLicenceExpired {
    if (navLicenceExpiry == null) return false;
    return navLicenceExpiry!.isBefore(DateTime.now());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameArabic': nameArabic,
    'registrationNumber': registrationNumber,
    'type': type,
    'typeArabic': typeArabic,
    'lengthMeters': lengthMeters,
    'engineHp': engineHp,
    'capacityPersons': capacityPersons,
    'color': color,
    'colorArabic': colorArabic,
    'navLicenceNumber': navLicenceNumber,
    'navLicenceExpiry': navLicenceExpiry?.toIso8601String(),
    'lastInspectionDate': lastInspectionDate?.toIso8601String(),
    'nextInspectionDate': nextInspectionDate?.toIso8601String(),
    'insurancePolicyNumber': insurancePolicyNumber,
    'insuranceExpiry': insuranceExpiry?.toIso8601String(),
    'isActive': isActive,
    'photoUrl': photoUrl,
  };

  factory VesselModel.fromJson(Map<String, dynamic> json) {
    return VesselModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameArabic: json['nameArabic'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String? ?? '',
      type: json['type'] as String? ?? 'Fishing Vessel',
      typeArabic: json['typeArabic'] as String? ?? '',
      lengthMeters: (json['lengthMeters'] as num?)?.toDouble(),
      engineHp: json['engineHp'] as int?,
      capacityPersons: json['capacityPersons'] as int?,
      color: json['color'] as String?,
      colorArabic: json['colorArabic'] as String?,
      navLicenceNumber: json['navLicenceNumber'] as String?,
      navLicenceExpiry: json['navLicenceExpiry'] != null
          ? DateTime.tryParse(json['navLicenceExpiry'] as String)
          : null,
      lastInspectionDate: json['lastInspectionDate'] != null
          ? DateTime.tryParse(json['lastInspectionDate'] as String)
          : null,
      nextInspectionDate: json['nextInspectionDate'] != null
          ? DateTime.tryParse(json['nextInspectionDate'] as String)
          : null,
      insurancePolicyNumber: json['insurancePolicyNumber'] as String?,
      insuranceExpiry: json['insuranceExpiry'] != null
          ? DateTime.tryParse(json['insuranceExpiry'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  static VesselModel get demo => VesselModel(
    id: 'vessel_001',
    name: 'Al Salam',
    nameArabic: 'السلام',
    registrationNumber: 'OM-MSC-2019-0438',
    type: 'Traditional Dhow',
    typeArabic: 'سنبوق تقليدي',
    lengthMeters: 8.5,
    engineHp: 85,
    capacityPersons: 6,
    color: 'Blue & White',
    colorArabic: 'أزرق وأبيض',
    navLicenceNumber: 'NAV-2024-1122',
    navLicenceExpiry: DateTime.now().add(const Duration(days: 120)),
    lastInspectionDate: DateTime(2024, 3, 10),
    nextInspectionDate: DateTime(2025, 3, 10),
    isActive: true,
  );
}
