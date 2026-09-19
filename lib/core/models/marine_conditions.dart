class MarineConditions {
  final double seaTemperatureC;
  final double waveHeightM;
  final double wavePeriodS;
  final double windSpeedKts;
  final double windDirectionDeg;
  final String tideState; // Rising, Falling, High, Low, Unavailable
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

  MarineConditions copyWith({bool? isCached}) => MarineConditions(
        seaTemperatureC: seaTemperatureC,
        waveHeightM: waveHeightM,
        wavePeriodS: wavePeriodS,
        windSpeedKts: windSpeedKts,
        windDirectionDeg: windDirectionDeg,
        tideState: tideState,
        tideHeightM: tideHeightM,
        lastUpdated: lastUpdated,
        isCached: isCached ?? this.isCached,
      );

  /// Maps the backend `/api/v1/marine/conditions` proxy payload
  /// (aggregated Open-Meteo marine + weather + WorldTides fields).
  factory MarineConditions.fromJson(Map<String, dynamic> json) {
    double _num(Object? v, [double fallback = 0]) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    return MarineConditions(
      seaTemperatureC: _num(json['sea_temperature_c'], 27.5),
      waveHeightM: _num(json['wave_height_m'], 0.8),
      wavePeriodS: _num(json['wave_period_s'], 7.0),
      windSpeedKts: _num(json['wind_speed_kts'], 10),
      windDirectionDeg: _num(json['wind_direction_deg'], 125),
      tideState: (json['tide_state'] as String?) ?? 'Unavailable',
      tideHeightM: _num(json['tide_height_m'], 0),
      lastUpdated:
          DateTime.tryParse(json['fetched_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      isCached: json['cached'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'sea_temperature_c': seaTemperatureC,
        'wave_height_m': waveHeightM,
        'wave_period_s': wavePeriodS,
        'wind_speed_kts': windSpeedKts,
        'wind_direction_deg': windDirectionDeg,
        'tide_state': tideState,
        'tide_height_m': tideHeightM,
        'fetched_at': lastUpdated.toUtc().toIso8601String(),
        'cached': isCached,
      };
}
