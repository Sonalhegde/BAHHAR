import 'dart:math' as math;

import '../models/hotspot_model.dart';
import '../services/fuel_calculator_service.dart';
import '../services/ml_prediction_service.dart';

/// Everything the trip planner wizard collects.
class TripRequest {
  final String targetSpecies;
  final String departurePort;
  final double departureLat;
  final double departureLon;
  final DateTime departureTime;
  final String departureSlotLabel;
  final String vesselType;
  final int maxRadiusNmi;
  final int durationHours;
  final double maxBudgetOmr;

  const TripRequest({
    required this.targetSpecies,
    required this.departurePort,
    required this.departureLat,
    required this.departureLon,
    required this.departureTime,
    this.departureSlotLabel = '05:00 AM (Dawn Slack)',
    this.vesselType = 'Fiberglass Skiff 24-28ft',
    this.maxRadiusNmi = 15,
    this.durationHours = 6,
    this.maxBudgetOmr = 35.0,
  });

  TripRequest copyWith({
    String? targetSpecies,
    String? departurePort,
    double? departureLat,
    double? departureLon,
    DateTime? departureTime,
    String? departureSlotLabel,
    String? vesselType,
    int? maxRadiusNmi,
    int? durationHours,
    double? maxBudgetOmr,
  }) {
    return TripRequest(
      targetSpecies: targetSpecies ?? this.targetSpecies,
      departurePort: departurePort ?? this.departurePort,
      departureLat: departureLat ?? this.departureLat,
      departureLon: departureLon ?? this.departureLon,
      departureTime: departureTime ?? this.departureTime,
      departureSlotLabel: departureSlotLabel ?? this.departureSlotLabel,
      vesselType: vesselType ?? this.vesselType,
      maxRadiusNmi: maxRadiusNmi ?? this.maxRadiusNmi,
      durationHours: durationHours ?? this.durationHours,
      maxBudgetOmr: maxBudgetOmr ?? this.maxBudgetOmr,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetSpecies': targetSpecies,
        'departurePort': departurePort,
        'departureLat': departureLat,
        'departureLon': departureLon,
        'departureTime': departureTime.toIso8601String(),
        'departureSlotLabel': departureSlotLabel,
        'vesselType': vesselType,
        'maxRadiusNmi': maxRadiusNmi,
        'durationHours': durationHours,
        'maxBudgetOmr': maxBudgetOmr,
      };
}

class TripWaypoint {
  final String time;
  final String title;
  final String subtitle;

  const TripWaypoint({
    required this.time,
    required this.title,
    required this.subtitle,
  });
}

/// The planner's output for the recommendation screen.
class TripRecommendation {
  final HotspotModel hotspot;
  final double distanceNm;
  final double estimatedFuelLiters;
  final double estimatedCostOmr;
  final int travelMinutes;
  final int probability;
  final String departurePort;
  final String departureSlotLabel;
  final String recommendedTackle;
  final String targetDepthRange;
  final List<TripWaypoint> waypoints;
  final bool isMock;

  const TripRecommendation({
    required this.hotspot,
    required this.distanceNm,
    required this.estimatedFuelLiters,
    required this.estimatedCostOmr,
    required this.travelMinutes,
    required this.probability,
    required this.departurePort,
    required this.departureSlotLabel,
    required this.recommendedTackle,
    required this.targetDepthRange,
    required this.waypoints,
    this.isMock = true,
  });
}

/// Trip planning orchestrator.
class TripService {
  /// Plans a trip for [request] using the given candidate hotspots.
  ///
  // TODO(ml-backend): replace the heuristic below with a call to the real ML
  // trip-planning endpoint once it exists, e.g.:
  //   final res = await ApiClient().post('/v1/trips/plan', body: request.toJson());
  //   return TripRecommendation.fromJson(res.data);
  // Until then this returns a deterministic, believable mock so the UI is
  // testable end to end (probability from MLPredictionService + fuel burn
  // from FuelCalculatorService against the real hotspot catalogue).
  Future<TripRecommendation> planTrip(
    TripRequest request,
    List<HotspotModel> hotspots,
  ) async {
    final boat = _boatProfileFor(request.vesselType);

    // Candidates within the user's cruising radius and budget.
    final candidates = <(HotspotModel, double, double, double, int)>[];
    for (final h in hotspots) {
      final (dist, fuel, cost, minutes) = FuelCalculatorService.calculateTrip(
        startLat: request.departureLat,
        startLon: request.departureLon,
        destLat: h.latitude,
        destLon: h.longitude,
        boat: boat,
      );
      if (dist <= request.maxRadiusNmi && cost <= request.maxBudgetOmr) {
        candidates.add((h, dist, fuel, cost, minutes));
      }
    }

    // Fall back to the closest hotspot when nothing fits radius/budget, so
    // the recommendation screen always has something meaningful to show.
    if (candidates.isEmpty) {
      final nearest = _nearest(hotspots, request);
      final (dist, fuel, cost, minutes) = FuelCalculatorService.calculateTrip(
        startLat: request.departureLat,
        startLon: request.departureLon,
        destLat: nearest.latitude,
        destLon: nearest.longitude,
        boat: boat,
      );
      candidates.add((nearest, dist, fuel, cost, minutes));
    }

    // Rank by species match first, then ML-flavoured probability.
    (HotspotModel, double, double, double, int)? best;
    var bestScore = -1.0;
    for (final c in candidates) {
      final h = c.$1;
      final speciesMatch =
          h.targetSpecies.any((s) => _sameSpecies(s, request.targetSpecies))
              ? 25.0
              : 0.0;
      final depthBonus = _depthAffinity(request.targetSpecies, h.depthMeters);
      final score = speciesMatch + depthBonus + h.probability;
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }

    final (hotspot, dist, fuel, cost, minutes) = best!;
    final probability = MLPredictionService.predictStrikeProbability(
      species: request.targetSpecies,
      seaTempC: 26.5,
      windSpeedKts: 12,
      waveHeightM: 1.0,
      tideState: 'Rising',
      depthMeters: hotspot.depthMeters,
    ).probability;

    return TripRecommendation(
      hotspot: hotspot,
      distanceNm: dist,
      estimatedFuelLiters: fuel,
      estimatedCostOmr: cost,
      travelMinutes: minutes,
      probability: probability,
      departurePort: request.departurePort,
      departureSlotLabel: request.departureSlotLabel,
      recommendedTackle: _tackleFor(request.targetSpecies),
      targetDepthRange: _depthRangeFor(hotspot.depthMeters),
      waypoints: _waypointsFor(request, hotspot, minutes),
    );
  }

