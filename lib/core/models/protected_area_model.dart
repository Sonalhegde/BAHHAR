class ProtectedArea {
  final String id;
  final String name;
  final String nameAr;
  final String type; // Nature Reserve, Turtle Sanctuary, Naval Anchorage
  final double centerLat;
  final double centerLon;
  final double radiusKm;
  final String regulationSummary;
  final String legalDecree;

  const ProtectedArea({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.type,
    required this.centerLat,
    required this.centerLon,
    required this.radiusKm,
    required this.regulationSummary,
    required this.legalDecree,
  });
}
