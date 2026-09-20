import 'dart:math' as math;

import '../models/hotspot_model.dart';
import '../services/api_client.dart';
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

  /// Why the optimiser ranked this spot first, as codes (`species_match`,
  /// `sea_state_rough_sea`, `no_viable_option`…). Codes and not sentences because
  /// this app is bilingual: the wording is the client's job — and that wording table
  /// has not been written, so no screen reads these yet. They travel with the plan so
  /// the sentences can be added without another round trip.
  final List<String> reasons;

  /// How the ranking was produced, in the backend's own words. Null when the local
  /// heuristic produced the plan. Server prose, so it is not printed as-is in an
  /// Arabic app — it is kept for the debug console and the same reason table above.
  final String? strategy;

  /// True when every candidate tripped one of the boat's own limits (outside the
  /// radius, or over budget) and this is the least-impossible option rather than a
  /// plan the boat can actually sail.
  final bool noViableOption;

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
    this.reasons = const [],
    this.strategy,
    this.noViableOption = false,
  });
}

/// Trip planning orchestrator.
///
/// Ranks the hotspot catalogue through the backend's `/api/v1/trip/optimize`, which is
/// the only version of this that knows what the water is actually doing. When the
/// backend is unreachable the older on-device ranking runs instead, and the result is
/// labelled `isMock` so the screen can say so — a plan computed without sea conditions
/// must never arrive looking like one that had them.
class TripService {
  TripService({ApiClient? apiClient})
      : _api = apiClient ??
            ApiClient(
              baseUrl: const String.fromEnvironment(
                'ML_API_BASE_URL',
                defaultValue: 'http://localhost:8000',
              ),
            );

  final ApiClient _api;

  /// Plans a trip for [request] using the given candidate hotspots.
  Future<TripRecommendation> planTrip(
    TripRequest request,
    List<HotspotModel> hotspots,
  ) async {
    final boat = _boatProfileFor(request.vesselType);
    try {
      final plan = await _planRemotely(request, hotspots, boat);
      if (plan != null) return plan;
    } on ApiException {
      // No backend, no verdict: fall through to the on-device ranking.
    }
    return _planLocally(request, hotspots, boat);
  }

  /// Asks the backend to rank [hotspots] against live conditions.
  ///
  /// Returns null when the answer is unusable (no recommendation, or one naming a
  /// spot this build's catalogue does not contain) rather than guessing at a plan.
  Future<TripRecommendation?> _planRemotely(
      TripRequest request, List<HotspotModel> hotspots, BoatProfile boat) async {
    if (hotspots.isEmpty) return null;
    final body = {
      'target_species': request.targetSpecies,
      'departure_lat': request.departureLat,
      'departure_lon': request.departureLon,
      'max_radius_nmi': request.maxRadiusNmi,
      'max_budget_omr': request.maxBudgetOmr,
      'duration_hours': request.durationHours,
      // Boat economics come from the app's own table, so the server prices the trip
      // with the same figures the fuel screen prints rather than a second copy of them.
      'cruising_speed_kts': boat.cruisingSpeedKnots,
      'liters_per_nmi': boat.litersPerNauticalMile,
      'candidates': hotspots
          .map((h) => {
                'id': h.id,
                'name': h.name,
                'latitude': h.latitude,
                'longitude': h.longitude,
                'depth_meters': h.depthMeters,
                'probability': h.probability,
                'target_species': h.targetSpecies,
              })
          .toList(),
    };

    final res = await _api.post('/api/v1/trip/optimize',
        body: body, timeout: const Duration(seconds: 20));
    final recommended = res['recommended'];
    if (recommended is! Map) return null;
    final id = recommended['id'] as String?;
    HotspotModel? spot;
    for (final h in hotspots) {
      if (h.id == id) {
        spot = h;
        break;
      }
    }
    if (spot == null) return null;
    final hotspot = spot;

    double d(String key, double fallback) =>
        recommended[key] is num ? (recommended[key] as num).toDouble() : fallback;

    // The server ranks; the fisherman-friendly strike number stays the app's own,
    // now fed with the live readings the ranking was scored against instead of the
    // standing assumptions the local heuristic carries.
    final conditions = res['conditions'];
    // The backend still answers when it could not reach the water, and says so by
    // sending no conditions at all. A ranking that flew blind is the offline case as
    // far as the fisherman is concerned, whatever URL produced it.
    final flewBlind = conditions is! Map;
    final probability = MLPredictionService.predictStrikeProbability(
      species: request.targetSpecies,
      seaTempC: _asDouble(conditions, 'sea_temperature_c', 26.5),
      windSpeedKts: _asDouble(conditions, 'wind_speed_kts', 12),
      waveHeightM: _asDouble(conditions, 'wave_height_m', 1.0),
      tideState: _asString(conditions, 'tide_state', 'Rising'),
      depthMeters: hotspot.depthMeters,
    ).probability;

    return TripRecommendation(
      hotspot: hotspot,
      // The server reports the one-way crossing and the round trip separately; the
      // card has always shown the round trip, which is what the fuel is for.
      distanceNm: d('round_trip_nm', d('distance_nm', 0) * 2),
      estimatedFuelLiters: d('fuel_liters', 0),
      estimatedCostOmr: d('cost_omr', 0),
      travelMinutes: d('travel_minutes', 0).round(),
      probability: probability,
      departurePort: request.departurePort,
      departureSlotLabel: request.departureSlotLabel,
      recommendedTackle: _tackleFor(request.targetSpecies),
      targetDepthRange: _depthRangeFor(hotspot.depthMeters),
      waypoints: _waypointsFor(
          request, hotspot, d('travel_minutes', 0).round()),
      isMock: flewBlind,
      reasons: (recommended['reasons'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      strategy: res['strategy'] as String?,
      noViableOption: recommended['fallback'] == true,
    );
  }

  static double _asDouble(Object? map, String key, double fallback) {
    if (map is Map && map[key] is num) return (map[key] as num).toDouble();
    return fallback;
  }

  static String _asString(Object? map, String key, String fallback) {
    if (map is Map && map[key] is String) return map[key] as String;
    return fallback;
  }

  /// The original on-device ranking: the catalogue's static probability, plus species
  /// and depth affinity, minus distance. It has no water in it, which is precisely why
  /// the backend exists; it stays as the offline path.
  TripRecommendation _planLocally(
      TripRequest request, List<HotspotModel> hotspots, BoatProfile boat) {
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
