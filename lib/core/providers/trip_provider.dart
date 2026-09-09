import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fuel_calculator_service.dart';
import '../models/hotspot_model.dart';
import 'hotspots_provider.dart';

class TripRecommendation {
  final HotspotModel hotspot;
  final double distanceNm;
  final double estimatedFuelLiters;
  final double estimatedCostOmr;
  final int travelMinutes;
  final int probability;
  final String departurePort;

  const TripRecommendation({
    required this.hotspot,
    required this.distanceNm,
    required this.estimatedFuelLiters,
    required this.estimatedCostOmr,
    required this.travelMinutes,
    required this.probability,
    required this.departurePort,
  });
}

class TripPlanState {
  final String targetSpecies;
  final String departurePort;
  final double departureLat;
  final double departureLon;
  final DateTime departureTime;
  final int durationHours;
  final BoatProfile selectedBoat;
  final double maxBudgetOmr;

  const TripPlanState({
    this.targetSpecies = 'Kingfish',
    this.departurePort = 'Marina Bandar Al Rowdha (Muscat)',
    this.departureLat = 23.5786,
    this.departureLon = 58.6083,
    required this.departureTime,
    this.durationHours = 6,
    required this.selectedBoat,
    this.maxBudgetOmr = 35.0,
  });

  TripPlanState copyWith({
    String? targetSpecies,
    String? departurePort,
    double? departureLat,
    double? departureLon,
    DateTime? departureTime,
    int? durationHours,
    BoatProfile? selectedBoat,
    double? maxBudgetOmr,
  }) {
    return TripPlanState(
      targetSpecies: targetSpecies ?? this.targetSpecies,
      departurePort: departurePort ?? this.departurePort,
      departureLat: departureLat ?? this.departureLat,
      departureLon: departureLon ?? this.departureLon,
      departureTime: departureTime ?? this.departureTime,
      durationHours: durationHours ?? this.durationHours,
      selectedBoat: selectedBoat ?? this.selectedBoat,
      maxBudgetOmr: maxBudgetOmr ?? this.maxBudgetOmr,
    );
  }
}

class TripPlanNotifier extends StateNotifier<TripPlanState> {
  TripPlanNotifier()
      : super(TripPlanState(
          departureTime: DateTime.now().add(const Duration(hours: 12)),
          selectedBoat: FuelCalculatorService.availableBoats.first,
        ));

  void updateSpecies(String species) => state = state.copyWith(targetSpecies: species);
  void updatePort(String port, double lat, double lon) =>
      state = state.copyWith(departurePort: port, departureLat: lat, departureLon: lon);
  void updateDuration(int hours) => state = state.copyWith(durationHours: hours);
  void updateBoat(BoatProfile boat) => state = state.copyWith(selectedBoat: boat);
  void updateBudget(double budget) => state = state.copyWith(maxBudgetOmr: budget);
}

final tripPlanProvider = StateNotifierProvider<TripPlanNotifier, TripPlanState>((ref) {
  return TripPlanNotifier();
});

final tripRecommendationsProvider = Provider<List<TripRecommendation>>((ref) {
  final plan = ref.watch(tripPlanProvider);
  final hotspots = ref.watch(hotspotsProvider);

  final list = <TripRecommendation>[];
  for (final h in hotspots) {
    final (dist, fuel, cost, time) = FuelCalculatorService.calculateTrip(
      startLat: plan.departureLat,
      startLon: plan.departureLon,
      destLat: h.latitude,
      destLon: h.longitude,
      boat: plan.selectedBoat,
    );

    // Filter by user budget
    if (cost <= plan.maxBudgetOmr) {
      list.add(TripRecommendation(
        hotspot: h,
        distanceNm: dist,
        estimatedFuelLiters: fuel,
        estimatedCostOmr: cost,
        travelMinutes: time,
        probability: h.probability,
        departurePort: plan.departurePort,
      ));
    }
  }

  list.sort((a, b) => b.probability.compareTo(a.probability));
  return list;
});
