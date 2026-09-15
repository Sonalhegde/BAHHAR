import 'dart:math' as math;

/// Formatting utilities for dates, sea temperatures, wave heights, and coordinates
class Formatters {
  Formatters._();

  /// Formats temperature in Celsius with degree symbol
  /// Example: 27.5 -> "27.5°C"
  static String formatTemperature(double celsius, {int decimals = 1}) {
    return '${celsius.toStringAsFixed(decimals)}°C';
  }

  /// Formats wave height in meters
  /// Example: 1.2 -> "1.2m"
  static String formatWaveHeight(double meters, {int decimals = 1}) {
    return '${meters.toStringAsFixed(decimals)}m';
  }

  /// Formats wind speed in knots
  /// Example: 12.5 -> "12.5kts"
  static String formatWindSpeed(double knots, {int decimals = 1}) {
    return '${knots.toStringAsFixed(decimals)}kts';
  }

  /// Formats distance in nautical miles
  /// Example: 15.3 -> "15.3nmi"
  static String formatNauticalMiles(double nmi, {int decimals = 1}) {
    return '${nmi.toStringAsFixed(decimals)}nmi';
  }

  /// Formats distance in kilometers
  /// Example: 28.3 -> "28.3km"
  static String formatKilometers(double km, {int decimals = 1}) {
    return '${km.toStringAsFixed(decimals)}km';
  }

  /// Formats weight in kilograms
  /// Example: 5.75 -> "5.75kg"
  static String formatWeight(double kg, {int decimals = 2}) {
    return '${kg.toStringAsFixed(decimals)}kg';
  }

  /// Formats length in centimeters
  /// Example: 85.5 -> "85.5cm"
  static String formatLength(double cm, {int decimals = 1}) {
    return '${cm.toStringAsFixed(decimals)}cm';
  }

  /// Formats depth in meters
  /// Example: 38 -> "38m"
  static String formatDepth(int meters) {
    return '${meters}m';
  }

  /// Formats coordinates as Degrees, Minutes
  /// Example: 23.5880 -> "23°35.28'N"
  static String formatLatitude(double latitude, {int decimalMinutes = 2}) {
    final direction = latitude >= 0 ? 'N' : 'S';
    final absLat = latitude.abs();
    final degrees = absLat.floor();
    final minutes = (absLat - degrees) * 60;
    return '$degrees°${minutes.toStringAsFixed(decimalMinutes)}\'$direction';
  }

  /// Formats longitude as Degrees, Minutes
  /// Example: 58.3829 -> "58°22.97'E"
  static String formatLongitude(double longitude, {int decimalMinutes = 2}) {
    final direction = longitude >= 0 ? 'E' : 'W';
    final absLon = longitude.abs();
    final degrees = absLon.floor();
    final minutes = (absLon - degrees) * 60;
    return '$degrees°${minutes.toStringAsFixed(decimalMinutes)}\'$direction';
  }

  /// Formats coordinates as decimal degrees
  /// Example: (23.5880, 58.3829) -> "23.5880°N, 58.3829°E"
  static String formatCoordinates(double latitude, double longitude, {int decimals = 4}) {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(decimals)}°$latDir, '
           '${longitude.abs().toStringAsFixed(decimals)}°$lonDir';
  }

  /// Formats date as "15 Sep 2024"
  static String formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Formats time as "14:30"
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}';
  }

  /// Formats date and time as "15 Sep 2024, 14:30"
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)}, ${formatTime(dateTime)}';
  }

  /// Formats duration in hours and minutes
  /// Example: Duration(hours: 2, minutes: 30) -> "2h 30m"
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  /// Formats fuel consumption in liters
  /// Example: 45.5 -> "45.5L"
  static String formatFuel(double liters, {int decimals = 1}) {
    return '${liters.toStringAsFixed(decimals)}L';
  }

  /// Formats percentage
  /// Example: 0.85 -> "85%"
  static String formatPercentage(double value, {int decimals = 0}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Formats probability score
  /// Example: 75 -> "75"
  static String formatScore(int score) {
    return score.toString();
  }

  /// Converts meters to feet
  static double metersToFeet(double meters) {
    return meters * 3.28084;
  }

  /// Converts kilometers to nautical miles
  static double kmToNauticalMiles(double km) {
    return km * 0.539957;
  }

  /// Converts knots to km/h
  static double knotsToKmh(double knots) {
    return knots * 1.852;
  }
}
