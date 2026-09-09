enum LicenceStatus { valid, expiringSoon, expired, pending }

class FishingLicenceModel {
  final String id;
  final String licenceNumber;
  final String licenceType;      // e.g. 'Commercial', 'Recreational', 'Artisanal'
  final String licenceTypeArabic;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String issuingAuthority;
  final String issuingAuthorityArabic;
  final LicenceStatus status;
  final String? scanUrl;         // optional uploaded scan

  const FishingLicenceModel({
    required this.id,
    required this.licenceNumber,
    required this.licenceType,
    this.licenceTypeArabic = '',
    required this.issueDate,
    required this.expiryDate,
    required this.issuingAuthority,
    this.issuingAuthorityArabic = '',
    required this.status,
    this.scanUrl,
  });

  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool get isExpired => daysUntilExpiry < 0;
  bool get isExpiringSoon => !isExpired && daysUntilExpiry <= 30;

  LicenceStatus get computedStatus {
    if (status == LicenceStatus.pending) return LicenceStatus.pending;
    if (isExpired) return LicenceStatus.expired;
    if (isExpiringSoon) return LicenceStatus.expiringSoon;
    return LicenceStatus.valid;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'licenceNumber': licenceNumber,
    'licenceType': licenceType,
    'licenceTypeArabic': licenceTypeArabic,
    'issueDate': issueDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'issuingAuthority': issuingAuthority,
    'issuingAuthorityArabic': issuingAuthorityArabic,
    'status': status.name,
    'scanUrl': scanUrl,
  };

  factory FishingLicenceModel.fromJson(Map<String, dynamic> json) {
    return FishingLicenceModel(
      id: json['id'] as String? ?? '',
      licenceNumber: json['licenceNumber'] as String? ?? '',
      licenceType: json['licenceType'] as String? ?? '',
      licenceTypeArabic: json['licenceTypeArabic'] as String? ?? '',
      issueDate: DateTime.parse(json['issueDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      issuingAuthority: json['issuingAuthority'] as String? ?? '',
      issuingAuthorityArabic: json['issuingAuthorityArabic'] as String? ?? '',
      status: LicenceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => LicenceStatus.valid,
      ),
      scanUrl: json['scanUrl'] as String?,
    );
  }

  static FishingLicenceModel get demo => FishingLicenceModel(
    id: 'lic_001',
    licenceNumber: 'MFA-2024-00512',
    licenceType: 'Artisanal Fishing',
    licenceTypeArabic: 'صيد حرفي',
    issueDate: DateTime(2024, 1, 15),
    expiryDate: DateTime.now().add(const Duration(days: 45)),
    issuingAuthority: 'Ministry of Agriculture, Fisheries and Water Resources',
    issuingAuthorityArabic: 'وزارة الزراعة والثروة السمكية وموارد المياه',
    status: LicenceStatus.expiringSoon,
  );
}
