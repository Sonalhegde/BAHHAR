import 'package:flutter/material.dart';

/// BAHHAR Professional Marine Design System
/// Calibrated to human-designed institutional & enterprise standards (LinkedIn/GCC corporate palette).
/// Restrained ink tones, neutral icon backgrounds, zero AI hyper-saturation.
class AppColors {
  // ── Primary Brand & Corporate Marine Palette ──
  static const Color primaryBlue = Color(0xFF0A66C2);      // LinkedIn corporate blue / Trustworthy marine
  static const Color primaryBlueDark = Color(0xFF004182);  // Pressed / active deep state
  static const Color primaryBlueLight = Color(0xFFEBF3FA); // Soft refined blue tint for chips
  static const Color oceanNavy = Color(0xFF181818);        // Deep charcoal primary ink (LinkedIn standard)
  static const Color cyanAccent = Color(0xFF0073B1);       // Subdued accent
  static const Color skyBlue = Color(0xFF70B5F9);          // Light accent

  // ── Professional Canvas & Backgrounds (LinkedIn Warm Neutral) ──
  static const Color bgGradientTop = Color(0xFFF3F4F6);    // Clean professional background canvas
  static const Color bgGradientMid = Color(0xFFF1F3F5);    // Mid neutral
  static const Color bgGradientBottom = Color(0xFFE8ECEF); // Soft transition
  static const Color surfaceCanvas = Color(0xFFF3F4F6);    // Main scaffold background
  static const Color cardBackground = Color(0xFFFFFFFF);   // Pure white card container
  static const Color mountainSilhouette = Color(0xFFDDE3EA);// Muted coastal headlands
  static const Color waveLayer = Color(0xFFD0DBE5);        // Low-contrast wave layer

  // ── Neutral Icon Box Palette (Unified, Non-AI) ──
  static const Color iconBoxNeutral = Color(0xFFF3F6F8);   // Uniform institutional neutral box
  static const Color iconForeground = Color(0xFF374151);   // Slate-charcoal icon color (unified)
  static const Color iconBrandForeground = Color(0xFF0A66C2);// Corporate brand icon color

  // ── Surfaces & Borders ──
  static const Color surfacePure = Color(0xFFFFFFFF);
  static const Color borderHairline = Color(0xFFE0E5EA);   // LinkedIn 1px hairline border
  static const Color dividerColor = Color(0xFFF1F3F5);     // Subtle item divider
  static const Color glassSurface = Color(0xF8FFFFFF);     // Subdued high-contrast white
  static const Color glassSurfaceDense = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0xFFE0E5EA);
  static const Color glassBorderSubtle = Color(0xFFE8ECEF);

  // ── Typography & Ink (Calibrated to LinkedIn Specifications) ──
  static const Color textPrimary = Color(0xFF181818);      // rgba(0, 0, 0, 0.9) - deep charcoal
  static const Color textSecondary = Color(0xFF5E5E5E);    // rgba(0, 0, 0, 0.6) - secondary subtitle
  static const Color textTertiary = Color(0xFF757575);     // rgba(0, 0, 0, 0.45) - metadata / captions
  static const Color textBlue = Color(0xFF0A66C2);         // Action / link ink
  static const Color textDisabled = Color(0xFF9E9E9E);     // Inactive text

  // ── Semantic Signals (Calibrated Corporate Tones) ──
  static const Color signalGood = Color(0xFF057642);       // LinkedIn emerald: Verified / Favorable
  static const Color signalGoodBg = Color(0xFFE6F4EA);     // Soft green tint
  static const Color signalCaution = Color(0xFFB25E00);    // Warm amber: Warning / Expiring
  static const Color signalCautionBg = Color(0xFFFEF7E0);  // Soft amber tint
  static const Color signalAlert = Color(0xFFC5221F);      // Formal alert crimson: Destructive
  static const Color signalAlertBg = Color(0xFFFCE8E6);    // Soft red tint
  static const Color legalRestricted = Color(0xFF6B46C1);  // Subdued purple: Marine Reserve
  static const Color legalPermitted = Color(0xFF057642);   // Open Waters

  // ── Chart & Map Colors ──
  static const Color mapWater = Color(0xFFE5EEF7);
  static const Color mapLand = Color(0xFFF0F3F6);
  static const Color mapContour = Color(0xFFC8D9E8);

  // ── Loading Skeletons ──
  static const Color skeletonBase = Color(0xFFE8EDF2);
  static const Color skeletonHighlight = Color(0xFFF6F8FA);

  // ── Compatibility Aliases ──
  static const Color bgPrimary = bgGradientTop;
  static const Color bgSecondary = bgGradientMid;
  static const Color cardWhite = cardBackground;
  static const Color hairline = borderHairline;
  static const Color surfaceSubtle = primaryBlueLight;
  static const Color borderGray = borderHairline;
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
  static const Color protectedArea = legalRestricted;
  static const Color restrictedZone = legalRestricted;
  static const Color permittedZone = legalPermitted;
  static const Color nightModeBg = Color(0xFF1B1F23);
  static const Color nightSurface = Color(0xFF24292E);
  static const Color nightBorder = Color(0xFF383E45);
  static const Color oceanAbyss = Color(0xFF181818);
  static const Color oceanDeep = Color(0xFF21262D);
  static const Color cyanBright = primaryBlue;
  static const Color seafoam = Color(0xFFDDF0FF);
  static const Color glassSubtle = Color(0x60FFFFFF);
  static const Color glassStandard = Color(0xE0FFFFFF);
  static const Color glassProminent = Color(0xFFFFFFFF);
  static const Color glassBorderGlow = Color(0x330A66C2);

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
