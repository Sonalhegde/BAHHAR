/// Application-wide configuration constants.
///
/// Values here are pure, compile-time configuration shared across features so
/// magic numbers/strings live in one place. Anything secret (API keys, tokens)
/// is intentionally NOT here — those are injected at build time via
/// `String.fromEnvironment` / `--dart-define` or read server-side only.
class AppConstants {
  AppConstants._();

  // ── Branding ──
  static const String appName = 'BAHHAR';
  static const String appNameAr = 'بَحّار';
  static const String appTagline = 'Oman Smart Marine & Fishing Companion';
  static const String appTaglineAr = 'الرفيق الذكي للصيد في عُمان';
  static const String appVersion = '1.0.0';

  // ── Localisation ──
  static const String defaultLocale = 'en';
  static const String arabicLocale = 'ar';
  static const List<String> supportedLocales = <String>[defaultLocale, arabicLocale];

  // ── Oman geography defaults ──
  /// Mutrah/Seeb coastal waters — the app's default map focus.
  static const double defaultLatitude = 23.6143;
  static const double defaultLongitude = 58.5453;
  static const double defaultZoom = 8.2;

  /// Oman's international dialling code and the length of a mobile number
  /// (excluding the country code).
  static const String omanCountryCode = '+968';
  static const int omanMobileLength = 8;
  static const int omanMobileMinLength = 7;

  // ── Auth ──
  static const int otpLength = 6;
  static const int minPasswordLength = 6;
  static const Duration otpResendCooldown = Duration(seconds: 30);

  // ── Network / API (Master Build Prompt §4, §9) ──
  /// Default FastAPI base when no `--dart-define=ML_API_BASE_URL` is supplied.
  static const String defaultApiBaseUrl = 'http://localhost:8000';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration marineTimeout = Duration(seconds: 15);

  // ── Marine freshness (matches MarineService.staleAfter) ──
  static const Duration marineStaleAfter = Duration(hours: 1);

  // ── Motion (shared entrance choreography) ──
  static const Duration fastAnim = Duration(milliseconds: 150);
  static const Duration mediumAnim = Duration(milliseconds: 400);
  static const Duration entranceAnim = Duration(milliseconds: 560);
  static const Duration gaugeSweep = Duration(milliseconds: 1100);

  // ── Layout ──
  /// Breakpoint (logical px) at which the shell switches from the compact
  /// bottom nav to the wide side-rail navigation.
  static const double wideLayoutBreakpoint = 720;
  static const double maxContentWidth = 420;

  // ── Legal ──
  static const String fisheriesNotice =
      'By continuing, you agree to Oman Marine & Fishery Regulations.';
  static const String fisheriesNoticeAr =
      'بالمتابعة فإنك توافق على لوائح حماية الثروة السمكية في سلطنة عُمان';
}
