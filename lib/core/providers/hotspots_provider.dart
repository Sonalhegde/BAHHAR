import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hotspot_model.dart';
import '../../shared/widgets/legal_status_badge.dart';

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

final hotspotsProvider = Provider<List<HotspotModel>>((ref) {
  return omaniHotspotsSeed;
});

final selectedRegionFilterProvider = StateProvider<String?>((ref) => null);
final selectedSpeciesFilterProvider = StateProvider<String?>((ref) => null);

final filteredHotspotsProvider = Provider<List<HotspotModel>>((ref) {
  final all = ref.watch(hotspotsProvider);
  final region = ref.watch(selectedRegionFilterProvider);
  final species = ref.watch(selectedSpeciesFilterProvider);

  return all.where((h) {
    if (region != null && h.region != region) return false;
    if (species != null && !h.targetSpecies.contains(species)) return false;
    return true;
  }).toList();
});
