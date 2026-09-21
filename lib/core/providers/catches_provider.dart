import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/user_model.dart';
import '../models/catch_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../services/prefs_service.dart';
import '../services/supabase_storage_service.dart';
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
    final user = _ref.read<UserProfile?>(authProvider);
    if (!FirebaseService.isConfigured || user == null || user.isGuest) {
      state = AsyncValue.data(initialCatchesSeed);
      return;
    }
    unawaited(_flushGuestQueue(user.id));
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

  /// Shown whenever a catch was recorded but its photo could not be stored, for
  /// any reason. One string so the two paths cannot drift apart.
  static const String _photoNotStoredWarning =
      'Photo storage is not set up on this build, so the catch was saved '
      'without its photo.';

  /// Saves a catch. Uploads the photo to Supabase Storage first when Firebase
  /// is available, photo storage is configured and a [photoPath] is provided;
  /// otherwise stores locally in memory (offline demo mode).
  ///
  /// Returns a warning to show the fisherman when the catch saved but its photo
  /// did not, or null when everything landed. The split is deliberate: photo
  /// storage being unconfigured is a known state of this build, so the record of
  /// a fish actually caught is kept and the gap is reported - while a real upload
  /// failure (network, bucket permissions) still throws, because a photo lost to
  /// a bad signal is worth retrying and the caller already surfaces failures.
  Future<String?> addCatch(CatchModel entry, {String? photoPath}) async {
    final user = _ref.read<UserProfile?>(authProvider);
    final uid = user?.id ?? 'user_default';

    if (!FirebaseService.isConfigured || user == null || user.isGuest) {
      state = state.whenData((list) => [entry, ...list]);
      // A catch logged before an account exists is the fisherman's own record of a fish
      // they actually caught. It is written to the device queue so a restart cannot
      // take it back, and it goes to Firestore under whoever signs in next.
      if (user == null || user.isGuest) {
        await PrefsService.addGuestCatch(jsonEncode(entry.toJson()));
      }
      // The same honesty applies here: a photo picked in demo mode is not
      // uploaded anywhere and the queued record does not carry the file, so
      // saying nothing would leave a log entry that implies a photo exists.
      return photoPath != null ? _photoNotStoredWarning : null;
    }

    String? photoUrl;
    String? photoWarning;
    if (photoPath != null) {
      try {
        photoUrl = await SupabaseStorageService.uploadCatchPhoto(
          uid: uid,
          catchId: entry.id,
          filePath: photoPath,
        );
      } on StorageUnavailableException {
        photoWarning = _photoNotStoredWarning;
      }
    }
    await _firestore.addCatch(entry, photoUrl: photoUrl);
    // Firestore snapshot listener refreshes [state]; optimistic insert keeps
    // the UI responsive until the snapshot lands.
    state = state.whenData(
      (list) => [entry.copyWith(photoUrl: photoUrl), ...list],
    );
    return photoWarning;
  }

  /// Points the controller at whatever account is current now.
  ///
  /// The constructor covers an app that started already signed in. A fisherman who
  /// signs in mid-session — which is the whole point of the guest queue — needs the
  /// queued catches pushed and their cloud log pulled, and needs the previous
  /// session's list gone from the screen while that happens.
  void reload() {
    final subscription = _subscription;
    _subscription = null;
    subscription?.cancel();
    state = const AsyncValue.loading();
    _init();
  }

  /// Writes any catches queued during guest sessions under [uid], then clears them.
  ///
  /// An entry that fails to write stays in the queue. A partial sync is survivable; an
  /// entry deleted because its first attempt failed is a lost catch.
  Future<void> _flushGuestQueue(String uid) async {
    final queued = PrefsService.getGuestCatchQueue();
    if (queued.isEmpty) return;
    final remaining = <String>[];
    for (final raw in queued) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) throw const FormatException('not an object');
        await _firestore.addCatch(
          CatchModel.fromJson(Map<String, dynamic>.from(decoded))
              .copyWith(userId: uid),
        );
      } catch (_) {
        remaining.add(raw);
      }
    }
    await PrefsService.setGuestCatchQueue(remaining);
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
  final controller = CatchesController(ref);
  if (FirebaseService.isConfigured) {
    // Guarded, not assumed: reading the auth state constructs FirebaseAuth, which has
    // no platform backing in a widget test or an offline demo build.
    ref.listen<UserProfile?>(authProvider, (_, __) => controller.reload());
  }
  return controller;
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
