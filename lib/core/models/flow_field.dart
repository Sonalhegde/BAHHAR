import 'dart:math' as math;
import 'dart:ui' show Offset;

/// One directional media (wind or ocean current) on a regular lat/lon grid.
///
/// Mirrors the backend contract of `/api/v1/wind-field` (see
/// backend/main.py §6.7 of SPECIFICATION.md): a header (origin `lo1`/`la1`,
/// step `dx`/`dy`, cell counts `nx`/`ny`) plus row-major U/V arrays in m/s
/// scanned west→east, north→south. A `null` cell means the model has no
/// value there (land or missing) — distinct from a measured `0.0` calm.
///
/// The bilinear sampling + null-renormalisation technique is the one
/// published by the open-source nullschool.net code (cambecc/earth, MIT)
/// and Esri's wind-js (Apache 2.0), ported to Dart by hand.
class FlowGrid {
  const FlowGrid({
    required this.nx,
    required this.ny,
    required this.lo1,
    required this.la1,
    required this.dx,
    required this.dy,
    required this.u,
    required this.v,
  });

  factory FlowGrid.fromJson(Map<String, dynamic> json, Map<String, dynamic> h) {
    final u = (json['u'] as List).cast<num?>().map((e) => e?.toDouble()).toList();
    final v = (json['v'] as List).cast<num?>().map((e) => e?.toDouble()).toList();
    return FlowGrid(
      nx: (h['nx'] as num).toInt(),
      ny: (h['ny'] as num).toInt(),
      lo1: (h['lo1'] as num).toDouble(),
      la1: (h['la1'] as num).toDouble(),
      dx: (h['dx'] as num).toDouble(),
      dy: (h['dy'] as num).toDouble(),
      u: u,
      v: v,
    );
  }

  final int nx;
  final int ny;

  /// West edge (lo1) and north edge (la1) of the grid, in degrees.
  final double lo1;
  final double la1;

  /// Cell step in degrees; rows scan north→south so latitude = la1 - iy*dy.
  final double dx;
  final double dy;

  final List<double?> u;
  final List<double?> v;

  double cellLat(int iy) => la1 - iy * dy;
  double cellLng(int ix) => lo1 + ix * dx;

  bool get isEmpty => u.isEmpty;

  /// Strongest measured speed (m/s); ~0.001 floor keeps ratios finite when a
  /// whole field is calm.
  double maxSpeedMs() {
    var m = 0.001;
    for (var i = 0; i < u.length; i++) {
      final uu = u[i], vv = v[i];
      if (uu == null || vv == null) continue;
      final s = math.sqrt(uu * uu + vv * vv);
      if (s > m) m = s;
    }
    return m;
  }

  /// Bilinear interpolation of (u, v) at a coordinate, or null outside the
  /// grid / over land. Null corners are skipped and the weights renormalised,
  /// so the coast reads as a fade-out rather than a wall.
  Offset? sample(double lng, double lat) {
    final fx = (lng - lo1) / dx;
    final fy = (la1 - lat) / dy;
    if (fx < -0.5 || fy < -0.5 || fx > nx - 0.5 || fy > ny - 0.5) return null;
    final x0 = fx.clamp(0, nx - 1.0).floor();
    final y0 = fy.clamp(0, ny - 1.0).floor();
    final x1 = math.min(nx - 1, x0 + 1);
    final y1 = math.min(ny - 1, y0 + 1);
    final tx = (fx - x0).clamp(0.0, 1.0);
    final ty = (fy - y0).clamp(0.0, 1.0);
    var su = 0.0, sv = 0.0, w = 0.0;
    void corner(int cx, int cy, double cw) {
      final i = cy * nx + cx;
      final uu = u[i], vv = v[i];
      if (uu == null || vv == null || cw == 0) return;
      su += uu * cw;
      sv += vv * cw;
      w += cw;
    }

    corner(x0, y0, (1 - tx) * (1 - ty));
    corner(x1, y0, tx * (1 - ty));
    corner(x0, y1, (1 - tx) * ty);
    corner(x1, y1, tx * ty);
    if (w < 0.25) return null;
    return Offset(su / w, sv / w);
  }
}

/// The two media together, exactly as one /api/v1/wind-field response
/// delivers them. Either may be absent when the backend served a partial
/// upstream failure.
class FlowField {
  const FlowField({
    required this.generatedAt,
    this.wind,
    this.current,
    this.cached = false,
    this.attribution = 'Open-Meteo.com (CC-BY 4.0)',
  });

  factory FlowField.fromJson(Map<String, dynamic> json) {
    final h = json['header'] as Map<String, dynamic>?;
    final fields = json['fields'] as Map<String, dynamic>?;
    DateTime when = DateTime.now().toUtc();
    final raw = json['generated_at'];
    if (raw is String) when = DateTime.tryParse(raw)?.toUtc() ?? when;
    return FlowField(
      generatedAt: when,
      cached: json['cached'] == true,
      attribution: json['attribution'] as String? ??
          'Open-Meteo.com (CC-BY 4.0)',
      wind: (h != null && fields?['wind'] is Map<String, dynamic>)
          ? FlowGrid.fromJson(fields!['wind'] as Map<String, dynamic>, h)
          : null,
      current: (h != null && fields?['current'] is Map<String, dynamic>)
          ? FlowGrid.fromJson(fields!['current'] as Map<String, dynamic>, h)
          : null,
    );
  }

  final DateTime generatedAt;
  final FlowGrid? wind;
  final FlowGrid? current;

  /// True when the backend answered from its TTL cache rather than Open-Meteo.
  final bool cached;
  final String attribution;

  bool get hasAny => wind != null || current != null;

  /// Data this old should be refetched before being drawn again (the backend
  /// refreshes its own cache on a 3 h model cadence).
  bool isStale({Duration maxAge = const Duration(hours: 1)}) =>
      DateTime.now().toUtc().difference(generatedAt) > maxAge;
}
