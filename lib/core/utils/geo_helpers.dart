import 'dart:math' as math;

/// Geolocation and nautical distance calculations for the Oman coastline.
class GeoHelpers {
  GeoHelpers._();

  static const double _earthRadiusKm = 6371.0;

  /// Approximate bounding box of Oman's Exclusive Economic Zone, covering the
  /// Sea of Oman, the Arabian Sea and Omani territorial waters. Used as a
  /// cheap first-pass "are we in Omani waters" check before any exact
  /// polygon test.
  static const double eezMinLat = 16.0;
  static const double eezMaxLat = 26.5;
  static const double eezMinLng = 51.0;
  static const double eezMaxLng = 61.5;

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
  static double _toDegrees(double radians) => radians * 180.0 / math.pi;

  /// Great-circle distance in kilometres between two coordinates.
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Distance in nautical miles — the standard unit for marine navigation.
  static double haversineNm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      haversineKm(lat1, lng1, lat2, lng2) * 0.539957;

  /// Initial bearing (forward azimuth) in degrees, 0–360 clockwise from north.
  static double bearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = _toRadians(lng2 - lng1);
    final y = math.sin(dLng) * math.cos(_toRadians(lat2));
    final x = math.cos(_toRadians(lat1)) * math.sin(_toRadians(lat2)) -
        math.sin(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.cos(dLng);
    final theta = math.atan2(y, x);
    return (_toDegrees(theta) + 360) % 360;
  }

  /// 16-point compass label for a bearing in degrees.
  static String compass(double bearingDegrees) {
    const points = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final index = ((bearingDegrees / 22.5) + 0.5).floor() % 16;
    return points[index];
  }

  /// Fast bounding-box check against Oman's EEZ envelope.
  static bool isWithinOmanEez(double lat, double lng) {
    return lat >= eezMinLat &&
        lat <= eezMaxLat &&
        lng >= eezMinLng &&
        lng <= eezMaxLng;
  }

  /// Ray-casting point-in-polygon test. [polygon] is a list of `[lat, lng]`
  /// pairs. Useful for exact protected-area / reserve boundary checks.
  static bool isInsidePolygon(
    double lat,
    double lng,
    List<List<double>> polygon,
  ) {
    if (polygon.length < 3) return false;
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final yi = polygon[i][0], xi = polygon[i][1];
      final yj = polygon[j][0], xj = polygon[j][1];
      final intersect = ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// Destination coordinate `[lat, lng]` reached by travelling
  /// [distanceKm] along [bearingDegrees] from a start point. Handy for
  /// projecting a heading onto the chart.
  static List<double> destination(
    double lat,
    double lng,
    double bearingDegrees,
    double distanceKm,
  ) {
    final angular = distanceKm / _earthRadiusKm;
    final bearingRad = _toRadians(bearingDegrees);
    final latRad = _toRadians(lat);
    final lngRad = _toRadians(lng);

    final destLat = math.asin(
      math.sin(latRad) * math.cos(angular) +
          math.cos(latRad) * math.sin(angular) * math.cos(bearingRad),
    );
    final destLng = lngRad +
        math.atan2(
          math.sin(bearingRad) * math.sin(angular) * math.cos(latRad),
          math.cos(angular) - math.sin(latRad) * math.sin(destLat),
        );

    return [_toDegrees(destLat), (_toDegrees(destLng) + 540) % 360 - 180];
  }
}
