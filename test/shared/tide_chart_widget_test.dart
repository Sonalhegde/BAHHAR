import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahhar/core/models/tide_curve.dart';
import 'package:bahhar/shared/widgets/tide_chart_widget.dart';

/// Builds a backend-shaped /api/v1/tides/curve payload from (minute, height)
/// samples so the model and the painter are exercised without any network.
Map<String, dynamic> _payload(List<({int min, double h})> samples,
    {String state = 'Rising', String? station = 'TEST STATION'}) {
  final base = DateTime.utc(2026, 9, 23, 8);
  final points = [
    for (final s in samples)
      {
        't': base.add(Duration(minutes: s.min)).millisecondsSinceEpoch ~/ 1000,
        'iso': base.add(Duration(minutes: s.min)).toIso8601String(),
        'height_m': s.h,
      },
  ];
  return {
    'tide_state': state,
    'tide_height_m': points.isEmpty ? 0.0 : samples.first.h,
    'hours': 24,
    'station': station,
    'points': points,
    'fetched_at': base.toIso8601String(),
    'cached': false,
  };
}

void main() {
  group('TideCurve model', () {
    test('parses points and computes range + trend', () {
      final curve = TideCurve.fromJson(
          _payload([(min: 0, h: 1.0), (min: 60, h: 2.5), (min: 120, h: 0.4)]));
      expect(curve.points.length, 3);
      expect(curve.minM, 0.4);
      expect(curve.maxM, 2.5);
      expect(curve.isRising, isTrue);
      expect(curve.isEmpty, isFalse);
      expect(curve.station, 'TEST STATION');
    });

    test('empty payload reports empty and no now-point', () {
      final curve = TideCurve.fromJson({'tide_state': 'Unavailable', 'points': []});
      expect(curve.isEmpty, isTrue);
      expect(curve.tideState, 'Unavailable');
      expect(curve.pointAtNow(), isNull);
    });
  });

  group('TideChart widget', () {
    testWidgets('renders the curve for populated data', (tester) async {
      final curve = TideCurve.fromJson(
          _payload([(min: 0, h: 1.0), (min: 60, h: 2.5), (min: 120, h: 0.4)]));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 320, child: TideChart(curve: curve)),
          ),
        ),
      ));
      expect(find.byType(TideChart), findsOneWidget);
      expect(find.text('Tide curve unavailable'), findsNothing);
    });

    testWidgets('shows the placeholder for an empty curve', (tester) async {
      final curve = TideCurve.fromJson({'tide_state': 'Unavailable', 'points': []});
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 320, child: TideChart(curve: curve)),
          ),
        ),
      ));
      expect(find.text('Tide curve unavailable'), findsOneWidget);
    });
  });
}
