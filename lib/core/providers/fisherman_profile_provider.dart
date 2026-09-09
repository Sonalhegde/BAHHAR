import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fisherman_profile_model.dart';
import '../models/fishing_licence_model.dart';
import '../models/vessel_model.dart';
import '../models/crew_member_model.dart';
import '../models/document_model.dart';

// ─── Profile Provider ─────────────────────────────────────────────────────────

class FishermanProfileNotifier extends StateNotifier<FishermanProfileModel> {
  FishermanProfileNotifier() : super(FishermanProfileModel.demo);

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
  }

  void updateEmergencyContact(EmergencyContactModel contact) {
    state = state.copyWith(emergencyContact: contact, updatedAt: DateTime.now());
  }

  void addLicenceId(String id) {
    if (!state.licenceIds.contains(id)) {
      state = state.copyWith(
        licenceIds: [...state.licenceIds, id],
        updatedAt: DateTime.now(),
      );
    }
  }

  void removeLicenceId(String id) {
    state = state.copyWith(
      licenceIds: state.licenceIds.where((l) => l != id).toList(),
      updatedAt: DateTime.now(),
    );
  }

  void addVesselId(String id) {
    if (!state.vesselIds.contains(id)) {
      state = state.copyWith(
        vesselIds: [...state.vesselIds, id],
        updatedAt: DateTime.now(),
      );
    }
  }

  void removeVesselId(String id) {
    state = state.copyWith(
      vesselIds: state.vesselIds.where((v) => v != id).toList(),
      updatedAt: DateTime.now(),
    );
  }
}

final fishermanProfileProvider =
    StateNotifierProvider<FishermanProfileNotifier, FishermanProfileModel>(
        (ref) => FishermanProfileNotifier());

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