  HotspotModel _nearest(
      List<HotspotModel> hotspots, TripRequest request) {
    HotspotModel? nearest;
    var bestDist = double.infinity;
    for (final h in hotspots) {
      final d = _haversineKm(
          request.departureLat, request.departureLon, h.latitude, h.longitude);
      if (d < bestDist) {
        bestDist = d;
        nearest = h;
      }
    }
    return nearest ?? hotspots.first;
  }

  double _haversineKm(lat1, lon1, lat2, lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  BoatProfile _boatProfileFor(String vesselType) {
    final v = vesselType.toLowerCase();
    if (v.contains('dhow')) {
      return FuelCalculatorService.availableBoats[2];
    }
    if (v.contains('cruiser') || v.contains('32ft')) {
      return FuelCalculatorService.availableBoats[1];
    }
    return FuelCalculatorService.availableBoats[0];
  }

  bool _sameSpecies(String a, String b) {
    String norm(String s) => s.toLowerCase().split('(').first.trim();
    return norm(a) == norm(b) || norm(b).contains(norm(a)) || norm(a).contains(norm(b));
  }

  double _depthAffinity(String species, int depthMeters) {
    final s = species.toLowerCase();
    if ((s.contains('tuna') || s.contains('sailfish')) && depthMeters > 40) {
      return 10;
    }
    if ((s.contains('grouper') || s.contains('hamoor')) && depthMeters > 25) {
      return 10;
    }
    return 0;
  }

  String _tackleFor(String species) {
    final s = species.toLowerCase();
    if (s.contains('tuna') || s.contains('kingfish') || s.contains('kanaad')) {
      return 'Trolling 40lb';
    }
    if (s.contains('grouper') || s.contains('hamoor')) return 'Deep Drop Jig';
    if (s.contains('mahi') || s.contains('sailfish')) return 'Trolling 30lb';
    return 'Popper / Topwater';
  }

  String _depthRangeFor(int depth) {
    final low = math.max(5, (depth * 0.8).round());
    final high = (depth * 1.2).round();
    return '$low - $high m';
  }

  List<TripWaypoint> _waypointsFor(
      TripRequest request, HotspotModel hotspot, int travelMinutes) {
    final t = request.departureTime;
    String fmt(DateTime dt) =>
        '${dt.hour == 12 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour < 12 ? 'AM' : 'PM'}';

    final arrive = t.add(Duration(minutes: travelMinutes));
    final shift = arrive.add(const Duration(hours: 2, minutes: 30));
    final returnT = t.add(Duration(hours: request.durationHours));

    return [
      TripWaypoint(
        time: fmt(t),
        title: 'Depart ${request.departurePort}',
        subtitle: 'Heading to ${hotspot.name} • ${hotspot.bestWindow} bite window',
      ),
      TripWaypoint(
        time: fmt(arrive),
        title: 'Arrive at ${hotspot.name} Drop-off',
        subtitle: 'Begin drift for ${request.targetSpecies}',
      ),
      TripWaypoint(
        time: fmt(shift),
        title: 'Work the ${hotspot.depthMeters}m contour',
        subtitle: 'Jigging window during slack tide',
      ),
      TripWaypoint(
        time: fmt(returnT),
        title: 'Return cruise to port',
        subtitle: 'Fuel reserve checked before departure',
      ),
    ];
  }
}
