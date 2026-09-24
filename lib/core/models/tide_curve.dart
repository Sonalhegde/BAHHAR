/// A continuous tide-height curve for one coastal position.
///
/// Mirrors the backend /api/v1/tides/curve proxy (WorldTides heights datum):
/// the rising/falling line between high and low water, not just the extremes
/// /api/v1/tides returns. Kept separate from MarineConditions because the chart
/// needs the whole series while the card only needs the instant reading.
///
/// Offline honesty: on network failure the service replays the last-known curve
/// with isCached set, exactly like the marine conditions, so a stale line is
/// never read as a live one.
class TidePoint {
  const TidePoint({required this.time, required this.heightM});

  /// Sample time, already converted to the device's local zone.
  final DateTime time;

  /// Height above chart datum, metres. Negative is normal below mean sea level.
  final double heightM;

  factory TidePoint.fromJson(Map<String, dynamic> json) => TidePoint(
        time: DateTime.tryParse(json['iso'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        heightM: (json['height_m'] as num?)?.toDouble() ?? 0,
      );
}

class TideCurve {
  const TideCurve({
    required this.station,
    required this.tideState,
    required this.currentHeightM,
    required this.hours,
    required this.points,
    required this.lastUpdated,
    this.isCached = false,
  });

  /// Nearest WorldTides station name, e.g. "PORT SULTAN QABOOS". Null if absent.
  final String? station;

  /// Rising | Falling | High | Low | Unavailable - derived server-side from the
  /// curve at request time, so the label and the drawn line cannot disagree.
  final String tideState;

  /// Height interpolated at "now", metres.
  final double currentHeightM;

  /// Window length the curve spans, hours.
  final int hours;

  /// The samples, oldest first. Empty only when the provider returned nothing.
  final List<TidePoint> points;

  final DateTime lastUpdated;
  final bool isCached;

  bool get isEmpty => points.isEmpty;
  bool get isRising => tideState == 'Rising' || tideState == 'High';

  double get minM => points.isEmpty
      ? 0
      : points.map((p) => p.heightM).reduce((a, b) => a < b ? a : b);
  double get maxM => points.isEmpty
      ? 0
      : points.map((p) => p.heightM).reduce((a, b) => a > b ? a : b);

  /// The sample nearest the wall clock, used to place the "now" marker on the line.
  TidePoint? pointAtNow({DateTime? now}) {
    if (points.isEmpty) return null;
    final reference = now ?? DateTime.now();
    return points.reduce(
      (a, b) => (a.time.difference(reference).abs() <=
              b.time.difference(reference).abs())
          ? a
          : b,
    );
  }

  factory TideCurve.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    return TideCurve(
      station: json['station'] as String?,
      tideState: (json['tide_state'] as String?) ?? 'Unavailable',
      currentHeightM: (json['tide_height_m'] as num?)?.toDouble() ?? 0,
      hours: (json['hours'] as num?)?.toInt() ?? 24,
      points: rawPoints is List
          ? rawPoints
              .whereType<Map<String, dynamic>>()
              .map(TidePoint.fromJson)
              .toList()
          : const [],
      lastUpdated:
          DateTime.tryParse(json['fetched_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      isCached: json['cached'] == true,
    );
  }

  TideCurve copyWith({bool? isCached}) => TideCurve(
        station: station,
        tideState: tideState,
        currentHeightM: currentHeightM,
        hours: hours,
        points: points,
        lastUpdated: lastUpdated,
        isCached: isCached ?? this.isCached,
      );
}
