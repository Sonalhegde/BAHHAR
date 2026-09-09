import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/catch_model.dart';

final initialCatchesSeed = [
  CatchModel(
    id: 'c1',
    speciesName: 'Kingfish (Kanaad)',
    speciesNameAr: 'كنعد',
    weightKg: 11.4,
    lengthCm: 98,
    locationName: 'Fahal Island, Muscat',
    latitude: 23.6811,
    longitude: 58.5028,
    caughtAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    notes: 'Trolled with live sardine at 25m depth near outer drop-off.',
    seaTempC: 27.2,
    waveHeightM: 0.9,
  ),
  CatchModel(
    id: 'c2',
    speciesName: 'Yellowfin Tuna (Thamad)',
    speciesNameAr: 'ثمد',
    weightKg: 18.2,
    lengthCm: 115,
    locationName: 'Ras Al Hadd Offshore',
    latitude: 22.5367,
    longitude: 59.8153,
    caughtAt: DateTime.now().subtract(const Duration(days: 4, hours: 5)),
    notes: 'Broke surface feeding frenzy at dawn. Landed on topwater popper.',
    seaTempC: 28.0,
    waveHeightM: 1.2,
  ),
  CatchModel(
    id: 'c3',
    speciesName: 'Hammour (Orange-spotted Grouper)',
    speciesNameAr: 'هامور',
    weightKg: 6.8,
    lengthCm: 64,
    locationName: 'Bandar Khayran Cove',
    latitude: 23.5186,
    longitude: 58.7364,
    caughtAt: DateTime.now().subtract(const Duration(days: 7)),
    notes: 'Deep structure jigging near the submerged pinnacle.',
    seaTempC: 26.8,
    waveHeightM: 0.6,
  ),
];

class CatchesNotifier extends StateNotifier<List<CatchModel>> {
  CatchesNotifier() : super(initialCatchesSeed);

  void addCatch(CatchModel newCatch) {
    state = [newCatch, ...state];
  }

  void removeCatch(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final catchesProvider = StateNotifierProvider<CatchesNotifier, List<CatchModel>>((ref) {
  return CatchesNotifier();
});

final catchStatsProvider = Provider<(int totalCatches, int totalTrips, String topSpecies)>((ref) {
  final catches = ref.watch(catchesProvider);
  if (catches.isEmpty) return (0, 0, 'None');

  final counts = <String, int>{};
  for (final c in catches) {
    counts[c.speciesName] = (counts[c.speciesName] ?? 0) + 1;
  }
  var top = catches.first.speciesName;
  var maxCount = 0;
  counts.forEach((k, v) {
    if (v > maxCount) {
      maxCount = v;
      top = k;
    }
  });

  return (catches.length, 5, top);
});
