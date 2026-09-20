import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../features/auth/domain/user_model.dart';
import '../models/catch_model.dart';
import '../models/fisherman_profile_model.dart';
import '../models/hotspot_model.dart';
import 'firebase_service.dart';

/// Typed Firestore/FireStorage data layer for BAHHAR.
///
/// Every method requires Firebase to be configured; otherwise it throws
/// [FirebaseUnavailableException] so callers can show an explicit error /
/// offline state instead of silently failing.
class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  void _ensureConfigured() {
    if (!FirebaseService.isConfigured) {
      throw const FirebaseUnavailableException();
    }
  }

  // ── Hotspots ──────────────────────────────────────────────────────────────

  /// Hotspots within [radiusKm] of [center], sorted by probability (best first).
  ///
  // TODO(perf): Firestore has no native geo-queries; once the hotspot count
  // grows, switch to geohash range queries instead of filtering client-side.
  Future<List<HotspotModel>> fetchHotspots(LatLng center, double radiusKm) async {
    _ensureConfigured();
    final snap = await _db.collection('hotspots').get();
    final all = snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return HotspotModel.fromJson(data);
    }).toList();

    return all
        .where((h) =>
            _distanceKm(center.latitude, center.longitude, h.latitude, h.longitude) <=
            radiusKm)
        .toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));
  }

  // ── Catches ───────────────────────────────────────────────────────────────

  /// Live stream of the signed-in user's catch log, newest first.
  Stream<List<CatchModel>> fetchCatchesForUser(String uid) {
    _ensureConfigured();
    return _db
        .collection('catches')
        .where('userId', isEqualTo: uid)
        .orderBy('caughtAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CatchModel.fromJson({'id': d.id, ...d.data()}))
            .toList());
  }

  /// Persists a catch document. Upload the photo first via [uploadCatchPhoto]
  /// and pass the resulting URL as [photoUrl].
  Future<void> addCatch(CatchModel entry, {String? photoUrl}) async {
    _ensureConfigured();
    final data = entry.copyWith(photoUrl: photoUrl).toJson();
    await _db.collection('catches').doc(entry.id).set(data);
  }

  /// Uploads a catch photo to Firebase Storage under catches/{uid}/{catchId}/
  /// and returns the public download URL.
  Future<String> uploadCatchPhoto({
    required String uid,
    required String catchId,
    required String filePath,
  }) async {
    _ensureConfigured();
    final file = File(filePath);
    final ref = _storage.ref().child('catches').child(uid).child('$catchId.jpg');
    final upload = await ref.putFile(file);
    return upload.ref.getDownloadURL();
  }

  // ── User profile ──────────────────────────────────────────────────────────

  Future<UserProfile?> fetchUserProfile(String uid) async {
    _ensureConfigured();
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromJson({'id': doc.id, ...?doc.data()});
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> fields) async {
    _ensureConfigured();
    await _db.collection('users').doc(uid).set(fields, SetOptions(merge: true));
  }

  /// Creates or refreshes the users/{uid} document after a successful login.
  Future<void> upsertUserOnLogin(User user, {String? preferredLocale}) async {
    _ensureConfigured();
    await _db.collection('users').doc(user.uid).set({
      'displayName': user.displayName ?? user.email?.split('@').first ?? 'Bahhar User',
      'email': user.email,
      'phone': user.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
      if (preferredLocale != null) 'preferredLocale': preferredLocale,
    }, SetOptions(merge: true));
  }

  // ── Fisherman profile ───────────────────────────────────────────────────────

  /// Reads `fisherman_profiles/{uid}`.
  ///
  /// A missing document returns null rather than throwing: never having saved a
  /// profile is the normal first-run state, not a failure, and the caller decides
  /// what to start the fisherman with.
  Future<FishermanProfileModel?> fetchFishermanProfile(String uid) async {
    _ensureConfigured();
    final doc = await _db.collection('fisherman_profiles').doc(uid).get();
    if (!doc.exists) return null;
    return FishermanProfileModel.fromJson({'uid': uid, ..._stringify(doc.data())});
  }

  /// Writes the whole profile.
  ///
  /// The document is FLAT because `FishermanProfileModel.toJson()` is flat, and
  /// `firestore.rules` asserts that same flat shape on create; the two have to move
  /// together or every first save is rejected with PERMISSION_DENIED.
  ///
  /// Merged, not replaced, so a field this build does not know about survives a save
  /// from a build that does. A null `createdAt` is stamped here instead: with a merge
  /// it would otherwise be written as null and stay null on every later save.
  Future<void> saveFishermanProfile(FishermanProfileModel profile) async {
    _ensureConfigured();
    final data = profile.toJson();
    data['createdAt'] ??=
        DateTime.now().toUtc().toIso8601String(); // device clock, first write only
    await _db
        .collection('fisherman_profiles')
        .doc(profile.uid)
        .set(data, SetOptions(merge: true));
  }

  /// Firestore stores dates as [Timestamp]; the models speak ISO-8601 strings,
  /// because that is the shape they were first built against offline. Normalising on
  /// the way in keeps a cloud_firestore import out of every model.
  Map<String, dynamic> _stringify(Map<String, dynamic>? data) {
    if (data == null) return const {};
    return data.map((key, value) => MapEntry(
          key,
          value is Timestamp ? value.toDate().toIso8601String() : value,
        ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;
}
