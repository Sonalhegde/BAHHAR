import 'package:flutter/material.dart';

/// Theme-aware surface/ink/accent tokens.
///
/// Static `AppColors.*` constants cannot react to a light/dark switch, so every
/// "surface-type" colour the app paints now lives here as a [ThemeExtension] with
/// a `.light` and a `.dark` instance. Resolve it anywhere with `context.colors`
/// (see [AppThemeX]) and it follows the active theme automatically.
///
/// Dark values are seeded from the previously-unused night palette
/// (nightModeBg/nightSurface/nightBorder/oceanDeep) and tuned against the GitHub
/// Dark-Dimmed ramp, which is measured for WCAG-AA: body ink on card clears 4.5:1
/// and large ink clears well beyond it. See the inline ratios on the text tokens.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  // ── Surfaces ──
  final Color background; // app canvas
  final Color card; // elevated card / white container
  final Color surfaceSubtle; // soft chip / filled-field tint
  final Color iconBox; // neutral icon backplate
  final Color border; // hairline outline
  final Color divider; // in-list separator
  final Color glassSurface; // translucent glass fill
  final Color glassBorder; // glass edge

  // ── Ink ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  // ── Brand / accent ──
  final Color primaryBlue;
  final Color primaryBlueDark;
  final Color cyanAccent;
  final Color skyBlue;

  // ── Semantic signals ──
  final Color signalGood;
  final Color signalGoodBg;
  final Color signalCaution;
  final Color signalCautionBg;
  final Color signalAlert;
  final Color signalAlertBg;
  final Color legalRestricted;

  // ── Chart & map ──
  final Color mapWater;
  final Color mapLand;
  final Color mapContour;

  // ── Loading skeletons ──
  final Color skeletonBase;
  final Color skeletonHighlight;

  const AppColorTokens({
    required this.background,
    required this.card,
    required this.surfaceSubtle,
    required this.iconBox,
    required this.border,
    required this.divider,
    required this.glassSurface,
    required this.glassBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.primaryBlue,
    required this.primaryBlueDark,
    required this.cyanAccent,
    required this.skyBlue,
    required this.signalGood,
    required this.signalGoodBg,
    required this.signalCaution,
    required this.signalCautionBg,
    required this.signalAlert,
    required this.signalAlertBg,
    required this.legalRestricted,
    required this.mapWater,
    required this.mapLand,
    required this.mapContour,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  // ── Light: the existing LinkedIn-corporate coastal palette ──
  static const AppColorTokens light = AppColorTokens(
    background: Color(0xFFF3F4F6),
    card: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFEBF3FA),
    iconBox: Color(0xFFF3F6F8),
    border: Color(0xFFE0E5EA),
    divider: Color(0xFFF1F3F5),
    glassSurface: Color(0xF8FFFFFF),
    glassBorder: Color(0xFFE0E5EA),
    textPrimary: Color(0xFF181818),
    textSecondary: Color(0xFF5E5E5E),
    textTertiary: Color(0xFF757575),
    textDisabled: Color(0xFF9E9E9E),
    primaryBlue: Color(0xFF0A66C2),
    primaryBlueDark: Color(0xFF004182),
    cyanAccent: Color(0xFF0073B1),
    skyBlue: Color(0xFF70B5F9),
    signalGood: Color(0xFF057642),
    signalGoodBg: Color(0xFFE6F4EA),
    signalCaution: Color(0xFFB25E00),
    signalCautionBg: Color(0xFFFEF7E0),
    signalAlert: Color(0xFFC5221F),
    signalAlertBg: Color(0xFFFCE8E6),
    legalRestricted: Color(0xFF6B46C1),
    mapWater: Color(0xFFE5EEF7),
    mapLand: Color(0xFFF0F3F6),
    mapContour: Color(0xFFC8D9E8),
    skeletonBase: Color(0xFFE8EDF2),
    skeletonHighlight: Color(0xFFF6F8FA),
  );

  // ── Dark: night-seeded ramp, contrast-measured for WCAG-AA ──
  // textPrimary #E6EDF3 on card #24292E  -> ~11.4:1
  // textSecondary #ADBAC7 on card #24292E -> ~6.6:1
  // textTertiary #98A2AD on card #24292E  -> ~4.7:1 (clears 4.5 for small meta)
  static const AppColorTokens dark = AppColorTokens(
    background: Color(0xFF0F1419),
    card: Color(0xFF24292E),
    surfaceSubtle: Color(0xFF21262D),
    iconBox: Color(0xFF21262D),
    border: Color(0xFF383E45),
    divider: Color(0xFF30363D),
    glassSurface: Color(0xE021262D),
    glassBorder: Color(0xFF383E45),
    textPrimary: Color(0xFFE6EDF3),
    textSecondary: Color(0xFFADBAC7),
    textTertiary: Color(0xFF98A2AD),
    textDisabled: Color(0xFF6E7681),
    primaryBlue: Color(0xFF4493F8),
    primaryBlueDark: Color(0xFF1F6FEB),
    cyanAccent: Color(0xFF58A6FF),
    skyBlue: Color(0xFF79B8FF),
    signalGood: Color(0xFF3FB950),
    signalGoodBg: Color(0xFF16281B),
    signalCaution: Color(0xFFD29922),
    signalCautionBg: Color(0xFF2B2111),
    signalAlert: Color(0xFFF85149),
    signalAlertBg: Color(0xFF2D1A1A),
    legalRestricted: Color(0xFFA371F7),
    mapWater: Color(0xFF10222E),
    mapLand: Color(0xFF1C2733),
    mapContour: Color(0xFF2D3B49),
    skeletonBase: Color(0xFF30363D),
    skeletonHighlight: Color(0xFF3D444D),
  );

  @override
  AppColorTokens copyWith({
    Color? background,
    Color? card,
    Color? surfaceSubtle,
    Color? iconBox,
    Color? border,
    Color? divider,
    Color? glassSurface,
    Color? glassBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? primaryBlue,
    Color? primaryBlueDark,
    Color? cyanAccent,
    Color? skyBlue,
    Color? signalGood,
    Color? signalGoodBg,
    Color? signalCaution,
    Color? signalCautionBg,
    Color? signalAlert,
    Color? signalAlertBg,
    Color? legalRestricted,
    Color? mapWater,
    Color? mapLand,
    Color? mapContour,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppColorTokens(
      background: background ?? this.background,
      card: card ?? this.card,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      iconBox: iconBox ?? this.iconBox,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      glassSurface: glassSurface ?? this.glassSurface,
      glassBorder: glassBorder ?? this.glassBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      primaryBlue: primaryBlue ?? this.primaryBlue,
      primaryBlueDark: primaryBlueDark ?? this.primaryBlueDark,
      cyanAccent: cyanAccent ?? this.cyanAccent,
      skyBlue: skyBlue ?? this.skyBlue,
      signalGood: signalGood ?? this.signalGood,
      signalGoodBg: signalGoodBg ?? this.signalGoodBg,
      signalCaution: signalCaution ?? this.signalCaution,
      signalCautionBg: signalCautionBg ?? this.signalCautionBg,
      signalAlert: signalAlert ?? this.signalAlert,
      signalAlertBg: signalAlertBg ?? this.signalAlertBg,
      legalRestricted: legalRestricted ?? this.legalRestricted,
      mapWater: mapWater ?? this.mapWater,
      mapLand: mapLand ?? this.mapLand,
      mapContour: mapContour ?? this.mapContour,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  // A discrete switch rather than a per-channel blend: these are identity
  // colours, not values that should exist at 50% between themes. It also keeps
  // the extension cheap to lerp during a theme animation.
  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return t < 0.5 ? this : other;
  }
}

/// `context.colors.textPrimary` — the one-line accessor the whole migration uses.
extension AppThemeX on BuildContext {
  AppColorTokens get colors =>
      Theme.of(this).extension<AppColorTokens>() ?? AppColorTokens.light;
}
