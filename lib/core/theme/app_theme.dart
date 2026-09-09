import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get coastalLightTheme => ThemeData(
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

  static ThemeData get lightTheme => coastalLightTheme;
  static ThemeData get darkTheme => coastalLightTheme;
  // backward-compat alias kept so old references don't break
  static ThemeData get marineDarkTheme => coastalLightTheme;
}
