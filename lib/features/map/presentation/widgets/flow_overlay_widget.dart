import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/models/flow_field.dart';

/// Which medium the flow layer is drawing. `off` removes the layer entirely.
enum FlowMode { off, wind, current }

/// A snapshot of the map viewport for one frame: the geographic bounds plus
/// the screen pixels where the north-west / south-east corners landed.
///
/// MapLibre is a Web-Mercator map, so between those two anchors longitude is
/// linear in screen-x and Mercator latitude is linear in screen-y. That lets
/// the overlay project *every* particle with pure arithmetic after just two
/// `toScreenLocation` platform calls per refresh — the difference between a
/// handful of channel round-trips a second and thousands.
class FlowViewport {
  const FlowViewport({
    required this.pixelSize,
    required this.nw,
    required this.se,
    required this.nwPoint,
    required this.sePoint,
  });

  final Size pixelSize;
  final LatLng nw; // geographic north-west corner of the visible area
  final LatLng se;
  final Offset nwPoint; // where nw landed on screen (px)
  final Offset sePoint;

  double get west => nw.longitude;
  double get east => se.longitude;
  double get north => nw.latitude;
  double get south => se.latitude;

  static double _merc(double latRad) =>
      math.log(math.tan(math.pi / 4 + latRad / 2));

  /// Geo → screen. Valid inside the bounds; outside it extrapolates.
  Offset project(double lat, double lng) {
    final fx = (lng - nw.longitude) / (se.longitude - nw.longitude);
    final mNorth = _merc(nw.latitude * math.pi / 180);
    final mSouth = _merc(se.latitude * math.pi / 180);
    final fy = (_merc(lat * math.pi / 180) - mNorth) / (mSouth - mNorth);
    return Offset(
      nwPoint.dx + fx * (sePoint.dx - nwPoint.dx),
      nwPoint.dy + fy * (sePoint.dy - nwPoint.dy),
    );
  }
}

/// Reads the live MapLibre camera into a [FlowViewport]. Returns null while
/// the map is not ready, or while [upright] reports a tilted/rotated camera —
/// the linear projection above only holds for the upright map this screen
/// uses (the screen tracks tilt/bearing from `onCameraMove`).
Future<FlowViewport?> maplibreViewport(
  MapLibreMapController? controller, { bool Function()? upright,
}) async {
  if (controller == null) return null;
  if (upright != null && !upright()) return null;
  try {
    final region = await controller.getVisibleRegion();
    // Bounds ship as SW/NE corners; the projection wants the visual top-left
    // and bottom-right anchors.
    final nw = LatLng(region.northeast.latitude, region.southwest.longitude);
    final se = LatLng(region.southwest.latitude, region.northeast.longitude);
    final nwPoint = await controller.toScreenLocation(nw);
    final sePoint = await controller.toScreenLocation(se);
    return FlowViewport(
      pixelSize: Size(
        (sePoint.x - nwPoint.x).abs().toDouble(),
        (sePoint.y - nwPoint.y).abs().toDouble(),
      ),
      nw: nw,
      se: se,
      nwPoint: Offset(nwPoint.x.toDouble(), nwPoint.y.toDouble()),
      sePoint: Offset(sePoint.x.toDouble(), sePoint.y.toDouble()),
    );
  } catch (_) {
    return null; // map disposed mid-frame: skip, the next tick retries
  }
}

/// Speed → colour ramps, shared with the website layer (assets/js/
/// flow-render.js) so a returning eye meets one visual language on both.
class FlowColors {
  const FlowColors._();

  static const List<List<num>> windStops = [
    [0, 91, 199, 195], [5, 15, 122, 122], [10, 216, 185, 140],
    [16, 194, 116, 58], [24, 168, 50, 50], [32, 120, 26, 90],
  ];
  static const List<List<num>> currentStops = [
    [0, 143, 184, 232], [0.6, 77, 111, 174], [1.4, 107, 79, 174],
    [2.6, 61, 47, 134], [4, 36, 26, 92],
  ];

  static List<List<num>> stopsFor(FlowMode mode) =>
      mode == FlowMode.current ? currentStops : windStops;

