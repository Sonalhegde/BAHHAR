import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catch_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// Seed catches used when Firebase is not configured (offline demo mode).
final initialCatchesSeed = [
  CatchModel(
    id: 'c1',
    userId: 'user_dev_01',
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
    baitOrLure: 'Live Bait Line',
    released: false,
  ),
  CatchModel(
    id: 'c2',
    userId: 'user_dev_01',
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
    baitOrLure: 'Popper / Topwater',
    released: false,
  ),
  CatchModel(
    id: 'c3',
    userId: 'user_dev_01',
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
    baitOrLure: 'Deep Drop Jig',
    released: true,
  ),
];

/// Async catch log state for the signed-in user. Firebase-backed when
/// configured (live Firestore snapshots), seed-backed in offline demo mode.
class CatchesController extends StateNotifier<AsyncValue<List<CatchModel>>> {
  final Ref _ref;
  StreamSubscription<List<CatchModel>>? _subscription;
  final FirestoreService _firestore = FirestoreService();

  CatchesController(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final user = _ref.read(authProvider);
    if (!FirebaseService.isConfigured || user == null || user.isGuest) {
      state = AsyncValue.data(initialCatchesSeed);
      return;
    }
    _subscription?.cancel();
    _subscription = _firestore.fetchCatchesForUser(user.id).listen(
      (catches) {
        state = AsyncValue.data(catches);
      },
      onError: (Object e, StackTrace st) {
        // Real stream errors (permissions, network) become a visible error
        // state; offline-demo fallback only applies to missing configuration.
        state = AsyncValue.error(e, st);
      },
    );
  }

  /// Saves a catch. Uploads the photo to Firebase Storage first when Firebase
  /// is available and a [photoPath] is provided; otherwise stores locally in
  /// memory (offline demo mode).
  Future<void> addCatch(CatchModel entry, {String? photoPath}) async {
    final user = _ref.read(authProvider);
    final uid = user?.id ?? 'user_default';

    if (!FirebaseService.isConfigured || user == null || user.isGuest) {
      state = state.whenData((list) => [entry, ...list]);
      return;
    }

    String? photoUrl;
    if (photoPath != null) {
      photoUrl = await _firestore.uploadCatchPhoto(
        uid: uid,
        catchId: entry.id,
        filePath: photoPath,
      );
    }
    await _firestore.addCatch(entry, photoUrl: photoUrl);
    // Firestore snapshot listener refreshes [state]; optimistic insert keeps
    // the UI responsive until the snapshot lands.
    state = state.whenData(
      (list) => [entry.copyWith(photoUrl: photoUrl), ...list],
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final catchesProvider =
    StateNotifierProvider<CatchesController, AsyncValue<List<CatchModel>>>(
        (ref) {
  return CatchesController(ref);
});

/// (totalCatches, totalTrips, topSpecies) computed from the real log — a trip
/// is a distinct fishing day.
final catchStatsProvider =
    Provider<(int totalCatches, int totalTrips, String topSpecies)>((ref) {
  final catches =
      ref.watch(catchesProvider).valueOrNull ?? const <CatchModel>[];
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

  final distinctDays = catches.map((c) {
    final d = c.caughtAt;
    return DateTime(d.year, d.month, d.day);
  }).toSet().length;

  return (catches.length, distinctDays, top);
});
