import 'package:flutter/material.dart';
import 'app_colors.dart';

/// BAHHAR Professional Typography Scale
/// Pair-set with the Plus Jakarta Sans / Cairo brand typefaces.
/// Confident display weights, tight negative tracking on large sizes,
/// generous line heights on body copy for comfortable marine data reading.
class AppTextStyles {
  // ── Hero & Display ──
  static const TextStyle display = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.7,
    color: AppColors.textPrimary,
  );

  // ── Big numeric readouts (gauge scores, stats) ──
  static const TextStyle stat = TextStyle(
    fontSize: 34,
    height: 1.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
  );

  // ── Screen Title (Top Level) ──
  static const TextStyle screenTitle = TextStyle(
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  // ── Subhead / Section Title ──
  static const TextStyle subhead = TextStyle(
    fontSize: 17,
    height: 23 / 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  // ── Group Header (Upper Micro Label) ──
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 11.5,
    height: 16 / 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
    color: AppColors.textSecondary,
  );

  // ── Card Title ──
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15.5,
    height: 21 / 15.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.15,
    color: AppColors.textPrimary,
  );

  // ── Body & Body Medium (Primary Reading Standard) ──
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.05,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.05,
    color: AppColors.textPrimary,
  );

  // ── Labels ──
  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // ── Caption & Subtitles ──
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: AppColors.textSecondary,
  );

  static const TextStyle captionMedium = TextStyle(
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textSecondary,
  );

  // ── Micro / Meta ──
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.textTertiary,
  );

  // ── Legacy Aliases ──
  static const TextStyle h1 = screenTitle;
  static const TextStyle h2 = subhead;
}
