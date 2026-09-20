/// Live water and air readings for one coastal position.
///
/// Field set mirrors the backend `/api/v1/marine/conditions` proxy exactly, so a
/// reading that exists upstream is not silently dropped on the way to the
/// dashboard. Every new field is optional with a neutral default, because this
/// model is also built from cached and partial payloads.
class MarineConditions {
  final double seaTemperatureC;
  final double waveHeightM;
  final double wavePeriodS;

  /// Bearing the seas are coming FROM, degrees true. Kept separate from
  /// [windDirectionDeg] on purpose: on the Omani coast a sea swell and a afternoon
  /// breeze routinely disagree, and one compass reading cannot stand in for both.
  final double waveDirectionDeg;
  final double windSpeedKts;
  final double windDirectionDeg;

  /// Surface current, recombined upstream from its eastward/northward components.
  /// Direction is the bearing the water SETS TOWARD - the opposite convention to
  /// waves and wind, which the backend labels `current_sets_to` for the same reason.
  final double currentSpeedKts;
  final double currentDirectionDeg;

  /// Null when the upstream did not report visibility. Zero would read as "fog"
  /// on a day the instrument simply said nothing.
  final double? visibilityKm;

  /// good | moderate | rough_sea | strong_current | high_risk | unknown.
  /// Computed server-side as the WORST single reading, never an average; the
  /// thresholds are published in the landing page's status band and in
  /// backend/main.py::_sea_state_band.
  final String seaStateBand;
  final String tideState; // Rising, Falling, High, Low, Unavailable
  final double tideHeightM;
  final DateTime lastUpdated;
  final bool isCached;

  const MarineConditions({
    required this.seaTemperatureC,
    required this.waveHeightM,
    required this.wavePeriodS,
    this.waveDirectionDeg = 0,
    required this.windSpeedKts,
    required this.windDirectionDeg,
    this.currentSpeedKts = 0,
    this.currentDirectionDeg = 0,
    this.visibilityKm,
    this.seaStateBand = 'unknown',
    required this.tideState,
    required this.tideHeightM,
    required this.lastUpdated,
    this.isCached = false,
  });

  /// 16-point compass text, matching the backend's `_compass_deg` so the card and
  /// the API never print two different words for one bearing.
  static String compass(double degrees) {
    const points = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', //
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    return points[((degrees + 11.25) % 360 / 22.5).floor()];
  }

  String get windDirectionCompass => compass(windDirectionDeg);
  String get waveDirectionCompass => compass(waveDirectionDeg);
  String get currentSetsToCompass => compass(currentDirectionDeg);

  /// Whether the water is rough enough to change what this trip should be.
  bool get isRough =>
      seaStateBand == 'rough_sea' || seaStateBand == 'high_risk';

  MarineConditions copyWith({bool? isCached}) => MarineConditions(
        seaTemperatureC: seaTemperatureC,
        waveHeightM: waveHeightM,
        wavePeriodS: wavePeriodS,
        waveDirectionDeg: waveDirectionDeg,
        windSpeedKts: windSpeedKts,
        windDirectionDeg: windDirectionDeg,
        currentSpeedKts: currentSpeedKts,
        currentDirectionDeg: currentDirectionDeg,
        visibilityKm: visibilityKm,
        seaStateBand: seaStateBand,
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

    final seaState = json['sea_state'];

    return MarineConditions(
      seaTemperatureC: _num(json['sea_temperature_c'], 27.5),
      waveHeightM: _num(json['wave_height_m'], 0.8),
      wavePeriodS: _num(json['wave_period_s'], 7.0),
      waveDirectionDeg: _num(json['wave_direction_deg']),
      windSpeedKts: _num(json['wind_speed_kts'], 10),
      windDirectionDeg: _num(json['wind_direction_deg'], 125),
      currentSpeedKts: _num(json['current_speed_kts']),
      currentDirectionDeg: _num(json['current_direction_deg']),
      visibilityKm: json['visibility_km'] == null
          ? null
          : _num(json['visibility_km']),
      seaStateBand: seaState is Map
          ? (seaState['band'] as String? ?? 'unknown')
          : 'unknown',
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
        'wave_direction_deg': waveDirectionDeg,
        'wind_speed_kts': windSpeedKts,
        'wind_direction_deg': windDirectionDeg,
        'current_speed_kts': currentSpeedKts,
        'current_direction_deg': currentDirectionDeg,
        'visibility_km': visibilityKm,
        'sea_state': {'band': seaStateBand},
        'tide_state': tideState,
        'tide_height_m': tideHeightM,
        'fetched_at': lastUpdated.toUtc().toIso8601String(),
        'cached': isCached,
      };
}
