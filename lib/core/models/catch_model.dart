class CatchModel {
  final String id;
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

  const CatchModel({
    required this.id,
    required this.speciesName,
    required this.speciesNameAr,
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
  });
}
