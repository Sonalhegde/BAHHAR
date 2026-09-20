import 'package:flutter_test/flutter_test.dart';

import 'package:bahhar/core/models/marine_conditions.dart';

/// A payload shaped exactly like `backend/main.py::marine_conditions` returns, so a
/// contract change upstream has to break something here.
Map<String, dynamic> _payload({Object? visibilityKm = 8.0}) => {
      'sea_temperature_c': 28.4,
      'wave_height_m': 1.6,
      'wave_period_s': 6.5,
      'wave_direction_deg': 135.0,
      'wind_speed_kts': 12.0,
      'wind_direction_deg': 315.0,
      'current_speed_kts': 2.3,
      'current_direction_deg': 90.0,
      'visibility_km': visibilityKm,
      'sea_state': {'band': 'strong_current', 'wind_raw': 12.0},
      'tide_state': 'Rising',
      'tide_height_m': 1.8,
      'fetched_at': '2026-09-20T05:30:00.000Z',
      'cached': false,
    };

void main() {
  group('MarineConditions.fromJson', () {
    test('reads the wave, current and visibility fields the proxy sends', () {
      final c = MarineConditions.fromJson(_payload());

      expect(c.waveDirectionDeg, 135.0);
      expect(c.currentSpeedKts, 2.3);
      expect(c.currentDirectionDeg, 90.0);
      expect(c.visibilityKm, 8.0);
      expect(c.seaStateBand, 'strong_current');
      expect(c.tideState, 'Rising');
      expect(c.isCached, isFalse);
    });

    test('accepts numbers that arrive as strings', () {
      // WorldTides and some cached Firestore documents hand back text.
      final c = MarineConditions.fromJson({
        ..._payload(),
        'wave_height_m': '1.6',
        'current_speed_kts': '0.4',
        'visibility_km': '9',
      });

      expect(c.waveHeightM, 1.6);
      expect(c.currentSpeedKts, 0.4);
      expect(c.visibilityKm, 9.0);
    });

    test('keeps an unreported visibility as null, never as zero', () {
      final c = MarineConditions.fromJson(_payload(visibilityKm: null));

      expect(c.visibilityKm, isNull);
    });

    test('defaults a payload with no visibility key at all to null', () {
      final json = _payload()..remove('visibility_km');
      final c = MarineConditions.fromJson(json);

      expect(c.visibilityKm, isNull);
    });

    test('falls back to a missing-value band, not a guessed one', () {
      final json = _payload()..remove('sea_state');
      final c = MarineConditions.fromJson(json);

      expect(c.seaStateBand, 'unknown');
      expect(c.isRough, isFalse);
    });
  });

  group('MarineConditions — direction conventions', () {
    test('wave and wind carry separate bearings', () {
      // A SE swell under a NW wind is an ordinary morning on this coast; one field
      // cannot stand in for the other.
      final c = MarineConditions.fromJson(_payload());

      expect(c.waveDirectionCompass, 'SE');
      expect(c.windDirectionCompass, 'NW');
    });

    test('the current is worded as the direction it sets toward', () {
      final c = MarineConditions.fromJson(_payload());

      expect(c.currentSetsToCompass, 'E');
    });

    test('compass rounds across all sixteen points and wraps at 360', () {
      expect(MarineConditions.compass(0), 'N');
      expect(MarineConditions.compass(360), 'N');
      expect(MarineConditions.compass(359), 'N');
      expect(MarineConditions.compass(11.25), 'NNE');
      expect(MarineConditions.compass(45), 'NE');
      expect(MarineConditions.compass(90), 'E');
      expect(MarineConditions.compass(180), 'S');
      expect(MarineConditions.compass(270), 'W');
    });
  });

  group('MarineConditions — sea state reading', () {
    MarineConditions c(String band) =>
        MarineConditions.fromJson({..._payload(), 'sea_state': {'band': band}});

    test('rough sea and high risk both mean the water changes the plan', () {
      expect(c('rough_sea').isRough, isTrue);
      expect(c('high_risk').isRough, isTrue);
    });

    test('a strong current is its own warning, not a rough sea', () {
      expect(c('strong_current').isRough, isFalse);
      expect(c('strong_current').seaStateBand, 'strong_current');
    });

    test('calm bands are not rough', () {
      expect(c('good').isRough, isFalse);
      expect(c('moderate').isRough, isFalse);
    });
  });

  group('MarineConditions — serialisation', () {
    test('survives a JSON round trip with every field intact', () {
      final original = MarineConditions.fromJson(_payload());
      final restored = MarineConditions.fromJson(original.toJson());

      expect(restored.seaTemperatureC, original.seaTemperatureC);
      expect(restored.waveHeightM, original.waveHeightM);
      expect(restored.wavePeriodS, original.wavePeriodS);
      expect(restored.waveDirectionDeg, original.waveDirectionDeg);
      expect(restored.windSpeedKts, original.windSpeedKts);
      expect(restored.windDirectionDeg, original.windDirectionDeg);
      expect(restored.currentSpeedKts, original.currentSpeedKts);
      expect(restored.currentDirectionDeg, original.currentDirectionDeg);
      expect(restored.visibilityKm, original.visibilityKm);
      expect(restored.seaStateBand, original.seaStateBand);
      expect(restored.tideState, original.tideState);
      expect(restored.tideHeightM, original.tideHeightM);
    });

    test('the round trip keeps an unreported visibility unreported', () {
      final original = MarineConditions.fromJson(_payload(visibilityKm: null));

      expect(MarineConditions.fromJson(original.toJson()).visibilityKm, isNull);
    });

    test('copyWith relabels cache state and nothing else', () {
      final original = MarineConditions.fromJson(_payload());
      final cached = original.copyWith(isCached: true);

      expect(cached.isCached, isTrue);
      expect(cached.waveDirectionDeg, original.waveDirectionDeg);
      expect(cached.currentSpeedKts, original.currentSpeedKts);
      expect(cached.visibilityKm, original.visibilityKm);
      expect(cached.seaStateBand, original.seaStateBand);
    });
  });
}
