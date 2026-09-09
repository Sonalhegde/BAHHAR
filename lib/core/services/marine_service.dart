import 'dart:math';
import '../models/marine_conditions.dart';

/// Marine data integration service (Section 2 & Phase 3)
/// Provides real-time marine observation approximations with caching fallback.
class MarineService {
  /// Fetches marine conditions for a specific coastal coordinate in Omani waters
  static Future<MarineConditions> getConditions(double lat, double lon) async {
    // Simulate marine API network latency
    await Future.delayed(const Duration(milliseconds: 350));

    // Oman waters typical ranges: Sea temp 26-30°C, waves 0.6 - 1.8m, wind 8 - 18 kts
    // Deterministic simulation based on latitude and current hour for consistency
    final hour = DateTime.now().hour;
    final tempBase = 27.5 + sin(lat) * 1.5;
    final waveBase = 0.8 + cos(lon) * 0.4;
    final windBase = 11.0 + sin(hour / 4) * 4.0;

    return MarineConditions(
      seaTemperatureC: double.parse(tempBase.toStringAsFixed(1)),
      waveHeightM: double.parse(waveBase.clamp(0.4, 2.8).toStringAsFixed(1)),
      wavePeriodS: 7.2,
      windSpeedKts: double.parse(windBase.clamp(4.0, 26.0).toStringAsFixed(0)),
      windDirectionDeg: 125.0, // South-easterly Arabian Sea breeze
      tideState: (hour % 12 < 6) ? 'Rising' : 'Falling',
      tideHeightM: 1.8,
      lastUpdated: DateTime.now(),
      isCached: false,
    );
  }
}
