import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color_tokens.dart';
import 'app_text_styles.dart';

/// BAHHAR Coastal theme pair.
///
/// Typography is powered by Google Fonts:
/// - English: Plus Jakarta Sans (geometric humanist sans, modern product feel)
/// - Arabic : Cairo (full Arabic + Latin coverage, matched weight rhythm)
///
/// Both a genuine light and dark [ThemeData] are produced from a single
/// [_build]; the only thing that changes is the [AppColorTokens] instance and
/// the [Brightness], so the surface/ink ramp stays coherent across modes.
class AppTheme {
  static ThemeData _build(
    Brightness brightness,
    AppColorTokens tokens,
    bool isArabic,
  ) {
    // Seed the Material scheme off the brand blue but pin the surface/ink roles
    // to the token ramp so bare Text() and Material widgets land on the exact
    // contrast-measured colours rather than fromSeed's auto-derived neutrals.
    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.primaryBlue,
      brightness: brightness,
    ).copyWith(
      surface: tokens.card,
      onSurface: tokens.textPrimary,
      onSurfaceVariant: tokens.textSecondary,
      primary: tokens.primaryBlue,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.background,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // AppBar paints titleTextStyle verbatim, so it must carry an explicit
        // colour — a stripped (null) colour here would not fall back cleanly.
        titleTextStyle:
            AppTextStyles.subhead.copyWith(color: tokens.textPrimary),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 1,
        space: 1,
      ),
    );

    // Swap the whole Material text scale onto the brand typeface so every
    // custom TextStyle (which leaves fontFamily null) inherits it via
    // DefaultTextStyle merging.
    final textTheme = isArabic
        ? GoogleFonts.cairoTextTheme(base.textTheme)
        : GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData coastalLightTheme({bool isArabic = false}) =>
      _build(Brightness.light, AppColorTokens.light, isArabic);

  static ThemeData coastalDarkTheme({bool isArabic = false}) =>
      _build(Brightness.dark, AppColorTokens.dark, isArabic);

  // ── Backward-compat accessors (kept so old references don't break) ──
  static ThemeData get lightTheme => coastalLightTheme();
  static ThemeData get darkTheme => coastalDarkTheme();
  static ThemeData get marineDarkTheme => coastalLightTheme();
}
