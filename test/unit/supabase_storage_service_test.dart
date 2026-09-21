import 'package:bahhar/core/services/supabase_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// SupabaseStorageService without a Supabase project.
///
/// These are the only assertions that can be made honestly on a machine with no
/// SUPABASE_URL / SUPABASE_ANON_KEY at build time, and they are the ones that
/// matter for the card-free migration: the service must refuse loudly rather than
/// hand back a URL that points at nothing.
void main() {
  group('SupabaseStorageService (unconfigured)', () {
    test('reports itself unconfigured in a test host, where no dart-define was passed',
        () {
      expect(SupabaseStorageService.isConfigured, isFalse);
    });

    test('init() with no credentials stays inert instead of throwing', () async {
      await SupabaseStorageService.init();
      expect(SupabaseStorageService.isConfigured, isFalse);
    });

    test('an upload attempt refuses rather than returning a made-up URL', () async {
      await expectLater(
        SupabaseStorageService.uploadCatchPhoto(
          uid: 'u1',
          catchId: 'c1',
          filePath: 'this-file-is-never-read.jpg',
        ),
        throwsA(isA<StorageUnavailableException>()),
      );
    });

    test('the refusal names the two flags to set', () {
      const error = StorageUnavailableException();
      expect(error.message, contains('SUPABASE_URL'));
      expect(error.message, contains('SUPABASE_ANON_KEY'));
    });

    test('bucket matches the out-of-band setup noted in .env.example', () {
      expect(SupabaseStorageService.bucket, 'bahhar-uploads');
    });
  });
}
