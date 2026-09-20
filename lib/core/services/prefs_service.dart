import 'package:shared_preferences/shared_preferences.dart';

/// Device-local settings that must survive a restart: language, the port the
/// fisherman fishes from, and whether readings print in metric or nautical units.
///
/// These are deliberately NOT in Firestore. Language and units are about the phone,
/// not the fisherman — a shared device and a personal one want different answers, and
/// a setting that syncs can be changed by whoever else signs in on this handset.
///
/// Every getter is safe to call before [init]: an uninitialised service returns the
/// same defaults the app has always started with, so a widget test that never touched
/// shared_preferences behaves exactly like a first run on a real device, and nothing
/// in the UI has to handle a missing preferences layer.
class PrefsService {
  static const String keyLanguageArabic = 'settings.language_arabic';
  static const String keyGovernorate = 'settings.governorate';
  static const String keyMetricUnits = 'settings.metric_units';

  /// Muscat is the app's default view, not a guess about the user.
  static const String defaultGovernorate = 'Muscat';

  static SharedPreferences? _prefs;

  /// Awaited once, in [main], before the first frame. Safe to call twice.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// True once [init] has completed. Tests and `flutter test` runs leave it false.
  static bool get isReady => _prefs != null;

  static bool getArabic() => _prefs?.getBool(keyLanguageArabic) ?? false;

  static Future<void> setArabic(bool value) async {
    await _prefs?.setBool(keyLanguageArabic, value);
  }

  static String getGovernorate() =>
      _prefs?.getString(keyGovernorate) ?? defaultGovernorate;

  static Future<void> setGovernorate(String value) async {
    await _prefs?.setString(keyGovernorate, value);
  }

  /// Defaults to metric because every existing screen was drawn in metric; the
  /// toggle exists so a fisherman can leave it that way or not.
  static bool getMetricUnits() => _prefs?.getBool(keyMetricUnits) ?? true;

  static Future<void> setMetricUnits(bool value) async {
    await _prefs?.setBool(keyMetricUnits, value);
  }

  // ── Guest catch queue ───────────────────────────────────────────────────────

  /// Catches logged before signing in, held as encoded JSON until there is an account
  /// to write them under.
  ///
  /// What survives the restart is the record — species, weight, position, time, tide.
  /// A photo taken during a guest session is not queued: its file belongs to a
  /// session that has already ended, and a log entry that silently loses its picture
  /// is better than one that silently loses the catch.
  static const String keyGuestCatches = 'catches.guest_queue';

  static List<String> getGuestCatchQueue() =>
      _prefs?.getStringList(keyGuestCatches) ?? const [];

  static Future<void> addGuestCatch(String encodedCatch) async {
    final queue = [...getGuestCatchQueue(), encodedCatch];
    await _prefs?.setStringList(keyGuestCatches, queue);
  }

  static Future<void> setGuestCatchQueue(List<String> queue) async {
    if (queue.isEmpty) {
      await _prefs?.remove(keyGuestCatches);
      return;
    }
    await _prefs?.setStringList(keyGuestCatches, queue);
  }
}
