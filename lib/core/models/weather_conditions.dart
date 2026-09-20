/// Atmospheric weather for one coastal position: now, the next few hours, five days.
///
/// Field set mirrors the backend `/api/v1/weather` proxy exactly. The proxy owns the
/// provider difference — AccuWeather when a key is set, live Open-Meteo when it is not,
/// a documented sample when neither is reachable — and hands every consumer the same
/// contract, so nothing here needs to know which one answered.
class WeatherHour {
  /// Local clock text ("14:00") as printed by the provider, not a parsed DateTime:
  /// the strip shows the hours ahead at the position it was requested for.
  final String time;
  final double tempC;
  final String condition;
  final double? rainProbabilityPct;

  const WeatherHour({
    required this.time,
    required this.tempC,
    required this.condition,
    this.rainProbabilityPct,
  });

  factory WeatherHour.fromJson(Map<String, dynamic> json) {
    double? num(Object? v) => v is num ? v.toDouble() : null;
    return WeatherHour(
      time: (json['time'] as String?) ?? '',
      tempC: json['temp_c'] is num
          ? (json['temp_c'] as num).toDouble()
          : 0,
      condition: (json['condition'] as String?) ?? '',
      rainProbabilityPct: num(json['rain_probability_pct']),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'temp_c': tempC,
        'condition': condition,
        'rain_probability_pct': rainProbabilityPct,
      };
}

class WeatherDay {
  /// ISO date ("2026-09-21").
  final String date;
  final double highC;
  final double lowC;
  final String condition;

  const WeatherDay({
    required this.date,
    required this.highC,
    required this.lowC,
    required this.condition,
  });

  factory WeatherDay.fromJson(Map<String, dynamic> json) => WeatherDay(
        date: (json['date'] as String?) ?? '',
        highC: json['high_c'] is num ? (json['high_c'] as num).toDouble() : 0,
        lowC: json['low_c'] is num ? (json['low_c'] as num).toDouble() : 0,
        condition: (json['condition'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'high_c': highC,
        'low_c': lowC,
        'condition': condition,
      };

  /// Short weekday label, Arabic-first because the strip is read in whichever
  /// language the app is showing. Falls back to the raw date if it will not parse.
  String weekdayLabel(bool isArabic) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const ar = ['اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
    return isArabic ? ar[parsed.weekday - 1] : en[parsed.weekday - 1];
  }
}

class WeatherAlert {
  final String title;
  final String? severity;
  final String? starts;
  final String? ends;

  const WeatherAlert({
    required this.title,
    this.severity,
    this.starts,
    this.ends,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) => WeatherAlert(
        title: (json['title'] as String?) ?? 'Weather alert',
        severity: json['severity'] as String?,
        starts: json['starts'] as String?,
        ends: json['ends'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'severity': severity,
        'starts': starts,
        'ends': ends,
      };
}

class WeatherConditions {
  final double tempC;
  final double feelsLikeC;

  /// A phrase, never a code: the backend translates WMO 4680 numbers into the same
  /// words AccuWeather sends, so the card prints one kind of sentence either way.
  final String condition;
  final double humidityPct;
  final double windKmh;

  /// Compass text for the bearing the wind comes FROM. Null when the provider sent no
  /// reading — an empty slot reads as "not measured", a guessed "N" reads as a fact.
  final String? windDir;
  final double? rainProbabilityPct;
  final double uvIndex;
  final double? visibilityKm;

  final List<WeatherHour> hourly;
  final List<WeatherDay> daily;
  final List<WeatherAlert> alerts;

  /// accuweather | open-meteo | mock. Displayed as attribution, not hidden: a sample
  /// reading must never look like a measurement.
  final String source;
  final String attribution;

  /// The provider's own explanation when it degraded. Shown verbatim rather than
  /// paraphrased, because the reason differs per provider and per failure.
  final String? note;
  final DateTime lastUpdated;
  final bool isCached;

  const WeatherConditions({
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.humidityPct,
    required this.windKmh,
    this.windDir,
    this.rainProbabilityPct,
    this.uvIndex = 0,
    this.visibilityKm,
    this.hourly = const [],
    this.daily = const [],
    this.alerts = const [],
    this.source = 'unknown',
    this.attribution = '',
    this.note,
    required this.lastUpdated,
    this.isCached = false,
  });

  /// UV banding for the badge colour. Thresholds follow the WHO index scale, which is
  /// what both providers report — the number itself always comes from upstream.
  String get uvBand {
    if (uvIndex < 3) return 'low';
    if (uvIndex < 6) return 'moderate';
    if (uvIndex < 8) return 'high';
    if (uvIndex < 11) return 'very_high';
    return 'extreme';
  }

  bool get hasAlerts => alerts.isNotEmpty;

  /// Heat stress matters on the Omani coast more than the air number alone: a 34°C day
  /// at 80% humidity is a different trip than 34°C dry.
  bool get isHot => feelsLikeC >= 40;

  WeatherConditions copyWith({bool? isCached}) => WeatherConditions(
        tempC: tempC,
        feelsLikeC: feelsLikeC,
        condition: condition,
        humidityPct: humidityPct,
        windKmh: windKmh,
        windDir: windDir,
        rainProbabilityPct: rainProbabilityPct,
        uvIndex: uvIndex,
        visibilityKm: visibilityKm,
        hourly: hourly,
        daily: daily,
        alerts: alerts,
        source: source,
        attribution: attribution,
        note: note,
        lastUpdated: lastUpdated,
        isCached: isCached ?? this.isCached,
      );

  factory WeatherConditions.fromJson(Map<String, dynamic> json) {
    double num(Object? v, [double fallback = 0]) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    double? opt(Object? v) => v == null ? null : num(v);

    final current = (json['current'] as Map?)?.cast<String, dynamic>() ?? {};
    final hourly = (json['hourly'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => WeatherHour.fromJson(e.cast<String, dynamic>()))
        .toList();
    final daily = (json['daily'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => WeatherDay.fromJson(e.cast<String, dynamic>()))
        .toList();
    final alerts = (json['alerts'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => WeatherAlert.fromJson(e.cast<String, dynamic>()))
        .toList();

    return WeatherConditions(
      tempC: num(current['temp_c']),
      feelsLikeC: num(current['feels_like_c']),
      condition: (current['condition'] as String?) ?? '',
      humidityPct: num(current['humidity_pct']),
      windKmh: num(current['wind_kmh']),
      windDir: current['wind_dir'] as String?,
      rainProbabilityPct: opt(current['rain_probability_pct']),
      uvIndex: num(current['uv_index']),
      visibilityKm: opt(current['visibility_km']),
      hourly: hourly,
      daily: daily,
      alerts: alerts,
      source: (json['source'] as String?) ?? 'unknown',
      attribution: (json['attribution'] as String?) ?? '',
      note: json['note'] as String?,
      lastUpdated:
          DateTime.tryParse(json['fetched_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      isCached: json['cached'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source,
        'attribution': attribution,
        'note': note,
        'current': {
          'temp_c': tempC,
          'feels_like_c': feelsLikeC,
          'condition': condition,
          'humidity_pct': humidityPct,
          'wind_kmh': windKmh,
          'wind_dir': windDir,
          'rain_probability_pct': rainProbabilityPct,
          'uv_index': uvIndex,
          'visibility_km': visibilityKm,
        },
        'hourly': hourly.map((e) => e.toJson()).toList(),
        'daily': daily.map((e) => e.toJson()).toList(),
        'alerts': alerts.map((e) => e.toJson()).toList(),
        'fetched_at': lastUpdated.toUtc().toIso8601String(),
        'cached': isCached,
      };
}
