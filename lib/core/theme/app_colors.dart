import 'package:flutter/material.dart';

/// BAHHAR Modern Marine-Tech Design System (Reference Direction)
class AppColors {
  // ── Primary Brand & Oceanic Palette ──
  static const Color primaryBlue = Color(0xFF0066CC);      // Vibrant royal ocean blue from reference
  static const Color primaryBlueDark = Color(0xFF0052A3);  // Pressed state
  static const Color primaryBlueLight = Color(0xFFE8F1FC); // Soft blue tint for chips/toggles
  static const Color oceanNavy = Color(0xFF0F2644);        // Deep coastal navy for text & structure
  static const Color cyanAccent = Color(0xFF0284C7);       // Cyan highlight / secondary
  static const Color skyBlue = Color(0xFF38BDF8);          // Light sky accent

  // ── Background & Coastal Atmospheric Canvas ──
  static const Color bgGradientTop = Color(0xFFF8FAFD);    // Crisp light mist sky
  static const Color bgGradientMid = Color(0xFFEFF5FC);    // Mid coastal air
  static const Color bgGradientBottom = Color(0xFFDCEBFA); // Bottom ocean swell
  static const Color mountainSilhouette = Color(0xFFC7DEFA);// Layered coastal mountain headlands
  static const Color waveLayer = Color(0xFFB9D8F7);        // Foreground ocean waves

  // ── Glassmorphism Surfaces ──
  static const Color glassSurface = Color(0xE6FFFFFF);     // 90% white frosted glass
  static const Color glassSurfaceLight = Color(0x99FFFFFF);// 60% translucent glass
  static const Color glassSurfaceDense = Color(0xF5FFFFFF);// 96% high-contrast glass
  static const Color glassBorder = Color(0x66FFFFFF);      // Crisp translucent border
  static const Color glassBorderSubtle = Color(0x33B4D3F2);// Soft oceanic border outline

  // ── Typography & Ink ──
  static const Color textPrimary = Color(0xFF0F172A);      // Deep slate black
  static const Color textSecondary = Color(0xFF475569);    // Nautical slate gray
  static const Color textTertiary = Color(0xFF94A3B8);     // Muted micro metadata
  static const Color textBlue = Color(0xFF0066CC);         // Brand accent text

  // ── Semantic Signals ──
  static const Color signalGood = Color(0xFF10B981);       // Emerald Green: Favorable / High Bite
  static const Color signalCaution = Color(0xFFF59E0B);    // Warm Amber: Moderate Opportunity
  static const Color signalAlert = Color(0xFFEF4444);      // Coral Red: Danger / Restricted
  static const Color legalRestricted = Color(0xFF8B5CF6);  // Desaturated Violet: Nature Reserves (Daymaniyat)
  static const Color legalPermitted = Color(0xFF10B981);   // Open Waters

  // ── Chart & Map Colors ──
  static const Color mapWater = Color(0xFFE0EDFB);         // Soft nautical chart water
  static const Color mapLand = Color(0xFFF0F4F8);          // Landmass
  static const Color mapContour = Color(0xFFBED8F3);       // Bathymetric depth lines

  // ── Backwards Compatibility Aliases ──
  static const Color bgPrimary = bgGradientTop;
  static const Color bgSecondary = bgGradientMid;
  static const Color cardWhite = glassSurface;
  static const Color hairline = glassBorderSubtle;
  static const Color surfacePure = glassSurfaceDense;
  static const Color surfaceSubtle = primaryBlueLight;
  static const Color borderHairline = glassBorderSubtle;
  static const Color inkPrimary = textPrimary;
  static const Color inkSecondary = textSecondary;
  static const Color inkTertiary = textTertiary;
  static const Color accentNavy = primaryBlue;
  static const Color deepSea = oceanNavy;
  static const Color oceanBlue = primaryBlue;
  static const Color aquaTeal = signalGood;
  static const Color sandGold = signalCaution;
  static const Color coralRed = signalAlert;
  static const Color deepNavyText = textPrimary;
  static const Color mistGray = bgGradientMid;
  static const Color borderGray = glassBorderSubtle;
  static const Color protectedArea = legalRestricted;
  static const Color restrictedZone = legalRestricted;
  static const Color permittedZone = legalPermitted;
  static const Color nightModeBg = Color(0xFF081524);
  static const Color nightSurface = Color(0xFF0F243B);
  static const Color nightBorder = Color(0xFF1F3A58);
  static const Color oceanAbyss = Color(0xFF061423);
  static const Color oceanDeep = Color(0xFF0A1D31);
  static const Color cyanBright = primaryBlue;
  static const Color seafoam = Color(0xFFBAE6FD);
  static const Color glassSubtle = Color(0x40FFFFFF);
  static const Color glassStandard = Color(0xCCFFFFFF);
  static const Color glassProminent = Color(0xF2FFFFFF);
  static const Color glassBorderGlow = Color(0x660066CC);

  // ── Probability Helpers ──
  static Color getProbabilityColor(int probability) {
    if (probability >= 70) return signalGood;
    if (probability >= 40) return signalCaution;
    return signalAlert;
  }

  static String getProbabilityLabel(int probability) {
    if (probability >= 70) return 'Optimal Bite';
    if (probability >= 40) return 'Moderate Activity';
    return 'Low Opportunity';
  }
}
