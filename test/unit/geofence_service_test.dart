import 'package:flutter_test/flutter_test.dart';
import 'package:bahhar/core/services/geofence_service.dart';
import 'package:bahhar/shared/widgets/legal_status_badge.dart';

void main() {
  group('GeofenceService Tests', () {
    test('Correctly calculates Haversine distance between Muscat and Daymaniyat', () {
      // Muscat approx 23.61, 58.54; Daymaniyat approx 23.86, 58.09
      final distKm = GeofenceService.distanceKm(23.61, 58.54, 23.86, 58.09);
      expect(distKm, greaterThan(45.0));
      expect(distKm, lessThan(65.0));
    });

    test('Identifies coordinates inside Daymaniyat Islands as protected reserve', () {
      final (status, reserve) = GeofenceService.checkLegalStatus(23.8617, 58.0933);
      expect(status, LegalStatus.protected);
      expect(reserve?.name, contains('Daymaniyat'));
      expect(reserve?.legalDecree, contains('23/96'));
    });

    test('Identifies open Muscat coastal waters as permitted zone', () {
      final (status, reserve) = GeofenceService.checkLegalStatus(23.65, 58.60);
      expect(status, LegalStatus.permitted);
      expect(reserve, isNull);
    });
  });
}
