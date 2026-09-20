/// Coastal governorates across the Sultanate of Oman, ordered north → south.
///
/// The [OmaniRegionX] extension attaches production metadata used by the map,
/// trip planner and hotspot filters: an Arabic name, a representative coastal
/// anchor point, a coastline bounding box (south-west / north-east corners)
/// and the offshore maritime zone the waters fall under (Gulf of Oman,
/// Arabian Sea or the Strait of Hormuz).
enum OmaniRegion {
  musandam,
  alBatinahNorth,
  alBatinahSouth,
  muscat,
  ashSharqiyahSouth,
  alWusta,
  dhofar,
}

/// A latitude/longitude pair. Kept dependency-free so constants stay pure Dart
/// (the map layer converts to `maplibre_gl.LatLng` at the edge).
class GeoPoint {
  final double lat;
  final double lon;

  const GeoPoint(this.lat, this.lon);
}

/// Rectangular coastline bounds (SW + NE corners) for camera framing.
class CoastBounds {
  final GeoPoint southWest;
  final GeoPoint northEast;

  const CoastBounds(this.southWest, this.northEast);

  /// Centre point, handy for `CameraPosition.target`.
  GeoPoint get center => GeoPoint(
        (southWest.lat + northEast.lat) / 2,
        (southWest.lon + northEast.lon) / 2,
      );

  /// Longitude span in degrees.
  double get lonSpan => (northEast.lon - southWest.lon).abs();

  /// Latitude span in degrees.
  double get latSpan => (northEast.lat - southWest.lat).abs();

  /// True when [point] falls inside the box (inclusive).
  bool contains(GeoPoint point) =>
      point.lat >= southWest.lat &&
      point.lat <= northEast.lat &&
      point.lon >= southWest.lon &&
      point.lon <= northEast.lon;
}

/// The offshore water body governing a region's sea state and species mix.
enum MaritimeZone {
  straitOfHormuz,
  gulfOfOman,
  arabianSea,
}

extension OmaniRegionX on OmaniRegion {
  String get displayName {
    switch (this) {
      case OmaniRegion.musandam:
        return 'Musandam';
      case OmaniRegion.alBatinahNorth:
        return 'Al Batinah North';
      case OmaniRegion.alBatinahSouth:
        return 'Al Batinah South';
      case OmaniRegion.muscat:
        return 'Muscat';
      case OmaniRegion.ashSharqiyahSouth:
        return 'Ash Sharqiyah South';
      case OmaniRegion.alWusta:
        return 'Al Wusta';
      case OmaniRegion.dhofar:
        return 'Dhofar';
    }
  }

  String get nameAr {
    switch (this) {
      case OmaniRegion.musandam:
        return 'مسندم';
      case OmaniRegion.alBatinahNorth:
        return 'شمال الباطنة';
      case OmaniRegion.alBatinahSouth:
        return 'جنوب الباطنة';
      case OmaniRegion.muscat:
        return 'مسقط';
      case OmaniRegion.ashSharqiyahSouth:
        return 'جنوب الشرقية';
      case OmaniRegion.alWusta:
        return 'الوسطى';
      case OmaniRegion.dhofar:
        return 'ظفار';
    }
  }

  /// Representative coastal anchor (harbour / landing site) for markers.
  GeoPoint get anchor {
    switch (this) {
      case OmaniRegion.musandam:
        return const GeoPoint(26.2270, 56.2500); // Khasab
      case OmaniRegion.alBatinahNorth:
        return const GeoPoint(24.3500, 56.7500); // Shinas
      case OmaniRegion.alBatinahSouth:
        return const GeoPoint(23.8617, 58.0933); // Daymaniyat approach
      case OmaniRegion.muscat:
        return const GeoPoint(23.6143, 58.5453); // Mutrah / Seeb
      case OmaniRegion.ashSharqiyahSouth:
        return const GeoPoint(22.5367, 59.8153); // Ras Al Hadd
      case OmaniRegion.alWusta:
        return const GeoPoint(20.4500, 58.7500); // Masirah channel
      case OmaniRegion.dhofar:
        return const GeoPoint(16.9833, 54.7000); // Mirbat
    }
  }

  /// Coastline + near-shore waters bounding box for map camera framing.
  CoastBounds get coastBounds {
    switch (this) {
      case OmaniRegion.musandam:
        return const CoastBounds(GeoPoint(25.85, 56.00), GeoPoint(26.65, 56.60));
      case OmaniRegion.alBatinahNorth:
        return const CoastBounds(GeoPoint(23.95, 56.45), GeoPoint(24.70, 56.95));
      case OmaniRegion.alBatinahSouth:
        return const CoastBounds(GeoPoint(23.55, 57.20), GeoPoint(23.95, 58.35));
      case OmaniRegion.muscat:
        return const CoastBounds(GeoPoint(23.30, 58.15), GeoPoint(23.75, 59.05));
      case OmaniRegion.ashSharqiyahSouth:
        return const CoastBounds(GeoPoint(22.10, 59.20), GeoPoint(22.90, 60.10));
      case OmaniRegion.alWusta:
        return const CoastBounds(GeoPoint(19.60, 57.80), GeoPoint(21.20, 59.30));
      case OmaniRegion.dhofar:
        return const CoastBounds(GeoPoint(16.60, 52.00), GeoPoint(17.35, 55.00));
    }
  }

  MaritimeZone get maritimeZone {
    switch (this) {
      case OmaniRegion.musandam:
        return MaritimeZone.straitOfHormuz;
      case OmaniRegion.alBatinahNorth:
      case OmaniRegion.alBatinahSouth:
      case OmaniRegion.muscat:
      case OmaniRegion.ashSharqiyahSouth:
        return MaritimeZone.gulfOfOman;
      case OmaniRegion.alWusta:
      case OmaniRegion.dhofar:
        return MaritimeZone.arabianSea;
    }
  }

  String get maritimeZoneAr {
    switch (maritimeZone) {
      case MaritimeZone.straitOfHormuz:
        return 'مضيق هرمز';
      case MaritimeZone.gulfOfOman:
        return 'خليج عُمان';
      case MaritimeZone.arabianSea:
        return 'بحر العرب';
    }
  }

  /// Matches a hotspot `region` string (e.g. 'Al Batinah South', 'Dhofar').
  static OmaniRegion? tryParse(String raw) {
    final key = raw.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    if (key.isEmpty) return null;
    for (final region in OmaniRegion.values) {
      final candidates = <String>{
        region.displayName.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ''),
        region.nameAr,
        region.name,
      };
      if (candidates.contains(key)) return region;
    }
    // Loose matches used by the seed catalogue / legacy strings.
    const aliases = <String, OmaniRegion>{
      'albatina': OmaniRegion.alBatinahSouth,
      'eastern': OmaniRegion.ashSharqiyahSouth,
      'sharqiyah': OmaniRegion.ashSharqiyahSouth,
      'northernbatinah': OmaniRegion.alBatinahNorth,
      'southernbatinah': OmaniRegion.alBatinahSouth,
    };
    return aliases[key];
  }
}

/// Whole-coast bounds covering the Omani EEZ from Musandam to Dhofar. Used as
/// the initial map camera and the max hotspot fetch radius.
const CoastBounds omanCoastBounds = CoastBounds(
  GeoPoint(16.60, 52.00),
  GeoPoint(26.65, 60.10),
);
