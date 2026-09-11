/// Formatting utilities for dates, sea temperatures, wave heights, distances,
/// speeds and coordinates.
///
/// Metric is the default for Oman; pass `metric: false` where a screen
/// exposes an imperial preference.
class Formatters {
  Formatters._();

  static const List<String> _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Sea / air temperature. Metric shows °C, imperial converts to °F.
  static String temperature(double celsius, {bool metric = true}) {
    if (metric) return '${celsius.round()}°C';
    final f = celsius * 9 / 5 + 32;
    return '${f.round()}°F';
  }

  /// Wave / swell height. Metric shows metres, imperial shows feet.
  static String waveHeight(double meters, {bool metric = true}) {
    if (metric) return '${meters.toStringAsFixed(1)} m';
    final feet = meters * 3.28084;
    return '${feet.toStringAsFixed(1)} ft';
  }

  /// Wind / vessel speed. Knots are the marine standard in both systems.
  static String speedKnots(double knots) => '${knots.toStringAsFixed(1)} kn';

  /// Wind speed with a system-aware secondary unit (km/h or mph).
  static String windSpeed(double knots, {bool metric = true}) {
    if (metric) {
      final kmh = knots * 1.852;
      return '${kmh.round()} km/h';
    }
    final mph = knots * 1.15078;
    return '${mph.round()} mph';
  }

  /// Distance. Under 1 km metric falls back to metres; imperial uses
  /// nautical miles which are the norm for offshore navigation.
  static String distance(double kilometers, {bool metric = true}) {
    if (metric) {
      if (kilometers < 1) return '${(kilometers * 1000).round()} m';
      return '${kilometers.toStringAsFixed(1)} km';
    }
    final nm = kilometers * 0.539957;
    return '${nm.toStringAsFixed(1)} nm';
  }

  /// Depth in metres or feet.
  static String depth(double meters, {bool metric = true}) {
    if (metric) return '${meters.round()} m';
    final feet = meters * 3.28084;
    return '${feet.round()} ft';
  }

  /// Short date, e.g. `5 Mar 2026`.
  static String date(DateTime dt) =>
      '${dt.day} ${_monthsEn[dt.month - 1]} ${dt.year}';

  /// 24-hour clock, e.g. `06:45`.
  static String time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  /// Combined date and time.
  static String dateTime(DateTime dt) => '${date(dt)} · ${time(dt)}';

  /// Relative "time ago" label for logs and notifications.
  static String relative(DateTime dt, {bool isArabic = false}) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'just now';
    if (diff.inHours < 1) {
      final m = diff.inMinutes;
      return isArabic ? 'قبل $m د' : '${m}m ago';
    }
    if (diff.inDays < 1) {
      final h = diff.inHours;
      return isArabic ? 'قبل $h س' : '${h}h ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return isArabic ? 'قبل $d ي' : '${d}d ago';
    }
    return date(dt);
  }

  /// Decimal-degree coordinate pair with N/S and E/W hemispheres.
  static String coordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}°$latDir, '
        '${lng.abs().toStringAsFixed(4)}°$lngDir';
  }

  /// Masks all but the last [visible] digits of a sensitive value.
  static String maskTrailing(String value, {int visible = 4}) {
    if (value.length <= visible) return value;
    final shown = value.substring(value.length - visible);
    return '${'•' * (value.length - visible)}$shown';
  }
}
