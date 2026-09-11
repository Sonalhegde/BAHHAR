class CatchModel {
  final String id;
  final String userId;
  final String speciesName;
  final String speciesNameAr;
  final double weightKg;
  final double? lengthCm;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime caughtAt;
  final String notes;
  final String? photoUrl;
  final double? seaTempC;
  final double? waveHeightM;
  final String? baitOrLure;
  final bool released;

  const CatchModel({
    required this.id,
    this.userId = '',
    required this.speciesName,
    this.speciesNameAr = '',
    required this.weightKg,
    this.lengthCm,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.caughtAt,
    this.notes = '',
    this.photoUrl,
    this.seaTempC,
    this.waveHeightM,
    this.baitOrLure,
    this.released = false,
  });

  CatchModel copyWith({
    String? id,
    String? userId,
    String? speciesName,
    String? speciesNameAr,
    double? weightKg,
    double? lengthCm,
    String? locationName,
    double? latitude,
    double? longitude,
    DateTime? caughtAt,
    String? notes,
    String? photoUrl,
    double? seaTempC,
    double? waveHeightM,
    String? baitOrLure,
    bool? released,
  }) {
    return CatchModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      speciesName: speciesName ?? this.speciesName,
      speciesNameAr: speciesNameAr ?? this.speciesNameAr,
      weightKg: weightKg ?? this.weightKg,
      lengthCm: lengthCm ?? this.lengthCm,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      caughtAt: caughtAt ?? this.caughtAt,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      seaTempC: seaTempC ?? this.seaTempC,
      waveHeightM: waveHeightM ?? this.waveHeightM,
      baitOrLure: baitOrLure ?? this.baitOrLure,
      released: released ?? this.released,
    );
  }

  factory CatchModel.fromJson(Map<String, dynamic> json) {
    return CatchModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      speciesName: json['speciesName'] as String? ?? '',
      speciesNameAr: json['speciesNameAr'] as String? ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      lengthCm: (json['lengthCm'] as num?)?.toDouble(),
      locationName: json['locationName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      caughtAt: DateTime.tryParse(json['caughtAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(
              (json['caughtAtMs'] as num?)?.toInt() ?? 0),
      notes: json['notes'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      seaTempC: (json['seaTempC'] as num?)?.toDouble(),
      waveHeightM: (json['waveHeightM'] as num?)?.toDouble(),
      baitOrLure: json['baitOrLure'] as String?,
      released: json['released'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'speciesName': speciesName,
      'speciesNameAr': speciesNameAr,
      'weightKg': weightKg,
      if (lengthCm != null) 'lengthCm': lengthCm,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'caughtAt': caughtAt.toIso8601String(),
      'notes': notes,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (seaTempC != null) 'seaTempC': seaTempC,
      if (waveHeightM != null) 'waveHeightM': waveHeightM,
      if (baitOrLure != null) 'baitOrLure': baitOrLure,
      'released': released,
    };
  }
}
