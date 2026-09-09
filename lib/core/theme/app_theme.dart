import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App theme configurations (Light & Dark)
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      // TODO: Define component themes (buttons, cards, inputs)
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      // TODO: Define component themes for dark mode
    );
  }
}
