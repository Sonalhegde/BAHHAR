import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/user_model.dart';
import '../models/fisherman_profile_model.dart';
import '../models/fishing_licence_model.dart';
import '../models/vessel_model.dart';
import '../models/crew_member_model.dart';
import '../models/document_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// ─── Profile Provider ─────────────────────────────────────────────────────────

/// The signed-in fisherman's own record, mirrored to `fisherman_profiles/{uid}`.
///
/// Reads happen when a real user signs in; every mutation writes the whole record
/// back. The state updates first and the write follows, so the form never blocks on
/// the network — which also means a save can fail after the UI has moved on. That is
/// why [lastSyncError] exists: an unsaved edit must be sayable out loud, not quietly
/// lost when the app next starts. Firebase being unconfigured is not an error at all
/// (offline demo mode), so it clears the flag instead of setting it.
class FishermanProfileNotifier extends StateNotifier<FishermanProfileModel> {
  FishermanProfileNotifier(this._ref) : super(FishermanProfileModel.demo) {
    // Guarded rather than assumed: reading the auth state pulls FirebaseAuth, which is
    // not constructed in a widget test or a build without config files. Offline demo
    // mode is the normal state here, not an exceptional one.
    if (FirebaseService.isConfigured) {
      unawaited(loadFor(_ref.read(authProvider)));
    }
  }

  final Ref _ref;
  final FirestoreService _firestore = FirestoreService();

  String? _lastSyncError;

  /// Null while the record in memory and the record in Firestore agree.
  String? get lastSyncError => _lastSyncError;

  /// The signed-in fisherman's record is pulled on start-up and whenever the account
  /// changes. A guest and a signed-out session keep the demo record, exactly as they
  /// keep the seeded catch log: nothing is read or written for a fisherman who has not
  /// chosen an account.
  Future<void> loadFor(UserProfile? user) async {
    if (!FirebaseService.isConfigured) return;
    if (user == null || user.isGuest) return;
    try {
      final stored = await _firestore.fetchFishermanProfile(user.id);
      // A fisherman who has never saved one has no document, which is not a reason to
      // blank out what the form is already showing.
      if (stored != null) state = stored;
      _lastSyncError = null;
    } catch (e) {
      _lastSyncError = e.toString();
    }
  }

  /// Pushes the current state to `fisherman_profiles/{uid}`.
  ///
  /// Awaited by the screens that report a save; the mutators below call it through
  /// [_persist] so the form never waits on the network.
  Future<void> save() async {
    if (!FirebaseService.isConfigured) return;
    final user = _ref.read<UserProfile?>(authProvider);
    if (user == null || user.isGuest) return;
    // The record in memory may still be the demo one, whose uid is `demo_uid`; it has
    // to adopt the signed-in id before it can be written under it.
    if (state.uid != user.id) state = state.copyWith(uid: user.id);
    try {
      await _firestore.saveFishermanProfile(state);
      _lastSyncError = null;
    } catch (e) {
      _lastSyncError = e.toString();
    }
  }

  /// Write-behind. A failure is recorded in [lastSyncError] rather than thrown, since
  /// there is no longer a caller waiting to hear about it.
  void _persist() => unawaited(save());

  void updatePersonalInfo({
    String? fullName,
    String? fullNameArabic,
    String? civilId,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? alternatePhone,
    String? email,
    String? governorate,
    String? wilayat,
    String? address,
  }) {
    state = state.copyWith(
      fullName: fullName,
      fullNameArabic: fullNameArabic,
      civilId: civilId,
      dateOfBirth: dateOfBirth,
      phoneNumber: phoneNumber,
      alternatePhone: alternatePhone,
      email: email,
      governorate: governorate,
      wilayat: wilayat,
      address: address,
      updatedAt: DateTime.now(),
    );
    _persist();
  }

  void updateEmergencyContact(EmergencyContactModel contact) {
    state = state.copyWith(emergencyContact: contact, updatedAt: DateTime.now());
    _persist();
  }

  void addLicenceId(String id) {
    if (!state.licenceIds.contains(id)) {
      state = state.copyWith(
        licenceIds: [...state.licenceIds, id],
        updatedAt: DateTime.now(),
      );
      _persist();
    }
  }

