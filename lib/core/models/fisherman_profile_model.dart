
/// Complete fisherman profile — the core identity record for a BAHHAR user.
class FishermanProfileModel {
  final String uid;
  // Personal
  final String fullName;
  final String fullNameArabic;
  final String civilId; // stored masked in display; full value kept private
  final DateTime? dateOfBirth;
  final String phoneNumber;
  final String? alternatePhone;
  final String? email;
  // Address
  final String governorate;
  final String? wilayat;
  final String? address;
  // Emergency Contact
  final EmergencyContactModel? emergencyContact;
  // Fishing
  final String? fishermanId; // ministry-issued fisherman ID
  final List<String> licenceIds; // references to FishingLicenceModel
  final List<String> vesselIds;  // references to VesselModel
  final List<String> crewIds;    // references to CrewMemberModel
  final List<String> gearIds;    // references to FishingGearModel
  final List<String> documentIds;// references to DocumentModel
  // Meta
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? profilePhotoUrl;

  const FishermanProfileModel({
    required this.uid,
    required this.fullName,
    this.fullNameArabic = '',
    required this.civilId,
    this.dateOfBirth,
    required this.phoneNumber,
    this.alternatePhone,
    this.email,
    required this.governorate,
    this.wilayat,
    this.address,
    this.emergencyContact,
    this.fishermanId,
    this.licenceIds = const [],
    this.vesselIds = const [],
    this.crewIds = const [],
    this.gearIds = const [],
    this.documentIds = const [],
    this.createdAt,
    this.updatedAt,
    this.profilePhotoUrl,
  });

  /// Completion percentage (0–100) for profile progress indicator.
  int get completionPercentage {
    int score = 0;
    const int total = 100;
    // Required (60 points)
    if (fullName.isNotEmpty) score += 15;
    if (civilId.isNotEmpty) score += 15;
    if (phoneNumber.isNotEmpty) score += 15;
    if (emergencyContact != null) score += 15;
    // Recommended (30 points)
    if (licenceIds.isNotEmpty) score += 10;
    if (vesselIds.isNotEmpty) score += 10;
    if (governorate.isNotEmpty) score += 5;
    if (wilayat != null && wilayat!.isNotEmpty) score += 5;
    // Optional (10 points)
    if (profilePhotoUrl != null) score += 5;
    if (email != null && email!.isNotEmpty) score += 5;
    return score.clamp(0, total);
  }

  FishermanProfileModel copyWith({
    String? uid,
    String? fullName,
    String? fullNameArabic,
    String? civilId,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? alternatePhone,
    String? email,
    String? governorate,
    String? wilayat,
    String? address,
    EmergencyContactModel? emergencyContact,
    String? fishermanId,
    List<String>? licenceIds,
    List<String>? vesselIds,
    List<String>? crewIds,
    List<String>? gearIds,
    List<String>? documentIds,
    DateTime? updatedAt,
    String? profilePhotoUrl,
  }) {
    return FishermanProfileModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      fullNameArabic: fullNameArabic ?? this.fullNameArabic,
      civilId: civilId ?? this.civilId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      governorate: governorate ?? this.governorate,
      wilayat: wilayat ?? this.wilayat,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      fishermanId: fishermanId ?? this.fishermanId,
      licenceIds: licenceIds ?? this.licenceIds,
      vesselIds: vesselIds ?? this.vesselIds,
      crewIds: crewIds ?? this.crewIds,
      gearIds: gearIds ?? this.gearIds,
      documentIds: documentIds ?? this.documentIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'fullName': fullName,
    'fullNameArabic': fullNameArabic,
    'civilId': civilId,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'phoneNumber': phoneNumber,
    'alternatePhone': alternatePhone,
    'email': email,
    'governorate': governorate,
    'wilayat': wilayat,
    'address': address,
    'emergencyContact': emergencyContact?.toJson(),
    'fishermanId': fishermanId,
    'licenceIds': licenceIds,
    'vesselIds': vesselIds,
    'crewIds': crewIds,
    'gearIds': gearIds,
    'documentIds': documentIds,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'profilePhotoUrl': profilePhotoUrl,
  };

  factory FishermanProfileModel.fromJson(Map<String, dynamic> json) {
    return FishermanProfileModel(
      uid: json['uid'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      fullNameArabic: json['fullNameArabic'] as String? ?? '',
      civilId: json['civilId'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      alternatePhone: json['alternatePhone'] as String?,
      email: json['email'] as String?,
      governorate: json['governorate'] as String? ?? 'Muscat',
      wilayat: json['wilayat'] as String?,
      address: json['address'] as String?,
      emergencyContact: json['emergencyContact'] != null
          ? EmergencyContactModel.fromJson(json['emergencyContact'] as Map<String, dynamic>)
          : null,
      fishermanId: json['fishermanId'] as String?,
      licenceIds: List<String>.from(json['licenceIds'] as List? ?? []),
      vesselIds: List<String>.from(json['vesselIds'] as List? ?? []),
      crewIds: List<String>.from(json['crewIds'] as List? ?? []),
      gearIds: List<String>.from(json['gearIds'] as List? ?? []),
      documentIds: List<String>.from(json['documentIds'] as List? ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
    );
  }

  /// Demo profile for mock/testing
  static FishermanProfileModel get demo => FishermanProfileModel(
    uid: 'demo_uid',
    fullName: 'Ahmed Al Balushi',
    fullNameArabic: 'أحمد البلوشي',
    civilId: '12345678',
    dateOfBirth: DateTime(1985, 6, 15),
    phoneNumber: '+96899123456',
    email: 'ahmed@example.com',
    governorate: 'Muscat',
    wilayat: 'Muttrah',
    emergencyContact: const EmergencyContactModel(
      name: 'Fatima Al Balushi',
      nameArabic: 'فاطمة البلوشي',
      relationship: 'Spouse',
      relationshipArabic: 'زوجة',
      phoneNumber: '+96899654321',
    ),
    fishermanId: 'FID-2024-00512',
    licenceIds: ['lic_001'],
    vesselIds: ['vessel_001'],
    crewIds: [],
    gearIds: [],
    documentIds: [],
    createdAt: DateTime(2024, 1, 10),
    updatedAt: DateTime.now(),
  );
}

class EmergencyContactModel {
  final String name;
  final String nameArabic;
  final String relationship;
  final String relationshipArabic;
  final String phoneNumber;
  final String? alternatePhone;

  const EmergencyContactModel({
    required this.name,
    this.nameArabic = '',
    required this.relationship,
    this.relationshipArabic = '',
    required this.phoneNumber,
    this.alternatePhone,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'nameArabic': nameArabic,
    'relationship': relationship,
    'relationshipArabic': relationshipArabic,
    'phoneNumber': phoneNumber,
    'alternatePhone': alternatePhone,
  };

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name'] as String? ?? '',
      nameArabic: json['nameArabic'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      relationshipArabic: json['relationshipArabic'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      alternatePhone: json['alternatePhone'] as String?,
    );
  }
}
