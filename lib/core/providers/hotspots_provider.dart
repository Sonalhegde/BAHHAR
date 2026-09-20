import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../models/hotspot_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../../shared/widgets/legal_status_badge.dart';

/// Seed hotspots used when Firebase is not configured, so the app remains
/// explorable offline. Never used once Firebase is available.
final omaniHotspotsSeed = [
  const HotspotModel(
    id: 'fahal_island',
    name: 'Fahal Island (Shark Island)',
    nameAr: 'جزيرة الفحل',
    region: 'Muscat',
    latitude: 23.6811,
    longitude: 58.5028,
    distanceNm: 4.2,
    depthMeters: 38,
    targetSpecies: ['Kingfish', 'Yellowfin Tuna', 'Queenfish', 'Trevally'],
    probability: 88,
    legalStatus: LegalStatus.permitted,
    bestWindow: '05:30 – 09:00',
    description: 'Premier pelagic feeding ground off Muscat. Steep limestone drop-offs attract massive kingfish and tuna schools.',
  ),
  const HotspotModel(
    id: 'daymaniyat_islands',
    name: 'Daymaniyat Nature Reserve Drop-off',
    nameAr: 'محمية جزر الديمانيات',
    region: 'Al Batinah South',
    latitude: 23.8617,
    longitude: 58.0933,
    distanceNm: 9.8,
    depthMeters: 55,
    targetSpecies: ['Hammour', 'Sailfish', 'Yellowfin Tuna'],
    probability: 92,
    legalStatus: LegalStatus.protected,
    bestWindow: '06:00 – 10:30',
    description: 'Vibrant coral archipelago. Exceptional biodiversity. Strictly protected reserve requiring official ministry permit.',
    legalNotice: 'Protected under Royal Decree 23/96. Special recreational angling permit required.',
  ),
  const HotspotModel(
    id: 'bandar_khayran',
    name: 'Bandar Khayran Coves',
    nameAr: 'بندر الخيران',
    region: 'Muscat',
    latitude: 23.5186,
    longitude: 58.7364,
    distanceNm: 6.5,
    depthMeters: 28,
    targetSpecies: ['Hammour', 'Queenfish', 'Barracuda', 'Trevally'],
    probability: 74,
    legalStatus: LegalStatus.permitted,
    bestWindow: '15:30 – 18:45',
    description: 'Deep natural fjords with tidal current channels. Excellent inshore casting and bottom jigging for grouper and snapper.',
  ),
  const HotspotModel(
    id: 'ras_al_hadd',
    name: 'Ras Al Hadd Deep Trench',
    nameAr: 'خندق رأس الحد العميق',
    region: 'Ash Sharqiyah South',
    latitude: 22.5367,
    longitude: 59.8153,
    distanceNm: 12.0,
    depthMeters: 90,
    targetSpecies: ['Yellowfin Tuna', 'Mahi-Mahi', 'Sailfish'],
    probability: 85,
    legalStatus: LegalStatus.permitted,
    bestWindow: '05:00 – 08:30',
    description: 'Where the Gulf of Oman converges with the Arabian Sea. Upwelling creates prime big-game trolling conditions.',
  ),
  const HotspotModel(
    id: 'khasab_kumzar',
    name: 'Kumzar Deep Passage',
    nameAr: 'ممر كمزار البحري',
    region: 'Musandam',
    latitude: 26.3314,
    longitude: 56.4178,
    distanceNm: 14.5,
    depthMeters: 75,
    targetSpecies: ['Kingfish', 'Giant Trevally', 'Hammour'],
    probability: 89,
    legalStatus: LegalStatus.permitted,
    bestWindow: '06:00 – 09:30',
    description: 'Dramatic cliffs and high-velocity tidal currents in the Strait of Hormuz. Renowned for monster kingfish.',
  ),
  const HotspotModel(
    id: 'masirah_channel',
    name: 'Masirah Island Channel',
    nameAr: 'قناة جزيرة مصيرة',
    region: 'Al Wusta',
    latitude: 20.4500,
    longitude: 58.7500,
    distanceNm: 16.0,
    depthMeters: 45,
    targetSpecies: ['Queenfish', 'Kingfish', 'Barracuda'],
    probability: 78,
    legalStatus: LegalStatus.permitted,
    bestWindow: '06:30 – 11:00',
    description: 'Rich shallow-to-deep transition shelf. Strong seasonal winds; check wave forecast before departing.',
  ),
  const HotspotModel(
    id: 'mirbat_dropoff',
    name: 'Mirbat Pelagic Drop-off',
    nameAr: 'جرف مرباط البحري',
    region: 'Dhofar',
    latitude: 16.9833,
    longitude: 54.7000,
    distanceNm: 8.0,
    depthMeters: 110,
    targetSpecies: ['Yellowfin Tuna', 'Amberjack', 'Grouper'],
    probability: 82,
    legalStatus: LegalStatus.permitted,
    bestWindow: '05:45 – 09:15',
    description: 'Post-Khareef cold nutrient upwelling attracts massive schools of game fish close to the shore.',
  ),
];

