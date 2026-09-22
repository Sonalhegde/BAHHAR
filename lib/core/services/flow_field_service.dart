import '../models/flow_field.dart';
import 'api_client.dart';

/// Wind/current grid service — feeds the map's particle-flow layer.
///
/// Fetches the whole Gulf-of-Oman U/V grid from the backend proxy
/// (`/api/v1/wind-field`), which batches Open-Meteo multi-point queries
/// server-side and caches the result on the model refresh cadence. One
/// request covers every particle on screen: no per-point calls.
///
/// Offline behaviour matches MarineService: on network failure the last
/// known grid is replayed so the layer keeps drawing instead of vanishing
/// mid-trip; the grid's own [FlowField.isStale] tells the UI when a
/// refetch is due.
class FlowFieldService {
  FlowFieldService({ApiClient? apiClient})
      : _api = apiClient ??
            ApiClient(
              baseUrl: const String.fromEnvironment(
                'ML_API_BASE_URL',
                defaultValue: 'http://localhost:8000',
              ),
            );

  final ApiClient _api;

  static FlowField? _lastKnown;

  static FlowField? get lastKnown => _lastKnown;

  /// Fetches the wind + current grid; falls back to the last good one.
  Future<FlowField> getFlowField() async {
    try {
      final json = await _api.get(
        '/api/v1/wind-field?fields=wind,current',
        timeout: const Duration(seconds: 20),
      );
      final field = FlowField.fromJson(json);
      if (!field.hasAny) throw ApiException('wind-field: empty body');
      _lastKnown = field;
      return field;
    } on ApiException {
      final fallback = _lastKnown;
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  /// Clears the in-memory grid (e.g. on logout).
  static void clearCache() => _lastKnown = null;
}
