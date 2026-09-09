import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography scale — Bahhar AI v2 (Section 4.2)
/// Clean normal sans-serif, lining tabular figures, restrained weight ladder.
class AppTextStyles {
  // ── Display / Hero numeral ──
  static const TextStyle display = TextStyle(
    fontSize: 30,
    height: 38 / 30,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.5,
    color: AppColors.inkPrimary,
  );

  // ── Screen title (large heading) ──
  static const TextStyle screenTitle = TextStyle(
    fontSize: 22,
    height: 30 / 22,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.3,
    color: AppColors.inkPrimary,
  );

  // ── Subhead (AppBar / section heading) ──
  static const TextStyle subhead = TextStyle(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.2,
    color: AppColors.inkPrimary,
  );

  // ── Section header (uppercase micro label) ──
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: 1.0,
    color: AppColors.inkSecondary,
  );

  // ── Card title ──
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.inkPrimary,
  );

  // ── Body / body medium ──
  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.inkPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.inkPrimary,
  );

  // ── Label medium / small ──
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.inkPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.inkPrimary,
  );

  // ── Caption ──
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.inkSecondary,
  );

  static const TextStyle captionMedium = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.inkSecondary,
  );

  // ── Micro ──
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: 0.2,
    color: AppColors.inkSecondary,
  );

  // Legacy aliases
  static const TextStyle h1 = screenTitle;
  static const TextStyle h2 = subhead;
}
