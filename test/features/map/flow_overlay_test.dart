import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:bahhar/core/models/flow_field.dart';
import 'package:bahhar/features/map/presentation/widgets/flow_overlay_widget.dart';

/// Uniform eastward 10 m/s grid covering the fake viewport below.
FlowGrid _grid() => const FlowGrid(
      nx: 3,
      ny: 3,
      lo1: 57.5,
      la1: 24.5,
      dx: 1.0,
      dy: 1.0,
      u: [10, 10, 10, 10, 10, 10, 10, 10, 10],
      v: [0, 0, 0, 0, 0, 0, 0, 0, 0],
    );

FlowField _field() => FlowField(
      generatedAt: DateTime.now().toUtc(),
      wind: _grid(),
      current: _grid(),
    );

/// A fixed 400x600 px window onto lon 57.5..59.5 / lat 23.0..24.5.
FlowViewport _viewport() => const FlowViewport(
      pixelSize: Size(400, 600),
      nw: LatLng(24.5, 57.5),
      se: LatLng(23.0, 59.5),
      nwPoint: Offset(0, 0),
      sePoint: Offset(400, 600),
    );

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, height: 600, child: child),
      ),
    );

/// The Scaffold chrome paints too, so the finder must stay inside the
/// overlay's own subtree.
final _overlayPaint = find.descendant(
  of: find.byType(FlowOverlay),
  matching: find.byType(CustomPaint),
);

void main() {
  group('FlowViewport projection', () {
    test('corners map to the anchor pixels, mid-mercator in between', () {
      final vp = _viewport();
      final nw = vp.project(24.5, 57.5);
      final se = vp.project(23.0, 59.5);
      expect(nw.dx, closeTo(0, 1e-6));
      expect(nw.dy, closeTo(0, 1e-6));
      expect(se.dx, closeTo(400, 1e-6));
      expect(se.dy, closeTo(600, 1e-6));
      // Longitude is linear in x: halfway east lands halfway across.
      final midEast = vp.project(24.5, 58.5);
      expect(midEast.dx, closeTo(200, 1e-6));
      // Latitude is Mercator, not linear: Mercator stretches space toward
      // the poles, so the pixel halfway down corresponds to a latitude
      // slightly south of the arithmetic mid-latitude (23.75 here).
      final midLat = vp.project(23.75, 57.5);
      expect(midLat.dy, greaterThan(300));
      expect(midLat.dy, lessThan(302));
    });
  });

  group('FlowOverlay', () {
    testWidgets('off mode renders no paint layer at all', (tester) async {
      await tester.pumpWidget(_host(FlowOverlay(
        field: _field(),
        mode: FlowMode.off,
        viewport: () async => _viewport(),
      )));
      expect(_overlayPaint, findsNothing);
    });

    testWidgets('missing field data renders nothing (graceful failure)',
        (tester) async {
      await tester.pumpWidget(_host(FlowOverlay(
        field: null,
        mode: FlowMode.wind,
        viewport: () async => _viewport(),
      )));
      expect(_overlayPaint, findsNothing);
    });

    testWidgets('wind mode seeds particles and keeps ticking', (tester) async {
      final key = GlobalKey<FlowOverlayState>();
      await tester.pumpWidget(_host(FlowOverlay(
        key: key,
        field: _field(),
        mode: FlowMode.wind,
        viewport: () async => _viewport(),
        particleCount: 120,
      )));
      // Let the (async) viewport resolve and the ticker run a few frames.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final state = key.currentState!;
      expect(state.debugParticleCount, greaterThan(0));
      expect(state.debugParticleCount, lessThanOrEqualTo(120));
      final frames = state.debugPaintFrames;
      expect(frames, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 300));
      expect(key.currentState!.debugPaintFrames, greaterThan(frames));
    });

    testWidgets('an unavailable viewport (tilted camera) stays silent',
        (tester) async {
      final key = GlobalKey<FlowOverlayState>();
      await tester.pumpWidget(_host(FlowOverlay(
        key: key,
        field: _field(),
        mode: FlowMode.wind,
        viewport: () async => null, // the screen reports a rotated camera
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(key.currentState!.debugParticleCount, 0);
      expect(key.currentState!.debugPaintFrames, 0);
    });

    testWidgets('reduced motion draws static arrows instead of animating',
        (tester) async {
      final key = GlobalKey<FlowOverlayState>();
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: FlowOverlay(
                key: key,
                field: _field(),
                mode: FlowMode.wind,
                viewport: () async => _viewport(),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // The information is painted (CustomPaint present) but the clock never
      // runs: zero advected frames means zero motion.
      expect(_overlayPaint, findsWidgets);
      expect(key.currentState!.debugPaintFrames, 0);
    });

    testWidgets('switching to current mode keeps the layer alive',
        (tester) async {
      final key = GlobalKey<FlowOverlayState>();
      final field = _field();
      await tester.pumpWidget(_host(FlowOverlay(
        key: key,
        field: field,
        mode: FlowMode.wind,
        viewport: () async => _viewport(),
      )));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_host(FlowOverlay(
        key: key,
        field: field,
        mode: FlowMode.current,
        viewport: () async => _viewport(),
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(key.currentState!.debugParticleCount, greaterThan(0));
    });
  });

  group('FlowColors', () {
    test('ramp is continuous and clamps at both ends', () {
      final calm = FlowColors.forKt(FlowMode.wind, 0);
      final mid1 = FlowColors.forKt(FlowMode.wind, 5);
      final mid2 = FlowColors.forKt(FlowMode.wind, 5.0001);
      final storm = FlowColors.forKt(FlowMode.wind, 1000);
      expect(calm, isNotNull);
      // Interpolation, not banding: a 0.0001 kt difference is continuous.
      expect(mid1.r, closeTo(mid2.r, 0.01));
      expect(storm, FlowColors.forKt(FlowMode.wind, 32));
    });

    test('current ramp uses the blue family', () {
      final c = FlowColors.forKt(FlowMode.current, 1.0);
      // (.r/.g/.b are 0..1 doubles on this Flutter version.)
      expect(c.b, greaterThan(c.r));
    });
  });
}
