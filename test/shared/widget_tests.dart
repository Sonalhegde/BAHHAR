import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/shared/widgets/fishing_score_gauge.dart';
import 'package:bahhar/shared/widgets/legal_status_badge.dart';
import 'package:bahhar/shared/widgets/condition_stat_chip.dart';
import 'package:bahhar/shared/widgets/alert_banner.dart';

void main() {
  group('Bahhar AI Shared Components Tests', () {
    testWidgets('FishingScoreGauge renders with correct percentage and high band color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FishingScoreGauge(probability: 85),
          ),
        ),
      );

      expect(find.byType(FishingScoreGauge), findsOneWidget);
      expect(AppColors.getProbabilityColor(85), AppColors.aquaTeal);
      expect(AppColors.getProbabilityLabel(85), 'High');
    });

    testWidgets('LegalStatusBadge renders distinctly for permitted and protected zones',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LegalStatusBadge(status: LegalStatus.permitted),
                LegalStatusBadge(status: LegalStatus.protected),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Permitted'), findsOneWidget);
      expect(find.text('Protected Reserve'), findsOneWidget);
    });

    testWidgets('ConditionStatChip displays numeric value and label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConditionStatChip(
              icon: Icons.air,
              value: '14 kts',
              label: 'Wind Speed',
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
              message: 'Wave heights exceeding 2.2m off Ras Al Jinz',
              severity: AlertSeverity.warning,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('High Swell Advisory'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });
  });
}
