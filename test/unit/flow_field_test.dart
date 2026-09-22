import 'package:flutter_test/flutter_test.dart';
import 'package:bahhar/core/models/flow_field.dart';

/// Contract fixture mirroring backend/main.py /api/v1/wind-field:
/// header + row-major u/v (m/s), scanned west→east, north→south.
/// 3x2 grid: lon 58.0/58.5/59.0, lat 24.0/23.5.
Map<String, dynamic> _payload({
  List<num?>? windU,
  List<num?>? windV,
}) =>
    {
      'header': {
        'version': 1,
        'nx': 3,
        'ny': 2,
        'lo1': 58.0,
        'la1': 24.0,
        'dx': 0.5,
        'dy': 0.5,
        'scan': 'row, w→e, n→s',
        'unit': 'm/s',
      },
      'fields': {
        'wind': {
          'u': windU ?? [10, 10, 10, 10, 10, 10],
          'v': windV ?? [0, 0, 0, 0, 0, 0],
          'unit': 'm/s',
        },
        'current': {
          'u': [1, 2, 3, 4, 5, 6],
          'v': [0, 0, 0, 0, 0, 0],
          'unit': 'm/s',
        },
      },
      'generated_at': '2026-09-21T12:00:00Z',
      'cached': true,
      'attribution': 'Open-Meteo',
    };

void main() {
  group('FlowField.fromJson', () {
    test('parses the backend grid contract', () {
      final field = FlowField.fromJson(_payload());
      expect(field.cached, isTrue);
      expect(field.wind, isNotNull);
      expect(field.current, isNotNull);
      expect(field.wind!.nx, 3);
      expect(field.wind!.ny, 2);
      expect(field.generatedAt, DateTime.utc(2026, 9, 21, 12));
      expect(field.hasAny, isTrue);
    });

    test('tolerates a partial (wind-only) payload from a degraded cache', () {
      final json = _payload();
      json['fields'] = {'wind': json['fields']['wind']};
      final field = FlowField.fromJson(json);
      expect(field.wind, isNotNull);
      expect(field.current, isNull);
      expect(field.hasAny, isTrue);
    });
  });

  group('FlowGrid sampling', () {
    test('bilinear interior lookup matches the cell value', () {
      final grid = FlowField.fromJson(_payload()).wind!;
      // Pure eastward 10 m/s everywhere.
      final uv = grid.sample(58.5, 23.75);
      expect(uv, isNotNull);
      expect(uv!.dx, closeTo(10, 1e-9));
      expect(uv.dy, closeTo(0, 1e-9));
    });

    test('interpolates between differing cells', () {
      final grid = const FlowGrid(
        nx: 2,
        ny: 1,
        lo1: 58.0,
        la1: 24.0,
        dx: 2.0,
        dy: 1.0,
        u: [0, 10],
        v: [0, 0],
      );
      final mid = grid.sample(59.0, 24.0)!;
      expect(mid.dx, closeTo(5, 1e-9));
    });

    test('null (land) corners are renormalised, not dropped', () {
      // Row 0 is land; a point on the boundary still interpolates from water.
      final grid = const FlowGrid(
        nx: 2,
        ny: 2,
        lo1: 58.0,
        la1: 24.0,
        dx: 1.0,
        dy: 1.0,
        u: [null, null, 8, 8],
        v: [null, null, 0, 0],
      );
      // Just north of the water row: weights renormalise over water only.
      final uv = grid.sample(58.5, 23.6);
      expect(uv, isNotNull);
      expect(uv!.dx, closeTo(8, 1e-9));
      // Deep into the land row the water weight falls under the floor.
      expect(grid.sample(58.5, 24.0), isNull);
    });

    test('outside the grid is null', () {
      final grid = FlowField.fromJson(_payload()).wind!;
      expect(grid.sample(50, 23), isNull);
      expect(grid.sample(58.5, 30), isNull);
    });

    test('measured calm (0.0) is distinct from land (null)', () {
      final grid = FlowField.fromJson(_payload(
        windU: [0, 0, 0, 0, 0, 0],
        windV: [0, 0, 0, 0, 0, 0],
      )).wind!;
      final uv = grid.sample(58.0, 24.0);
      expect(uv, isNotNull);
      expect(uv!.dx, 0);
      expect(grid.maxSpeedMs(), greaterThanOrEqualTo(0.001));
    });

    test('maxSpeedMs reports the strongest measured vector', () {
      final grid = FlowField.fromJson(_payload(
        windU: [3, 0, 0, 0, 0, 0],
        windV: [4, 0, 0, 0, 0, 0],
      )).wind!;
      expect(grid.maxSpeedMs(), closeTo(5, 1e-9));
    });
  });

  group('freshness', () {
    test('a grid from the current hour is fresh', () {
      final field = FlowField(
        generatedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
        wind: FlowField.fromJson(_payload()).wind,
      );
      expect(field.isStale(), isFalse);
    });

    test('older than the max age is stale', () {
      final field = FlowField(
        generatedAt: DateTime.now().toUtc().subtract(const Duration(hours: 5)),
        wind: FlowField.fromJson(_payload()).wind,
      );
      expect(field.isStale(), isTrue);
    });
  });
}
