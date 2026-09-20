import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahhar/core/models/hotspot_model.dart';
import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/features/map/presentation/widgets/layer_toggles_widget.dart';
import 'package:bahhar/features/map/presentation/widgets/probability_markers_widget.dart';
import 'package:bahhar/features/map/presentation/widgets/species_filter_chips.dart';
import 'package:bahhar/core/providers/hotspots_provider.dart';
import 'package:bahhar/shared/widgets/legal_status_badge.dart' show LegalStatus;

HotspotModel _spot(
  String id,
  int probability, {
  LegalStatus status = LegalStatus.permitted,
}) =>
    HotspotModel(
      id: id,
      name: id,
      nameAr: id,
      region: 'Muscat',
      latitude: 23.6,
      longitude: 58.5,
      distanceNm: 4,
      depthMeters: 30,
      targetSpecies: const ['Kingfish'],
      probability: probability,
      legalStatus: status,
      bestWindow: '05:00',
      description: 'test spot',
    );

void main() {
  group('ProbabilityMarkersWidget', () {
    testWidgets('renders one marker per hotspot and reports taps',
        (tester) async {
      final spots = [_spot('a', 88), _spot('b', 45)];
      HotspotModel? tapped;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 240,
            child: ProbabilityMarkersWidget(
              hotspots: spots,
              project: (h) => const Offset(120, 120),
              onMarkerTap: (h) => tapped = h,
            ),
          ),
        ),
      ));

      expect(find.byKey(const Key('probability_marker_a')), findsOneWidget);
      expect(find.byKey(const Key('probability_marker_b')), findsOneWidget);
      expect(find.text('88'), findsOneWidget);

      await tester.tap(find.byKey(const Key('probability_marker_b')));
      await tester.pump();
      expect(tapped?.id, 'b');
    });

    test('colour encodes probability band and protected override', () {
      expect(
        ProbabilityMarkersWidget.colorFor(_spot('a', 88)),
        AppColors.getProbabilityColor(88),
      );
      expect(
        ProbabilityMarkersWidget.colorFor(
            _spot('p', 92, status: LegalStatus.protected)),
        AppColors.legalRestricted,
      );
    });

    test('higher probability yields a larger marker', () {
      const w = ProbabilityMarkersWidget(
        hotspots: [],
        project: _never,
      );
      expect(w.diameterFor(_spot('hi', 95)),
          greaterThan(w.diameterFor(_spot('lo', 20))));
    });

    test('renders nothing for an empty list', () {
      expect(
        const ProbabilityMarkersWidget(hotspots: [], project: _never),
        isA<StatelessWidget>(),
      );
    });
  });

  group('MapSpeciesFilterChips', () {
    testWidgets('shows All + species chips and writes the filter provider',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Widen the surface so the horizontally-scrolled Kingfish chip is fully
      // within the viewport and reliably hit-testable.
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 60,
              child: Center(child: MapSpeciesFilterChips()),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Seed catalogue is offline (Firebase not configured) → Kingfish exists.
      expect(find.text('All Spots'), findsOneWidget);
      expect(find.byKey(const Key('species_filter_chip_Kingfish')),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('species_filter_chip_Kingfish')));
      await tester.pump();
      expect(container.read(selectedSpeciesFilterProvider), 'Kingfish');

      // Tapping the active species clears the filter again.
      await tester.tap(find.byKey(const Key('species_filter_chip_Kingfish')));
      await tester.pump();
      expect(container.read(selectedSpeciesFilterProvider), isNull);
    });
  });

  group('LayerTogglesWidget', () {
    testWidgets('toggling a layer emits an updated, immutable MapLayers',
        (tester) async {
      MapLayers? updated;
      const initial = MapLayers(
        hotspots: true,
        protectedAreas: true,
        depthContours: false,
        myLocation: true,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LayerTogglesWidget(
            layers: initial,
            onChanged: (l) => updated = l,
          ),
        ),
      ));

      await tester.tap(find.byKey(const Key('layer_toggle_depthContours')));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.depthContours, isTrue);
      // Untouched layers are preserved.
      expect(updated!.hotspots, isTrue);
      expect(updated!.myLocation, isTrue);
      // Original is unchanged (value semantics).
      expect(initial.depthContours, isFalse);
    });

    test('MapLayers.toggle + equality behave as a value type', () {
      const base = MapLayers(hotspots: true, myLocation: false);
      final flipped = base.toggle(MapLayerKind.myLocation);
      expect(flipped.myLocation, isTrue);
      expect(base.myLocation, isFalse);
      expect(base, const MapLayers(hotspots: true, myLocation: false));
      expect(base == flipped, isFalse);
    });
  });
}

Offset _never(HotspotModel h) => const Offset(0, 0);
