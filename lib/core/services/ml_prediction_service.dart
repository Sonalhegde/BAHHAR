/// ML Prediction Service Contract compliant with Section 10
class MLPredictionResult {
  final int probability; // 0 to 100
  final double confidence; // 0.0 to 1.0
  final List<String> contributingFactors;

  const MLPredictionResult({
    required this.probability,
    required this.confidence,
    required this.contributingFactors,
  });
}

class MLPredictionService {
  /// Computes species-specific strike probability given environmental features
  static MLPredictionResult predictStrikeProbability({
    required String species,
    required double seaTempC,
    required double windSpeedKts,
    required double waveHeightM,
    required String tideState,
    required int depthMeters,
  }) {
    int score = 65;
    final factors = <String>[];

    // Sea Temp analysis for Omani species
    if (species.toLowerCase().contains('kingfish') || species.toLowerCase().contains('كنعد')) {
      if (seaTempC >= 25.0 && seaTempC <= 28.5) {
        score += 15;
        factors.add('Optimal sea surface temperature (26-28°C)');
      }
    } else if (species.toLowerCase().contains('tuna') || species.toLowerCase().contains('ثمد')) {
      if (depthMeters >= 40) {
        score += 18;
        factors.add('Deep pelagic shelf presence (>40m)');
      }
    }

    // Tide correlation
    if (tideState == 'Rising') {
      score += 10;
      factors.add('Favorable flood tide driving baitfish');
    }

    // Wind & Wave safety/strike adjustment
    if (waveHeightM > 2.0) {
      score -= 20;
      factors.add('High swell impacting schooling visibility');
    } else if (windSpeedKts >= 8 && windSpeedKts <= 15) {
      score += 8;
      factors.add('Moderate surface chop stimulating bite activity');
    }

    // Gale-force winds shut the bite down on top of the swell penalty.
    if (windSpeedKts > 20) {
      score -= 10;
      factors.add('Strong winds suppressing surface feeding');
    }

    final finalScore = score.clamp(15, 95);
    return MLPredictionResult(
      probability: finalScore,
      confidence: 0.84,
      contributingFactors: factors.isEmpty ? ['Stable marine conditions'] : factors,
    );
  }
}
