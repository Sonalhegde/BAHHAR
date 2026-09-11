import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/shared/widgets/fishing_score_gauge.dart';
import 'package:bahhar/shared/widgets/legal_status_badge.dart';
import 'package:bahhar/shared/widgets/condition_stat_chip.dart';
import 'package:bahhar/shared/widgets/alert_banner.dart';

void main() {
  group('Bahhar AI Shared Components Tests', () {
    testWidgets('FishingScoreGauge renders the score and its band label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FishingScoreGauge(score: 85),
          ),
        ),
      );

      expect(find.byType(FishingScoreGauge), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      // 85 sits in the top probability band.
      expect(AppColors.getProbabilityColor(85), AppColors.signalGood);
      expect(AppColors.getProbabilityLabel(85), 'Optimal Bite');
    });

    testWidgets('LegalStatusBadge renders for open waters vs reserves',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LegalStatusBadge(isRestricted: false),
                LegalStatusBadge(isRestricted: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Open Waters'), findsOneWidget);
      expect(find.text('Marine Reserve'), findsOneWidget);
    });

    testWidgets('ConditionStatChip displays value and label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConditionStatChip(
              label: 'Wind Speed',
              value: '14 kts',
            ),
          ),
        ),
      );

      expect(find.text('14 kts'), findsOneWidget);
      expect(find.text('Wind Speed'), findsOneWidget);
    });

    testWidgets('AlertBanner displays title, message, and dismiss',
        (WidgetTester tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertBanner(
              title: 'High Swell Advisory',
              message: 'Wave heights exceeding 2.2m off Ras Al Hadd',
              severity: AlertSeverity.warning,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('High Swell Advisory'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(dismissed, isTrue);
    });
  });
}
