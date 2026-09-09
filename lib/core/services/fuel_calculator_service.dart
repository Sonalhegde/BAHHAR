import 'geofence_service.dart';

class BoatProfile {
  final String id;
  final String name;
  final int horsepower;
  final double cruisingSpeedKnots;
  final double litersPerNauticalMile;

  const BoatProfile({
    required this.id,
    required this.name,
    required this.horsepower,
    required this.cruisingSpeedKnots,
    required this.litersPerNauticalMile,
  });
}

/// Smart Trip Fuel & Nautical Engine (Section 1 & Phase 6)
class FuelCalculatorService {
  // Official Oman fuel price benchmark (OMR per liter for M91/M95)
  static const double omanFuelPricePerLiterOmr = 0.239;

  static const List<BoatProfile> availableBoats = [
    BoatProfile(
      id: 'skiff_50',
      name: 'Traditional 24ft Skiff (Single 50 HP)',
      horsepower: 50,
      cruisingSpeedKnots: 20.0,
      litersPerNauticalMile: 0.85,
    ),
    BoatProfile(
      id: 'center_console_150',
      name: '28ft Center Console (Twin 150 HP)',
      horsepower: 300,
      cruisingSpeedKnots: 26.0,
      litersPerNauticalMile: 1.65,
    ),
    BoatProfile(
      id: 'cruiser_dhow',
      name: '35ft Cabin Dhow (Inboard Diesel)',
      horsepower: 200,
      cruisingSpeedKnots: 16.0,
      litersPerNauticalMile: 1.95,
    ),
  ];

  /// Calculates round trip distance, fuel liters, and fuel cost in OMR with 25% safety reserve
  static (double distanceNm, double fuelLiters, double costOmr, int travelMinutes) calculateTrip({
    required double startLat,
    required double startLon,
    required double destLat,
    required double destLon,
    required BoatProfile boat,
  }) {
    final oneWayKm = GeofenceService.distanceKm(startLat, startLon, destLat, destLon);
    final oneWayNm = GeofenceService.kmToNauticalMiles(oneWayKm);
    final roundTripNm = oneWayNm * 2.0;

    // Add 25% reserve for currents, trolling, and harbor maneuvering
    final totalFuelLiters = (roundTripNm * boat.litersPerNauticalMile) * 1.25;
    final totalCostOmr = totalFuelLiters * omanFuelPricePerLiterOmr;
    final travelMinutes = ((oneWayNm / boat.cruisingSpeedKnots) * 60).round();

    return (
      double.parse(roundTripNm.toStringAsFixed(1)),
      double.parse(totalFuelLiters.toStringAsFixed(1)),
      double.parse(totalCostOmr.toStringAsFixed(2)),
      travelMinutes,
    );
  }
}
