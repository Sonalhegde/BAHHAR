import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get marineDarkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.oceanAbyss,
    colorSchemeSeed: AppColors.cyanAccent,
    canvasColor: AppColors.oceanDeep,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.subhead,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.12),
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: AppColors.glassStandard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
    ),
  );

  static ThemeData get darkTheme => marineDarkTheme;
  static ThemeData get lightTheme => marineDarkTheme;
}
