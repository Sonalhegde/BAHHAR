class CrewMemberModel {
  final String id;
  final String name;
  final String nameArabic;
  final String role;
  final String roleArabic;
  final String? civilId;
  final String? phoneNumber;
  final String? fishingLicenceNumber;
  final DateTime? licenceExpiry;
  // Emergency Contact for this crew member
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final bool isActive;

  const CrewMemberModel({
    required this.id,
    required this.name,
    this.nameArabic = '',
    required this.role,
    this.roleArabic = '',
    this.civilId,
    this.phoneNumber,
    this.fishingLicenceNumber,
    this.licenceExpiry,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.isActive = true,
  });

  bool get licenceExpired {
    if (licenceExpiry == null) return false;
    return licenceExpiry!.isBefore(DateTime.now());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameArabic': nameArabic,
    'role': role,
    'roleArabic': roleArabic,
    'civilId': civilId,
    'phoneNumber': phoneNumber,
    'fishingLicenceNumber': fishingLicenceNumber,
    'licenceExpiry': licenceExpiry?.toIso8601String(),
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'emergencyContactRelation': emergencyContactRelation,
    'isActive': isActive,
  };

  factory CrewMemberModel.fromJson(Map<String, dynamic> json) {
    return CrewMemberModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameArabic: json['nameArabic'] as String? ?? '',
      role: json['role'] as String? ?? '',
      roleArabic: json['roleArabic'] as String? ?? '',
      civilId: json['civilId'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      fishingLicenceNumber: json['fishingLicenceNumber'] as String?,
      licenceExpiry: json['licenceExpiry'] != null
          ? DateTime.tryParse(json['licenceExpiry'] as String)
          : null,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      emergencyContactRelation: json['emergencyContactRelation'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
