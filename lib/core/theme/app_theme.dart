import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// BAHHAR Coastal Light Theme
/// Typography is powered by Google Fonts:
/// - English: Plus Jakarta Sans (geometric humanist sans, modern product feel)
/// - Arabic : Cairo (full Arabic + Latin coverage, matched weight rhythm)
class AppTheme {
  static ThemeData coastalLightTheme({bool isArabic = false}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgGradientTop,
      colorSchemeSeed: AppColors.primaryBlue,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.oceanNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.subhead,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2EDF8),
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

  static ThemeData get lightTheme => coastalLightTheme();
  static ThemeData get darkTheme => coastalLightTheme();
  // backward-compat alias kept so old references don't break
  static ThemeData get marineDarkTheme => coastalLightTheme();
}
