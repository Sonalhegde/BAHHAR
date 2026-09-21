import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when a file upload is attempted with no Supabase project configured.
///
/// Surfaced rather than swallowed: a missing photo is a fact the fisherman is
/// entitled to, and the alternative — storing a URL that points at nothing —
/// is the kind of fiction this project has already refused once (see the
/// documented sample data in the backend's weather/marine endpoints, which is
/// always labelled as such).
class StorageUnavailableException implements Exception {
  final String message;
  const StorageUnavailableException([this.message =
      'Photo storage is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY '
      'and rebuild with --dart-define (or --dart-define-from-file=.env).']);

  @override
  String toString() => message;
}

/// File storage for BAHHAR: Supabase Storage.
///
/// This replaced Firebase Cloud Storage. The reason is money, not taste: Cloud
/// Storage requires the Blaze (billing-enabled) plan at any volume, and the
/// project is deliberately card-free — the same reasoning that put MapLibre and
/// OpenFreeMap in place of Google Maps. Firestore still holds every document;
/// only the bytes moved.
///
/// Mirrors the service-layer shape used across `lib/core/services/`: clear
/// `Future<String> uploadX()` methods returning a URL, and an [isConfigured]
/// flag that keeps an unprovisioned build honest instead of pretend-working.
class SupabaseStorageService {
  /// Client config, not a secret — row-level security on the bucket is the
  /// boundary. Empty unless supplied at build time, which is the state a fresh
  /// clone is in until someone creates the Supabase project.
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Bucket name, matching the out-of-band setup note in `.env.example`.
  /// Must be created PUBLIC-READ with authenticated writes: [uploadCatchPhoto]
  /// hands back a public URL and the catch document stores only that URL.
  static const String bucket = 'bahhar-uploads';

  static bool _isConfigured = false;

  /// True once [init] completed against real credentials.
  static bool get isConfigured => _isConfigured;

  static SupabaseClient get _client => Supabase.instance.client;

  /// Initialise the Supabase client. Safe to call when nothing is configured:
  /// the app then runs with no photo storage and says so on first use, exactly
  /// like [FirebaseService.init] running without cloud sync.
  static Future<void> init() async {
    if (_url.isEmpty || _anonKey.isEmpty) {
      _isConfigured = false;
      debugPrint(
        'BAHHAR: photo storage is NOT configured (no SUPABASE_URL / '
        'SUPABASE_ANON_KEY). Catches still save; their photos will not upload.',
      );
      return;
    }
    try {
      await Supabase.initialize(url: _url, anonKey: _anonKey);
      _isConfigured = true;
    } catch (e) {
      _isConfigured = false;
      debugPrint('BAHHAR: photo storage is unavailable ($e).');
    }
  }

  /// Uploads a catch photo to `catches/{uid}/{catchId}.jpg` and returns its
  /// public URL.
  ///
  /// Overwrites are intentional (`upsert`) so re-picking a photo for the same
  /// unsaved catch does not pile up `..._1.jpg` copies in the bucket.
  static Future<String> uploadCatchPhoto({
    required String uid,
    required String catchId,
    required String filePath,
  }) async {
    if (!_isConfigured) throw const StorageUnavailableException();

    final path = 'catches/$uid/$catchId.jpg';
    final bytes = await File(filePath).readAsBytes();
    await _client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
