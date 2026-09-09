import 'package:flutter/material.dart';

/// Design tokens — Bahhar AI v2 (Premium White Direction)
class AppColors {
  // ── Surfaces & Backgrounds (White-first, editorial) ──
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF7F7F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color hairline = Color(0xFFE7E7E4);

  // v2 semantic aliases (used throughout screens)
  static const Color surfacePure = bgPrimary;
  static const Color surfaceSubtle = bgSecondary;
  static const Color borderHairline = hairline;

  // ── Typography Inks ──
  static const Color inkPrimary = Color(0xFF1A1A1A);
  static const Color inkSecondary = Color(0xFF6B6B6B);
  static const Color inkTertiary = Color(0xFF9E9E9E);

  // v2 semantic aliases
  static const Color textPrimary = inkPrimary;
  static const Color textSecondary = inkSecondary;
  static const Color textTertiary = inkTertiary;

  // ── Single Brand Accent ──
  static const Color accentNavy = Color(0xFF12263A);

  // ── Signal Colors (muted, desaturated) ──
  static const Color signalGood = Color(0xFF2E7D5B);
  static const Color signalCaution = Color(0xFFB8862E);
  static const Color signalAlert = Color(0xFFB23A2E);

  // ── Regulatory Marine Zones ──
  static const Color legalRestricted = Color(0xFF6B5B95);
  static const Color legalPermitted = Color(0xFF2E7D5B);

  // ── Map / Chart ──
  static const Color mapWater = Color(0xFFE5E9EC);

  // ── Night Mode ──
  static const Color nightModeBg = Color(0xFF0D0D0D);
  static const Color nightSurface = Color(0xFF141414);
  static const Color nightBorder = Color(0xFF222222);

  // Legacy backward-compat aliases
  static const Color deepSea = accentNavy;
  static const Color oceanBlue = accentNavy;
  static const Color aquaTeal = signalGood;
  static const Color sandGold = signalCaution;
  static const Color coralRed = signalAlert;
  static const Color deepNavyText = inkPrimary;
  static const Color mistGray = bgSecondary;
  static const Color borderGray = hairline;
  static const Color protectedArea = legalRestricted;
  static const Color restrictedZone = legalRestricted;
  static const Color permittedZone = legalPermitted;

  static Color getProbabilityColor(int probability) {
    if (probability >= 70) return signalGood;
    if (probability >= 40) return signalCaution;
    return signalAlert;
  }

  static String getProbabilityLabel(int probability) {
    if (probability >= 70) return 'Favorable';
    if (probability >= 40) return 'Moderate';
    return 'Low Opportunity';
  }
}
