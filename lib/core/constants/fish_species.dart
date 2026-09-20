/// Target commercial and game fish species found in Omani waters.
///
/// Each species carries production metadata used across the app: bilingual
/// display names, bathymetric and sea-surface-temperature preferences,
/// seasonal availability windows and the bundled artwork asset. The
/// [FishSpeciesX] extension is the single source of truth — screens and the
/// ML heuristic must read from here rather than hard-coding literals.
enum FishSpecies {
  kingfish,      // الكنعد
  yellowfinTuna, // الثمد (تونة صفراء الزعانف)
  queenfish,     // الحمام (الضلعة)
  hammour,       // الهامور (Grouper)
  mahiMahi,      // العنفلوص (Dorado)
  sailfish,      // الشراع
  barracuda,     // القد
  trevally,      // الضلعة / البياض
}

/// Month ranges (1 = January) a species is reliably targeted in Omani waters.
/// A range that starts after its end wraps across the year boundary.
class SeasonRange {
  final int startMonth;
  final int endMonth;

  const SeasonRange(this.startMonth, this.endMonth);

  /// Full-year range constant.
  static const SeasonRange yearRound = SeasonRange(1, 12);

  bool contains(int month) {
    final m = month.clamp(1, 12);
    if (startMonth <= endMonth) return m >= startMonth && m <= endMonth;
    // Wrapping range, e.g. Oct (10) → Apr (4).
    return m >= startMonth || m <= endMonth;
  }

  /// Short bilingual label, e.g. "Oct–Apr" / "أكتوبر–أبريل".
  String label({bool isArabic = false}) {
    const en = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const ar = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    final names = isArabic ? ar : en;
    return '${names[startMonth - 1]}–${names[endMonth - 1]}';
  }
}

/// Inclusive sea-surface-temperature band (°C) where the species feeds hard.
class TempRange {
  final double minC;
  final double maxC;

  const TempRange(this.minC, this.maxC);

  bool contains(double tempC) => tempC >= minC && tempC <= maxC;

  String get label => '${minC.round()}–${maxC.round()}°C';
}

/// Inclusive preferred depth band (meters).
class DepthRange {
  final int minM;
  final int maxM;

  const DepthRange(this.minM, this.maxM);

  bool contains(int depthMeters) =>
      depthMeters >= minM && depthMeters <= maxM;

  String get label => '$minM–$maxM m';
}

/// Metadata + lookup helpers for [FishSpecies].
extension FishSpeciesX on FishSpecies {
  /// English display label matching the hotspot catalogue strings
  /// (`HotspotModel.targetSpecies`).
  String get displayName {
    switch (this) {
      case FishSpecies.kingfish:
        return 'Kingfish';
      case FishSpecies.yellowfinTuna:
        return 'Yellowfin Tuna';
      case FishSpecies.queenfish:
        return 'Queenfish';
      case FishSpecies.hammour:
        return 'Hammour';
      case FishSpecies.mahiMahi:
        return 'Mahi-Mahi';
      case FishSpecies.sailfish:
        return 'Sailfish';
      case FishSpecies.barracuda:
        return 'Barracuda';
      case FishSpecies.trevally:
        return 'Trevally';
    }
  }

  /// Arabic display name (Omani common names).
  String get nameAr {
    switch (this) {
      case FishSpecies.kingfish:
        return 'الكنعد';
      case FishSpecies.yellowfinTuna:
        return 'الثمد';
      case FishSpecies.queenfish:
        return 'الحمام';
      case FishSpecies.hammour:
        return 'الهامور';
      case FishSpecies.mahiMahi:
        return 'العنفلوص';
      case FishSpecies.sailfish:
        return 'الشراع';
      case FishSpecies.barracuda:
        return 'القد';
      case FishSpecies.trevally:
        return 'الضلعة';
    }
  }

  String get scientificName {
    switch (this) {
      case FishSpecies.kingfish:
        return 'Scomberomorus commerson';
      case FishSpecies.yellowfinTuna:
        return 'Thunnus albacares';
      case FishSpecies.queenfish:
        return 'Scomberomorus queenslandicus';
      case FishSpecies.hammour:
        return 'Variola albimarginata';
      case FishSpecies.mahiMahi:
        return 'Coryphaena hippurus';
      case FishSpecies.sailfish:
        return 'Istiophorus platypterus';
      case FishSpecies.barracuda:
        return 'Sphyraena barracuda';
      case FishSpecies.trevally:
        return 'Caranx ignobilis';
    }
  }