/// Center used for the initial hotspot fetch — Muscat/Seeb coastal waters.
const LatLng defaultMapCenter = LatLng(23.6143, 58.5453);

/// Hotspots straight from FirestoreService; falls back to seed data only when
/// Firebase is not configured (offline demo mode). Real Firestore/network
/// errors propagate to the UI as an error state with retry.
///
/// Every fallback path returns [omaniHotspotsSeed] itself, which is how
/// [offlineDataModeProvider] recognises offline mode without this provider
/// writing to another one.
final hotspotsProvider = FutureProvider<List<HotspotModel>>((ref) async {
  if (!FirebaseService.isConfigured) {
    return omaniHotspotsSeed;
  }
  final service = FirestoreService();
  try {
    // 1200 km covers the full Omani coast from Musandam to Dhofar.
    final hotspots = await service.fetchHotspots(defaultMapCenter, 1200);
    // Firestore reachable but collection empty (e.g. not seeded yet).
    return hotspots.isEmpty ? omaniHotspotsSeed : hotspots;
  } on FirebaseUnavailableException {
    return omaniHotspotsSeed;
  }
  // Any other error (permissions, network) intentionally propagates so the
  // UI can show a retry state instead of silently swapping in fake data.
});

/// True when the data layer fell back to the bundled seed because live data was
/// unavailable. UI shows a visible banner while this is set.
///
/// Derived from [hotspotsProvider] rather than written to it: Riverpod forbids
/// mutating a provider while a different one is initialising, and
/// `hotspotsProvider` is watched from inside several other providers' build
/// phases. Identity comparison is safe because real data is always a fresh list
/// instance while every fallback returns the seed list itself.
final offlineDataModeProvider = Provider<bool>((ref) => ref
    .watch(hotspotsProvider)
    .maybeWhen(
      data: (spots) => identical(spots, omaniHotspotsSeed),
      orElse: () => false,
    ));

final selectedRegionFilterProvider = StateProvider<String?>((ref) => null);
final selectedSpeciesFilterProvider = StateProvider<String?>((ref) => null);

final filteredHotspotsProvider = FutureProvider<List<HotspotModel>>((ref) async {
  final all = await ref.watch(hotspotsProvider.future);
  final region = ref.watch(selectedRegionFilterProvider);
  final species = ref.watch(selectedSpeciesFilterProvider);

  return all.where((h) {
    if (region != null && h.region != region) return false;
    if (species != null && !h.targetSpecies.contains(species)) return false;
    return true;
  }).toList();
});

/// Synchronous lookup for the details screen once hotspots are loaded.
final hotspotByIdProvider = FutureProvider.family<HotspotModel?, String>(
  (ref, id) async {
    final all = await ref.watch(hotspotsProvider.future);
    try {
      return all.firstWhere((h) => h.id == id);
    } on StateError {
      return null;
    }
  },
);

/// Distinct species across the loaded hotspots, for filter chips.
final availableSpeciesProvider = FutureProvider<List<String>>((ref) async {
  final all = await ref.watch(hotspotsProvider.future);
  final set = <String>{};
  for (final h in all) {
    set.addAll(h.targetSpecies);
  }
  return set.toList()..sort();
});
