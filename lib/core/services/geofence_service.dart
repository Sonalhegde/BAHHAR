import 'dart:math';
import '../models/protected_area_model.dart';
import '../../shared/widgets/legal_status_badge.dart';

/// Geofencing service for checking vessels against Omani marine nature reserves
/// and restricted maritime zones (Section 1 & Phase 4)
class GeofenceService {
  static const List<ProtectedArea> omaniReserves = [
    ProtectedArea(
      id: 'daymaniyat',
      name: 'Ad Daymaniyat Islands Nature Reserve',
      nameAr: 'محمية جزر الديمانيات الطبيعية',
      type: 'Marine Nature Reserve',
      centerLat: 23.8617,
      centerLon: 58.0933,
      radiusKm: 18.0,
      regulationSummary: 'No fishing permitted without official MOAF permit. Strictly prohibited anchorage outside designated buoys.',
      legalDecree: 'Royal Decree No. 23/96',
    ),
    ProtectedArea(
      id: 'ras_al_jinz',
      name: 'Ras Al Jinz Turtle Sanctuary',
      nameAr: 'محمية السلاحف برأس الجنز',
      type: 'Coastal Conservation Zone',
      centerLat: 22.4278,
      centerLon: 59.8319,
      radiusKm: 6.0,
      regulationSummary: 'Strict no-entry zone for motorized fishing boats within 3 nm of shoreline during green turtle nesting season.',
      legalDecree: 'Ministerial Decision No. 12/2008',
    ),
    ProtectedArea(
      id: 'musandam_choke',
      name: 'Strait of Hormuz Commercial Shipping Lane',
      nameAr: 'ممر الملاحة التجارية بمضيق هرمز',
      type: 'Restricted Traffic Separation Zone',
      centerLat: 26.3811,
      centerLon: 56.4522,
      radiusKm: 12.0,
      regulationSummary: 'Vessels under 20m strictly prohibited from drifting or casting nets within commercial separation corridors.',
      legalDecree: 'Maritime Law Decision 4/2012',
    ),
  ];

  /// Calculate distance between two GPS coordinates using the Haversine formula (km)
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Converts kilometers to nautical miles
  static double kmToNauticalMiles(double km) => km * 0.539957;

  /// Checks if a location falls inside any protected or restricted area
  static (LegalStatus, ProtectedArea?) checkLegalStatus(double lat, double lon) {
    for (final reserve in omaniReserves) {
      final d = distanceKm(lat, lon, reserve.centerLat, reserve.centerLon);
      if (d <= reserve.radiusKm) {
        if (reserve.type.contains('Reserve')) {
          return (LegalStatus.protected, reserve);
        } else {
          return (LegalStatus.restricted, reserve);
        }
      }
    }
    return (LegalStatus.permitted, null);
  }
}
