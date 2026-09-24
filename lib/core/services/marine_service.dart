import '../models/marine_conditions.dart';
import '../models/tide_curve.dart';
import 'api_client.dart';

/// Marine data integration service (Master Build Prompt Section 2, 4 & Phase 3).
///
/// Fetches live aggregated conditions from the FastAPI backend proxy
/// (/api/v1/marine/conditions), which in turn calls the keyless Open-Meteo
/// weather + marine APIs and the WorldTides tide API server-side. The
/// WorldTides key never ships in this client.
///
/// Offline behaviour (Section 9): on network failure the last-known response
/// is replayed with isCached = true so the dashboard can surface a
/// "last updated" stamp instead of an error. The tide curve follows the same
/// rule with its own last-known buffer.
class MarineService {
  MarineService({ApiClient? apiClient})
      : _api = apiClient ??
            ApiClient(
              baseUrl: const String.fromEnvironment(
                'ML_API_BASE_URL',
                defaultValue: 'http://localhost:8000',
              ),
            );

  final ApiClient _api;

  /// Last known good conditions kept in memory for offline fallback.
  static MarineConditions? _lastKnown;

  /// Last known good tide curve, kept separately so a conditions refresh does
  /// not have to succeed for the chart to keep showing the last real curve.
  static TideCurve? _lastCurve;

  /// Live data older than this is presented as stale even when fetch succeeds
  /// upstream (backend cache flag).
  static const Duration staleAfter = Duration(hours: 1);

  static MarineConditions? get lastKnown => _lastKnown;
  static TideCurve? get lastTideCurve => _lastCurve;

  /// Fetches marine conditions for a specific coastal coordinate in Omani waters.
  Future<MarineConditions> getConditions(double lat, double lon) async {
    try {
      final json = await _api.get(
        '/api/v1/marine/conditions?lat=${lat.toStringAsFixed(4)}'
        '&lon=${lon.toStringAsFixed(4)}',
        timeout: const Duration(seconds: 15),
      );
      final conditions = MarineConditions.fromJson(json);
      _lastKnown = conditions;
      return conditions;
    } on ApiException {
      // Offline / upstream down: replay last-known cached data if available.
      final fallback = _lastKnown;
      if (fallback != null) return fallback.copyWith(isCached: true);
      rethrow;
    }
  }

  /// Fetches the continuous tide-height curve for a coastal coordinate.
  ///
  /// [hours] is the forward window the chart should cover (backend clamps it to
  /// 6-48). On failure the last-known curve is replayed with isCached = true; if
  /// there was never a curve the ApiException rethrows so the card can show its
  /// honest "tide curve unavailable" state rather than a fabricated line.
  Future<TideCurve> getTideCurve(double lat, double lon, {int hours = 24}) async {
    try {
      final json = await _api.get(
        '/api/v1/tides/curve?lat=${lat.toStringAsFixed(4)}'
        '&lon=${lon.toStringAsFixed(4)}&hours=$hours',
        timeout: const Duration(seconds: 15),
      );
      final curve = TideCurve.fromJson(json);
      _lastCurve = curve;
      return curve;
    } on ApiException {
      final fallback = _lastCurve;
      if (fallback != null) return fallback.copyWith(isCached: true);
      rethrow;
    }
  }

  /// Whether a set of conditions should be flagged as stale to the user.
  static bool isStale(MarineConditions conditions) =>
      conditions.isCached ||
      DateTime.now().difference(conditions.lastUpdated) > staleAfter;

  /// Clears the in-memory offline cache (e.g. on logout).
  static void clearCache() {
    _lastKnown = null;
    _lastCurve = null;
  }
}
