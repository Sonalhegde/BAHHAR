import 'package:flutter_test/flutter_test.dart';
import 'package:bahhar/core/services/fuel_calculator_service.dart';

void main() {
  group('FuelCalculatorService Tests', () {
    test('Calculates fuel liters and OMR cost with safety reserve for Skiff', () {
      final skiff = FuelCalculatorService.availableBoats.first;
      final (distNm, fuelLiters, costOmr, travelMins) = FuelCalculatorService.calculateTrip(
        startLat: 23.5786,
        startLon: 58.6083,
        destLat: 23.6811,
        destLon: 58.5028,
        boat: skiff,
      );

      expect(distNm, greaterThan(10.0));
      expect(fuelLiters, greaterThan(5.0));
      expect(costOmr, greaterThan(1.0));
      expect(travelMins, greaterThan(10));
    });
  });
}
