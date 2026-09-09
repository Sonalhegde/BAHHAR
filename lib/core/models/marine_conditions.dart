class MarineConditions {
  final double seaTemperatureC;
  final double waveHeightM;
  final double wavePeriodS;
  final double windSpeedKts;
  final double windDirectionDeg;
  final String tideState; // Rising, Falling, High, Low
  final double tideHeightM;
  final DateTime lastUpdated;
  final bool isCached;

  const MarineConditions({
    required this.seaTemperatureC,
    required this.waveHeightM,
    required this.wavePeriodS,
    required this.windSpeedKts,
    required this.windDirectionDeg,
    required this.tideState,
    required this.tideHeightM,
    required this.lastUpdated,
    this.isCached = false,
  });

  String get windDirectionCompass {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((windDirectionDeg + 22.5) % 360 / 45).floor();
    return directions[idx];
  }
}