  /// Bundled artwork under assets/images/ (webp ships with the app).
  String get assetPath {
    switch (this) {
      case FishSpecies.kingfish:
        return 'assets/images/fish-kingfish.webp';
      case FishSpecies.yellowfinTuna:
        return 'assets/images/fish-tuna.webp';
      case FishSpecies.queenfish:
        return 'assets/images/fish-snapper.webp';
      case FishSpecies.hammour:
        return 'assets/images/fish-hammour.webp';
      case FishSpecies.mahiMahi:
        return 'assets/images/fish-grouper.webp';
      case FishSpecies.sailfish:
        return 'assets/images/fish-sailfish.webp';
      case FishSpecies.barracuda:
        return 'assets/images/fish-barracuda.webp';
      case FishSpecies.trevally:
        return 'assets/images/fish-cobia.webp';
    }
  }

  /// Optimal sea-surface temperature band for aggressive feeding.
  TempRange get optimalTemp {
    switch (this) {
      case FishSpecies.kingfish:
        return const TempRange(24.0, 29.0);
      case FishSpecies.yellowfinTuna:
        return const TempRange(26.0, 31.0);
      case FishSpecies.queenfish:
        return const TempRange(25.0, 30.0);
      case FishSpecies.hammour:
        return const TempRange(25.5, 30.5);
      case FishSpecies.mahiMahi:
        return const TempRange(24.0, 29.5);
      case FishSpecies.sailfish:
        return const TempRange(24.5, 29.0);
      case FishSpecies.barracuda:
        return const TempRange(23.5, 30.0);
      case FishSpecies.trevally:
        return const TempRange(24.0, 30.5);
    }
  }

  /// Preferred depth band over Omani shelf and drop-offs.
  DepthRange get preferredDepth {
    switch (this) {
      case FishSpecies.kingfish:
        return const DepthRange(5, 80);
      case FishSpecies.yellowfinTuna:
        return const DepthRange(40, 150);
      case FishSpecies.queenfish:
        return const DepthRange(8, 60);
      case FishSpecies.hammour:
        return const DepthRange(15, 90);
      case FishSpecies.mahiMahi:
        return const DepthRange(10, 60);
      case FishSpecies.sailfish:
        return const DepthRange(20, 120);
      case FishSpecies.barracuda:
        return const DepthRange(3, 50);
      case FishSpecies.trevally:
        return const DepthRange(5, 75);
    }
  }

  /// Prime season in Omani waters (Monsoon and Khareef aware).
  SeasonRange get season {
    switch (this) {
      case FishSpecies.kingfish:
        return const SeasonRange(10, 4); // Oct–Apr, peaks Nov–Feb
      case FishSpecies.yellowfinTuna:
        return const SeasonRange(5, 11); // May–Nov
      case FishSpecies.queenfish:
        return const SeasonRange(3, 10); // Mar–Oct
      case FishSpecies.hammour:
        return SeasonRange.yearRound;
      case FishSpecies.mahiMahi:
        return const SeasonRange(9, 3); // Sep–Mar
      case FishSpecies.sailfish:
        return const SeasonRange(10, 4); // Oct–Apr
      case FishSpecies.barracuda:
        return SeasonRange.yearRound;
      case FishSpecies.trevally:
        return SeasonRange.yearRound;
    }
  }

  /// Short bilingual season label for chips and cards.
  String seasonLabel({bool isArabic = false}) => season.label(isArabic: isArabic);

  bool isAvailableIn(int month) => season.contains(month);

  /// True when the species is in season for the current calendar month.
  bool get inSeasonNow => isAvailableIn(DateTime.now().month);

  /// Matches a catalogue or user-typed label such as 'Yellowfin Tuna',
  /// 'كنعد' or 'mahi mahi'. Returns null for unknown names.
  static FishSpecies? tryParse(String raw) {
    final key = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[-_\s]+'), '')
        .trim();
    if (key.isEmpty) return null;
    for (final species in FishSpecies.values) {
      final candidates = <String>{
        species.displayName.toLowerCase().replaceAll(RegExp(r'[-\s]+'), ''),
        species.nameAr,
        species.scientificName.split(' ').first.toLowerCase(),
        species.name.toLowerCase(),
      };
      if (candidates.contains(key)) return species;
    }
    // Common aliases used across the hotspot catalogue and seed data.
    const aliases = <String, FishSpecies>{
      'tuna': FishSpecies.yellowfinTuna,
      'grouper': FishSpecies.hammour,
      'amberjack': FishSpecies.trevally,
      'dorado': FishSpecies.mahiMahi,
      'dongola': FishSpecies.kingfish,
      'sharkisland': FishSpecies.kingfish,
    };
    return aliases[key];
  }
}