  void removeLicenceId(String id) {
    state = state.copyWith(
      licenceIds: state.licenceIds.where((l) => l != id).toList(),
      updatedAt: DateTime.now(),
    );
    _persist();
  }

  void addVesselId(String id) {
    if (!state.vesselIds.contains(id)) {
      state = state.copyWith(
        vesselIds: [...state.vesselIds, id],
        updatedAt: DateTime.now(),
      );
      _persist();
    }
  }

  void removeVesselId(String id) {
    state = state.copyWith(
      vesselIds: state.vesselIds.where((v) => v != id).toList(),
      updatedAt: DateTime.now(),
    );
    _persist();
  }
}

final fishermanProfileProvider =
    StateNotifierProvider<FishermanProfileNotifier, FishermanProfileModel>((ref) {
  final notifier = FishermanProfileNotifier(ref);
  if (FirebaseService.isConfigured) {
    // Signing in mid-session pulls the stored record — the constructor only covers the
    // case where the app started with a session Firebase had already restored.
    ref.listen<UserProfile?>(authProvider, (_, user) => notifier.loadFor(user));
  }
  return notifier;
});

// ─── Licences Provider ────────────────────────────────────────────────────────

class LicencesNotifier extends StateNotifier<List<FishingLicenceModel>> {
  LicencesNotifier() : super([FishingLicenceModel.demo]);

  void add(FishingLicenceModel licence) {
    state = [...state, licence];
  }

  void remove(String id) {
    state = state.where((l) => l.id != id).toList();
  }

  void update(FishingLicenceModel updated) {
    state = state.map((l) => l.id == updated.id ? updated : l).toList();
  }
}

final licencesProvider =
    StateNotifierProvider<LicencesNotifier, List<FishingLicenceModel>>(
        (ref) => LicencesNotifier());

// ─── Vessels Provider ─────────────────────────────────────────────────────────

class VesselsNotifier extends StateNotifier<List<VesselModel>> {
  VesselsNotifier() : super([VesselModel.demo]);

  void add(VesselModel vessel) => state = [...state, vessel];
  void remove(String id) => state = state.where((v) => v.id != id).toList();
  void update(VesselModel updated) =>
      state = state.map((v) => v.id == updated.id ? updated : v).toList();
}

final vesselsProvider =
    StateNotifierProvider<VesselsNotifier, List<VesselModel>>(
        (ref) => VesselsNotifier());

// ─── Crew Provider ────────────────────────────────────────────────────────────

class CrewNotifier extends StateNotifier<List<CrewMemberModel>> {
  CrewNotifier() : super([]);

  void add(CrewMemberModel member) => state = [...state, member];
  void remove(String id) => state = state.where((c) => c.id != id).toList();
  void update(CrewMemberModel updated) =>
      state = state.map((c) => c.id == updated.id ? updated : c).toList();
}

final crewProvider =
    StateNotifierProvider<CrewNotifier, List<CrewMemberModel>>(
        (ref) => CrewNotifier());

// ─── Documents Provider ───────────────────────────────────────────────────────

class DocumentsNotifier extends StateNotifier<List<DocumentModel>> {
  DocumentsNotifier() : super([]);

  void add(DocumentModel doc) => state = [...state, doc];
  void remove(String id) => state = state.where((d) => d.id != id).toList();
  void update(DocumentModel updated) =>
      state = state.map((d) => d.id == updated.id ? updated : d).toList();

  List<DocumentModel> get expiringSoon =>
      state.where((d) => d.isExpiringSoon).toList();

  List<DocumentModel> get expired =>
      state.where((d) => d.isExpired).toList();
}

final documentsProvider =
    StateNotifierProvider<DocumentsNotifier, List<DocumentModel>>(
        (ref) => DocumentsNotifier());

// ─── Gear Provider ────────────────────────────────────────────────────────────

class GearNotifier extends StateNotifier<List<FishingGearModel>> {
  GearNotifier() : super([]);

  void add(FishingGearModel gear) => state = [...state, gear];
  void remove(String id) => state = state.where((g) => g.id != id).toList();
}

final gearProvider =
    StateNotifierProvider<GearNotifier, List<FishingGearModel>>(
        (ref) => GearNotifier());
