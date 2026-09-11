import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/trip_service.dart';
import 'hotspots_provider.dart';

export '../services/trip_service.dart'
    show TripRequest, TripRecommendation, TripWaypoint, TripService;

/// Wizard state = the TripRequest itself. Every wizard step writes straight
/// into this provider via copyWith.
class TripRequestNotifier extends StateNotifier<TripRequest> {
  TripRequestNotifier()
      : super(TripRequest(
          targetSpecies: 'Kingfish (Kanaad)',
          departurePort: 'Marina Bandar Al Rowdha (Muscat)',
          departureLat: 23.5786,
          departureLon: 58.6083,
          departureTime: DateTime.now().add(const Duration(hours: 12)),
        ));

  void updateSpecies(String species) =>
      state = state.copyWith(targetSpecies: species);

  void updateStartingPoint(String port, double lat, double lon) =>
      state = state.copyWith(
          departurePort: port, departureLat: lat, departureLon: lon);

  void updateDeparture(DateTime when, String slotLabel) =>
      state = state.copyWith(departureTime: when, departureSlotLabel: slotLabel);

  void updateVesselType(String vesselType) =>
      state = state.copyWith(vesselType: vesselType);

  void updateMaxRadius(int radiusNmi) =>
      state = state.copyWith(maxRadiusNmi: radiusNmi);

  void updateDuration(int hours) => state = state.copyWith(durationHours: hours);

  void updateBudget(double budget) => state = state.copyWith(maxBudgetOmr: budget);
}

final tripPlanProvider =
    StateNotifierProvider<TripRequestNotifier, TripRequest>((ref) {
  return TripRequestNotifier();
});

/// Result of the wizard: calls TripService.planTrip against the loaded
/// hotspot catalogue. Currently a believable mock — see TripService TODO
/// for the real ML backend hookup.
final tripPlanResultProvider =
    FutureProvider.autoDispose<TripRecommendation>((ref) async {
  final request = ref.watch(tripPlanProvider);
  final hotspots = await ref.watch(hotspotsProvider.future);
  final service = TripService();
  return service.planTrip(request, hotspots);
});
