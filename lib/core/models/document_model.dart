enum DocumentType {
  fishingLicence,
  navLicence,
  boatRegistration,
  insurance,
  civilId,
  gearPermit,
  other,
}

extension DocumentTypeLabel on DocumentType {
  String get labelEn {
    switch (this) {
      case DocumentType.fishingLicence: return 'Fishing Licence';
      case DocumentType.navLicence: return 'Navigation Licence';
      case DocumentType.boatRegistration: return 'Boat Registration';
      case DocumentType.insurance: return 'Insurance';
      case DocumentType.civilId: return 'Civil ID';
      case DocumentType.gearPermit: return 'Gear Permit';
      case DocumentType.other: return 'Other';
    }
  }
  String get labelAr {
    switch (this) {
      case DocumentType.fishingLicence: return 'تصريح الصيد';
      case DocumentType.navLicence: return 'ترخيص الملاحة';
      case DocumentType.boatRegistration: return 'تسجيل القارب';
      case DocumentType.insurance: return 'التأمين';
      case DocumentType.civilId: return 'الهوية المدنية';
      case DocumentType.gearPermit: return 'تصريح المعدة';
      case DocumentType.other: return 'أخرى';
    }
  }
}

class DocumentModel {
  final String id;
  final DocumentType type;
  final String documentNumber;
  final String title;
  final String titleArabic;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? issuingAuthority;
  final String? scanUrl;
  final bool hasReminder;

  const DocumentModel({
    required this.id,
    required this.type,
    required this.documentNumber,
    required this.title,
    this.titleArabic = '',
    this.issueDate,
    this.expiryDate,
    this.issuingAuthority,
    this.scanUrl,
    this.hasReminder = true,
  });

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    return expiryDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool get isExpired => daysUntilExpiry != null && daysUntilExpiry! < 0;
  bool get isExpiringSoon => daysUntilExpiry != null && !isExpired && daysUntilExpiry! <= 30;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'documentNumber': documentNumber,
    'title': title,
    'titleArabic': titleArabic,
    'issueDate': issueDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'issuingAuthority': issuingAuthority,
    'scanUrl': scanUrl,
    'hasReminder': hasReminder,
  };

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String? ?? '',
      type: DocumentType.values.firstWhere(
        (d) => d.name == json['type'],
        orElse: () => DocumentType.other,
      ),
      documentNumber: json['documentNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleArabic: json['titleArabic'] as String? ?? '',
      issueDate: json['issueDate'] != null
          ? DateTime.tryParse(json['issueDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
      issuingAuthority: json['issuingAuthority'] as String?,
      scanUrl: json['scanUrl'] as String?,
      hasReminder: json['hasReminder'] as bool? ?? true,
    );
  }
}

class FishingGearModel {
  final String id;
  final String gearType;
  final String gearTypeArabic;
  final String? permitNumber;
  final DateTime? permitExpiry;
  final String? description;

  const FishingGearModel({
    required this.id,
    required this.gearType,
    this.gearTypeArabic = '',
    this.permitNumber,
    this.permitExpiry,
    this.description,
  });

  bool get permitExpired =>
      permitExpiry != null && permitExpiry!.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
    'id': id,
    'gearType': gearType,
    'gearTypeArabic': gearTypeArabic,
    'permitNumber': permitNumber,
    'permitExpiry': permitExpiry?.toIso8601String(),
    'description': description,
  };

  factory FishingGearModel.fromJson(Map<String, dynamic> json) {
    return FishingGearModel(
      id: json['id'] as String? ?? '',
      gearType: json['gearType'] as String? ?? '',
      gearTypeArabic: json['gearTypeArabic'] as String? ?? '',
      permitNumber: json['permitNumber'] as String?,
      permitExpiry: json['permitExpiry'] != null
          ? DateTime.tryParse(json['permitExpiry'] as String)
          : null,
      description: json['description'] as String?,
    );
  }
}