  /// Continuous (non-banded) ramp lookup in knots.
  static Color forKt(FlowMode mode, double kt) {
    final stops = stopsFor(mode);
    if (kt <= stops.first[0]) return _rgb(stops.first);
    if (kt >= stops.last[0]) return _rgb(stops.last);
    for (var i = 0; i < stops.length - 1; i++) {
      final a = stops[i], b = stops[i + 1];
      if (kt >= a[0] && kt < b[0]) {
        final t = ((kt - a[0]) / (b[0] - a[0])).clamp(0.0, 1.0);
        return Color.fromARGB(
          255,
          (a[1] + (b[1] - a[1]) * t).round(),
          (a[2] + (b[2] - a[2]) * t).round(),
          (a[3] + (b[3] - a[3]) * t).round(),
        );
      }
    }
    return _rgb(stops.last);
  }

  static Color _rgb(List<num> s) => Color.fromARGB(
      255, s[1].round(), s[2].round(), s[3].round());
}

/// Source of the current viewport — injected so the overlay is unit- and
/// widget-testable without a live MapLibre controller.
typedef FlowViewportSource = Future<FlowViewport?> Function();

/// Nullschool-style animated wind/current streaks drawn above a MapLibre map.
///
/// The technique — advecting particles through a bilinearly interpolated U/V
/// grid with fading trails — is the one published by the open-source
/// nullschool.net code (cambecc/earth, MIT) and Esri's wind-js (Apache 2.0),
/// ported to Dart/Canvas by hand per SPECIFICATION.md §6.7. Canvas 2D via
/// CustomPainter, deliberately not WebGL (the webgl-wind path is broken on
/// Android/iOS browsers and this audience is mobile-first).
///
/// Particles live in geo space, so they ride the map while it pans; the
/// viewport is refreshed at most every [viewportRefresh] while dragging.
/// Honours `MediaQuery.disableAnimations` by switching to one static arrow
/// per grid cell — same information, no motion.
class FlowOverlay extends StatefulWidget {
  const FlowOverlay({
    super.key,
    required this.field,
    required this.mode,
    required this.viewport,
    this.particleCount = 380,
    this.viewportRefresh = const Duration(milliseconds: 80),
  });

  final FlowField? field;
  final FlowMode mode;
  final FlowViewportSource viewport;

  /// Tuned for mid-range Android; must be perf-tested on a real device
  /// before raising (ticket §6.7).
  final int particleCount;
  final Duration viewportRefresh;

  @override
  State<FlowOverlay> createState() => FlowOverlayState();
}

