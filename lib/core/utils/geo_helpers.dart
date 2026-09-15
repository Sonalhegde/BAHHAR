import 'dart:math' as math;

/// Geolocation and nautical distance calculations
class GeoHelpers {
  GeoHelpers._();

  /// Earth's radius in kilometers
  static const double earthRadiusKm = 6371.0;
  
  /// Earth's radius in nautical miles
  static const double earthRadiusNmi = 3440.065;

  /// Oman Exclusive Economic Zone (EEZ) boundaries
  /// Approximate coordinates for validation
  static const double omanMinLat = 16.0;  // Southern tip (Dhofar)
  static const double omanMaxLat = 26.5;  // Northern tip (Musandam)
  static const double omanMinLon = 52.0;  // Western boundary
  static const double omanMaxLon = 60.0;  // Eastern boundary

  /// Calculates distance between two points using Haversine formula
  /// Returns distance in kilometers
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculates distance between two points in nautical miles
  static double haversineNmi(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return haversineKm(lat1, lon1, lat2, lon2) * 0.539957;
  }

  /// Calculates initial bearing between two points
  /// Returns bearing in degrees (0-360)
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final bearing = _radiansToDegrees(math.atan2(y, x));
    return (bearing + 360) % 360;
  }

  /// Converts bearing to compass direction (N, NE, E, SE, S, SW, W, NW)
  static String bearingToCompass(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Calculates destination point given start point, bearing, and distance
  /// Distance in kilometers
  /// Returns [latitude, longitude]
  static List<double> calculateDestination(
    double lat,
    double lon,
    double bearing,
    double distanceKm,
  ) {
    final latRad = _degreesToRadians(lat);
    final lonRad = _degreesToRadians(lon);
    final bearingRad = _degreesToRadians(bearing);
    final angularDistance = distanceKm / earthRadiusKm;

    final lat2 = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
          math.cos(latRad) * math.sin(angularDistance) * math.cos(bearingRad),
    );

    final lon2 = lonRad +
        math.atan2(
          math.sin(bearingRad) * math.sin(angularDistance) * math.cos(latRad),
          math.cos(angularDistance) - math.sin(latRad) * math.sin(lat2),
        );

    return [
      _radiansToDegrees(lat2),
      _radiansToDegrees(lon2),
    ];
  }

  /// Checks if coordinates are within Oman's territorial waters
  static bool isWithinOmanEEZ(double lat, double lon) {
    return lat >= omanMinLat &&
        lat <= omanMaxLat &&
        lon >= omanMinLon &&
        lon <= omanMaxLon;
  }

  /// Checks if coordinates are within Oman's coastal waters (12nm from shore)
  /// This is a simplified check - actual implementation would need coastline data
  static bool isWithinOmanCoastalWaters(double lat, double lon) {
    // Simplified: check if within EEZ bounds
    // In production, this would check actual distance from coastline
    return isWithinOmanEEZ(lat, lon);
  }

  /// Calculates the midpoint between two coordinates
  static List<double> calculateMidpoint(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final lat1Rad = _degreesToRadians(lat1);
    final lon1Rad = _degreesToRadians(lon1);
    final lat2Rad = _degreesToRadians(lat2);
    final dLon = _degreesToRadians(lon2 - lon1);

    final bx = math.cos(lat2Rad) * math.cos(dLon);
    final by = math.cos(lat2Rad) * math.sin(dLon);

    final lat3 = math.atan2(
      math.sin(lat1Rad) + math.sin(lat2Rad),
      math.sqrt((math.cos(lat1Rad) + bx) * (math.cos(lat1Rad) + bx) + by * by),
    );
    final lon3 = lon1Rad + math.atan2(by, math.cos(lat1Rad) + bx);

    return [
      _radiansToDegrees(lat3),
      _radiansToDegrees(lon3),
    ];
  }

  /// Converts degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Converts radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  /// Calculates bounds (bounding box) for a given center point and radius
  /// Returns [minLat, minLon, maxLat, maxLon]
  static List<double> calculateBounds(
    double centerLat,
    double centerLon,
    double radiusKm,
  ) {
    // Approximate degrees per km at given latitude
    final latDegPerKm = 1 / 110.574;
    final lonDegPerKm = 1 / (111.320 * math.cos(_degreesToRadians(centerLat)));

    final latDelta = radiusKm * latDegPerKm;
    final lonDelta = radiusKm * lonDegPerKm;

    return [
      centerLat - latDelta, // minLat
      centerLon - lonDelta, // minLon
      centerLat + latDelta, // maxLat
      centerLon + lonDelta, // maxLon
    ];
  }

  /// Checks if a point is within a circular area
  static bool isWithinRadius(
    double centerLat,
    double centerLon,
    double pointLat,
    double pointLon,
    double radiusKm,
  ) {
    final distance = haversineKm(centerLat, centerLon, pointLat, pointLon);
    return distance <= radiusKm;
  }
}
