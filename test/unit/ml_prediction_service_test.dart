import 'package:flutter_test/flutter_test.dart';
import 'package:bahhar/core/services/ml_prediction_service.dart';

void main() {
  group('MLPredictionService Tests', () {
    test('Optimal Kingfish conditions yield high probability (>70%)', () {
      final result = MLPredictionService.predictStrikeProbability(
        species: 'Kingfish',
        seaTempC: 27.2,
        windSpeedKts: 12.0,
        waveHeightM: 0.8,
        tideState: 'Rising',
        depthMeters: 38,
      );

      expect(result.probability, greaterThanOrEqualTo(75));
      expect(result.confidence, 0.84);
      expect(result.contributingFactors, isNotEmpty);
    });

    test('Dangerous swell degrades strike probability', () {
      final result = MLPredictionService.predictStrikeProbability(
        species: 'Kingfish',
        seaTempC: 27.2,
        windSpeedKts: 24.0,
        waveHeightM: 2.8,
        tideState: 'Falling',
        depthMeters: 38,
      );

      expect(result.probability, lessThan(60));
    });
  });
}
