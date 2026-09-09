import 'package:flutter/material.dart';
import 'app_colors.dart';

/// BAHHAR Professional Typography Scale
/// Calibrated to LinkedIn & modern enterprise design systems.
/// Clean, dignified sans-serif hierarchy with balanced line heights and semibold accents.
class AppTextStyles {
  // ── Hero & Display ──
  static const TextStyle display = TextStyle(
    fontSize: 26,
    height: 32 / 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  // ── Screen Title (LinkedIn AppBar / Top Level) ──
  static const TextStyle screenTitle = TextStyle(
    fontSize: 19,
    height: 26 / 19,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  // ── Subhead / Section Title ──
  static const TextStyle subhead = TextStyle(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  // ── Group Header (LinkedIn Upper Micro Label) ──
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // ── Card Title ──
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body & Body Medium (LinkedIn Primary Reading Standard) ──
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // ── Labels ──
  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ── Caption & Subtitles ──
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle captionMedium = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ── Micro / Meta ──
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AppColors.textTertiary,
  );

  // ── Legacy Aliases ──
  static const TextStyle h1 = screenTitle;
  static const TextStyle h2 = subhead;
}
