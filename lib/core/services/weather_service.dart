import '../models/weather_conditions.dart';
import 'api_client.dart';

/// Atmospheric weather service — the non-marine half of the same dashboard.
///
/// Fetches from the FastAPI proxy (`/api/v1/weather`), which resolves the provider
/// server-side: AccuWeather when a key is configured, live keyless Open-Meteo
/// otherwise, and a documented sample shape if neither answers. No provider key is
/// ever held by this client, and this client never renders a number the proxy did not
/// send — `source` travels with the payload so a sample can be labelled as one.
///
/// Offline behaviour mirrors MarineService exactly: on network failure the last-known
/// response is replayed with `isCached = true`, so the card shows its "last updated"
/// stamp instead of an error.
class WeatherService {
  WeatherService({ApiClient? apiClient})
      : _api = apiClient ??
            ApiClient(
              baseUrl: const String.fromEnvironment(
                'ML_API_BASE_URL',
                defaultValue: 'http://localhost:8000',
              ),
            );

  final ApiClient _api;

  static WeatherConditions? _lastKnown;

  /// Live data older than this is presented as stale even when the fetch succeeded,
  /// because the proxy caches per region and a hot afternoon changes faster than that.
  static const Duration staleAfter = Duration(hours: 1);

  static WeatherConditions? get lastKnown => _lastKnown;

  Future<WeatherConditions> getConditions(double lat, double lon,
      {String region = 'Muscat'}) async {
    try {
      final json = await _api.get(
        '/api/v1/weather?lat=${lat.toStringAsFixed(4)}'
        '&lon=${lon.toStringAsFixed(4)}'
        '&region=${Uri.encodeQueryComponent(region)}',
        timeout: const Duration(seconds: 15),
      );
      final conditions = WeatherConditions.fromJson(json);
      _lastKnown = conditions;
      return conditions;
    } on ApiException {
      final fallback = _lastKnown;
      if (fallback != null) return fallback.copyWith(isCached: true);
      rethrow;
    }
  }

  static bool isStale(WeatherConditions conditions) =>
      conditions.isCached ||
      DateTime.now().difference(conditions.lastUpdated) > staleAfter;

  /// Whether the reading is a provider sample rather than a measurement. The card says
  /// so on its face; a demo number must not be able to pass as live data.
  static bool isSample(WeatherConditions conditions) =>
      conditions.source == 'mock';

  static void clearCache() => _lastKnown = null;
}
