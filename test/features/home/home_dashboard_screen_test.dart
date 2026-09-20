import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahhar/core/constants/fish_species.dart';
import 'package:bahhar/core/models/hotspot_model.dart';
import 'package:bahhar/features/home/presentation/widgets/hotspot_list_widget.dart';
import 'package:bahhar/features/home/presentation/widgets/opportunity_gauge_widget.dart';
import 'package:bahhar/features/home/presentation/widgets/species_chips_widget.dart';
import 'package:bahhar/shared/widgets/hotspot_card.dart';
import 'package:bahhar/shared/widgets/legal_status_badge.dart' show LegalStatus;

HotspotModel _spot(String id, int probability) => HotspotModel(
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
      legalStatus: LegalStatus.permitted,
      bestWindow: '05:00',
      description: 'spot',
    );

void main() {
  group('OpportunityGaugeWidget', () {
    testWidgets('shows the percentage and its band label', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: OpportunityGaugeWidget(index: 85))),
      ));
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Optimal Bite'), findsOneWidget);
    });

    testWidgets('clamps out-of-range indices', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: OpportunityGaugeWidget(index: 150))),
      ));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('renders a low band + caption', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: OpportunityGaugeWidget(
                index: 10, caption: 'Dawn slack water'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('Low Opportunity'), findsOneWidget);
      expect(find.text('Dawn slack water'), findsOneWidget);
    });
  });

  group('SpeciesChipsWidget', () {
    testWidgets('selecting an unselected chip adds it (multi-select)',
        (tester) async {
      List<FishSpecies>? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 40,
            child: SpeciesChipsWidget(
              selected: const [],
              species: const [FishSpecies.kingfish, FishSpecies.hammour],
              onChanged: (s) => result = s,
            ),
          ),
        ),
      ));

      await tester.tap(find.byKey(const Key('species_chip_kingfish')));
      await tester.pump();
      expect(result, contains(FishSpecies.kingfish));
    });

    testWidgets('tapping a selected chip removes it', (tester) async {
      List<FishSpecies>? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 40,
            child: SpeciesChipsWidget(
              species: const [FishSpecies.kingfish, FishSpecies.hammour],
              selected: const [FishSpecies.kingfish, FishSpecies.hammour],
              onChanged: (s) => result = s,
            ),
          ),
        ),
      ));

      await tester.tap(find.byKey(const Key('species_chip_kingfish')));
      await tester.pump();
      expect(result, isNot(contains(FishSpecies.kingfish)));
      expect(result, contains(FishSpecies.hammour));
    });

    testWidgets('single-select replaces the selection', (tester) async {
      List<FishSpecies>? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 40,
            child: SpeciesChipsWidget(
              species: const [FishSpecies.hammour, FishSpecies.sailfish],
              selected: const [FishSpecies.hammour],
              singleSelect: true,
              onChanged: (s) => result = s,
            ),
          ),
        ),
      ));

      await tester.tap(find.byKey(const Key('species_chip_sailfish')));
      await tester.pump();
      expect(result, [FishSpecies.sailfish]);
    });

    testWidgets('renders Arabic labels', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 40,
            child: SpeciesChipsWidget(
              selected: const [],
              isArabic: true,
              species: const [FishSpecies.kingfish],
              onChanged: (_) {},
            ),
          ),
        ),
      ));
      expect(find.text('الكنعد'), findsOneWidget);
    });

    testWidgets('empty catalogue renders nothing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpeciesChipsWidget(
            selected: const [],
            species: const [],
            onChanged: (_) {},
          ),
        ),
      ));
      expect(find.byType(SpeciesChipsWidget), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });
  });

  group('HotspotListWidget', () {
    testWidgets('ranks by descending probability', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HotspotListWidget(
              hotspots: [_spot('low', 40), _spot('high', 95)],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HotspotCard), findsNWidgets(2));
      // Highest-probability card is rendered first.
      final firstCard = tester.widget<HotspotCard>(find.byType(HotspotCard).first);
      expect(firstCard.hotspot.id, 'high');
    });

    testWidgets('limit truncates to the top spot', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HotspotListWidget(
              hotspots: [_spot('low', 40), _spot('high', 95)],
              limit: 1,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(HotspotCard), findsOneWidget);
      expect(find.text('high'), findsOneWidget);
      expect(find.text('low'), findsNothing);
    });

    testWidgets('reports taps with the hotspot', (tester) async {
      HotspotModel? tapped;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HotspotListWidget(
              hotspots: [_spot('a', 80)],
              onTap: (h) => tapped = h,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('a'));
      await tester.pump();
      expect(tapped?.id, 'a');
    });

    testWidgets('empty list shows the bilingual empty message', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HotspotListWidget(hotspots: [])),
      ));
      expect(find.text('No ranked spots available right now.'), findsOneWidget);
    });
  });
}