class FlowOverlayState extends State<FlowOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  final math.Random _rng = math.Random();
  final List<_Particle> _particles = [];

  FlowViewport? _viewport;
  Timer? _viewportTimer;
  Stopwatch _lastTick = Stopwatch()..start();
  int _debugPaintFrames = 0; // observable by tests: how many ticks painted

  FlowGrid? get _grid {
    final field = widget.field;
    if (field == null || widget.mode == FlowMode.off) return null;
    final grid = widget.mode == FlowMode.wind ? field.wind : field.current;
    return (grid != null && !grid.isEmpty) ? grid : null;
  }

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _clock.addListener(_step);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First-run start lives here, not initState: _restart reads MediaQuery,
    // and inherited-widget lookups are illegal before initState completes.
    if (!_started) {
      _started = true;
      _restart();
    }
  }

  @override
  void didUpdateWidget(FlowOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        !identical(oldWidget.field, widget.field) ||
        oldWidget.particleCount != widget.particleCount) {
      _restart();
    }
  }

  void _restart() {
    _clock.stop();
    _particles.clear();
    _viewportTimer?.cancel();
    _viewportTimer = null;
    if (widget.mode == FlowMode.off || _grid == null) return; // paints nothing
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _refreshViewport().then((_) {
        if (mounted && _viewport != null) setState(() {}); // static arrows
      });
      return;
    }
    _lastTick = Stopwatch()..start();
    unawaited(_refreshViewport());
    _viewportTimer = Timer.periodic(widget.viewportRefresh, (_) => _refreshViewport());
    _clock.repeat();
  }

  Future<void> _refreshViewport() async {
    final vp = await widget.viewport();
    if (!mounted || vp == null) return;
    _viewport = vp;
    if (_particles.isEmpty) _seedAll();
  }

  void _seedAll() {
    final grid = _grid;
    if (grid == null) return;
    final target = widget.particleCount;
    var guard = target * 4;
    while (_particles.length < target && guard-- > 0) {
      final p = _Particle();
      if (_seedOne(p, grid)) _particles.add(p);
    }
  }

  bool _seedOne(_Particle p, FlowGrid grid) {
    final vp = _viewport;
    for (var tries = 0; tries < 8; tries++) {
      double lat, lng;
      if (vp != null) {
        lat = vp.south + _rng.nextDouble() * (vp.north - vp.south);
        lng = vp.west + _rng.nextDouble() * (vp.east - vp.west);
      } else {
        // No viewport yet: spawn across the grid itself.
        lat = grid.la1 - _rng.nextDouble() * (grid.ny - 1) * grid.dy;
        lng = grid.lo1 + _rng.nextDouble() * (grid.nx - 1) * grid.dx;
      }
      if (grid.sample(lng, lat) != null) {
        p.resetAt(lat, lng, _rng);
        return true;
      }
    }
    return false;
  }

  void _step() {
    final grid = _grid;
    final vp = _viewport;
    if (grid == null || vp == null) return;
    final dt = math.min(_lastTick.elapsedMicroseconds / 1e6, 0.05);
    _lastTick = Stopwatch()..start();
    if (dt <= 0) return;

    // Advection converts m/s into degrees/s. Currents get the larger gain
    // or their 0–1 m/s motion is invisible at a regional camera — the
    // standard exaggeration of this technique, disclosed in the legend.
    final gain = widget.mode == FlowMode.current ? 0.16 : 0.05;

    for (final p in _particles) {
      final uv = grid.sample(p.lng, p.lat);
      if (uv == null || p.age > p.life) {
        _seedOne(p, grid);
        continue;
      }
      p.lat += uv.dy * gain * dt;
      p.lng += uv.dx * gain * dt;
      p.age += dt;
      p.trail.add(LatLng(p.lat, p.lng));
      if (p.trail.length > _Particle.trailLen) p.trail.removeAt(0);
    }
    _debugPaintFrames++;
  }

  @override
  void dispose() {
    _viewportTimer?.cancel();
    _clock.removeListener(_step);
    _clock.dispose();
    super.dispose();
  }

  /// Test hook: how many animation frames have painted.
  int get debugPaintFrames => _debugPaintFrames;

  /// Test hook: current particle population.
  int get debugParticleCount => _particles.length;

  @override
  Widget build(BuildContext context) {
    final grid = _grid;
    if (grid == null || widget.mode == FlowMode.off) {
      return const SizedBox.shrink();
    }
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return IgnorePointer(
      child: CustomPaint(
        painter: _FlowPainter(
          grid: grid,
          mode: widget.mode,
          particles: _particles,
          viewport: _viewport,
          staticArrows: reduceMotion,
          repaint: _clock,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// One advected tracer; positions are geographic so streaks stick to the map.
class _Particle {
  static const int trailLen = 7;

  double lat = 0, lng = 0;
  double age = 0;
  double life = 4;
  final List<LatLng> trail = [];

  void resetAt(double a, double b, math.Random rng) {
    lat = a;
    lng = b;
    age = 0;
    life = 2.5 + rng.nextDouble() * 3.5; // jitter kills synchronised blinking
    trail
      ..clear()
      ..add(LatLng(lat, lng));
  }
}

/// Draws trails as tapered polylines: oldest segments faintest, a wide
/// low-alpha glow under the head segment, a bright speed-coloured core.
class _FlowPainter extends CustomPainter {
  _FlowPainter({
    required this.grid,
    required this.mode,
    required this.particles,
    required this.viewport,
    required this.staticArrows,
    super.repaint,
  });

  final FlowGrid grid;
  final FlowMode mode;
  final List<_Particle> particles;
  final FlowViewport? viewport;
  final bool staticArrows;

  static const double _knots = 1.943844;

  @override
  void paint(Canvas canvas, Size size) {
    final vp = viewport;
    if (vp == null) return;
    if (staticArrows) {
      _paintStatic(canvas, vp);
      return;
    }

    final ktMax = mode == FlowMode.current ? 4.0 : 30.0;
    for (final p in particles) {
      if (p.trail.length < 2) continue;
      final uv = grid.sample(p.lng, p.lat);
      if (uv == null) continue;
      final kt = math.sqrt(uv.dx * uv.dx + uv.dy * uv.dy) * _knots;
      final ratio = (kt / ktMax).clamp(0.0, 1.0);
      final color = FlowColors.forKt(mode, kt);
      // Life envelope: fade in over 0.3 s, out over the last 0.7 s.
      final env = math.min(
          math.min(p.age / 0.3, 1.0), math.min((p.life - p.age) / 0.7, 1.0));
      if (env <= 0) continue;

      final pts = [
        for (final g in p.trail) vp.project(g.latitude, g.longitude)
      ];
      // Skip off-screen streaks cheaply (with margin for the glow).
      final head = pts.last;
      if (head.dx < -40 || head.dy < -40 ||
          head.dx > size.width + 40 || head.dy > size.height + 40) {
        continue;
      }

      // Trail, oldest → newest: width and alpha ramp toward the head.
      final trailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 1; i < pts.length; i++) {
        final f = i / (pts.length - 1); // 0 tail … 1 head
        trailPaint
          ..color = color.withValues(alpha: (0.55 * f * f * env).clamp(0.0, 1.0))
          ..strokeWidth = (0.7 + 1.5 * ratio) * (0.5 + 0.5 * f);
        canvas.drawLine(pts[i - 1], pts[i], trailPaint);
      }
      // Glow under the head — the luminous body, cheap single wide stroke.
      canvas.drawLine(
        head,
        pts[pts.length - 2],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.10 * env)
          ..strokeWidth = 3 + 4 * ratio,
      );
    }
  }

  /// prefers-reduced-motion / disableAnimations: one coloured arrow per
  /// water cell — the same data the streaks encode, without the loop.
  void _paintStatic(Canvas canvas, FlowViewport vp) {
    final max = grid.maxSpeedMs();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var iy = 0; iy < grid.ny; iy++) {
      for (var ix = 0; ix < grid.nx; ix++) {
        final i = iy * grid.nx + ix;
        final uu = grid.u[i], vv = grid.v[i];
        if (uu == null || vv == null) continue;
        final lat = grid.cellLat(iy), lng = grid.cellLng(ix);
        final c = vp.project(lat, lng);
        if (c.dx < -20 || c.dy < -20 ||
            c.dx > vp.pixelSize.width + 20 || c.dy > vp.pixelSize.height + 20) {
          continue;
        }
        final s = math.sqrt(uu * uu + vv * vv);
        final ratio = (s / max).clamp(0.0, 1.0);
        final len = 6.0 + 14 * ratio;
        final dir = Offset(uu / (s == 0 ? 1 : s), -vv / (s == 0 ? 1 : s)); // screen y is down
        final color = FlowColors.forKt(mode, s * _knots);
        stroke
          ..color = color.withValues(alpha: 0.9)
          ..strokeWidth = 1 + 1.6 * ratio;
        canvas.drawLine(c - dir * len * 0.4, c + dir * len, stroke);
        canvas.drawCircle(c + dir * len, 1.4 + 1.2 * ratio,
            Paint()..color = color.withValues(alpha: 0.9));
      }
    }
  }

  @override
  bool shouldRepaint(_FlowPainter oldDelegate) =>
      oldDelegate.mode != mode ||
      !identical(oldDelegate.grid, grid) ||
      oldDelegate.viewport != viewport ||
      oldDelegate.staticArrows != staticArrows ||
      oldDelegate.particles != particles;
}
