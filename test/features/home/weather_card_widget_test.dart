import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahhar/core/models/weather_conditions.dart';
import 'package:bahhar/features/home/presentation/widgets/weather_card_widget.dart';
import 'package:bahhar/shared/widgets/condition_stat_chip.dart';
import 'package:bahhar/shared/widgets/skeleton.dart';

/// A reading with nothing optional left unset, so a test that cares about one field
/// changes that field and nothing else.
WeatherConditions _weather({
  double tempC = 34,
  double feelsLikeC = 38,
  String condition = 'Partly cloudy',
  double humidityPct = 68,
  double windKmh = 18,
  String? windDir = 'NE',
  double? rainProbabilityPct = 5,
  double uvIndex = 9,
  List<WeatherHour> hourly = const [],
  List<WeatherDay> daily = const [],
  List<WeatherAlert> alerts = const [],
  String source = 'open-meteo',
  String attribution = 'Open-Meteo.com',
  String? note,
  bool isCached = false,
}) =>
    WeatherConditions(
      tempC: tempC,
      feelsLikeC: feelsLikeC,
      condition: condition,
      humidityPct: humidityPct,
      windKmh: windKmh,
      windDir: windDir,
      rainProbabilityPct: rainProbabilityPct,
      uvIndex: uvIndex,
      hourly: hourly,
      daily: daily,
      alerts: alerts,
      source: source,
      attribution: attribution,
      note: note,
      lastUpdated: DateTime.now(),
      isCached: isCached,
    );

Future<void> _pump(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: card)),
  ));
  await tester.pumpAndSettle();
}

/// The chip carrying [label], so a test can read its warning state instead of
/// guessing at it from a colour.
ConditionStatChip _chip(WidgetTester tester, String label) => tester.widget<
    ConditionStatChip>(find.ancestor(
  of: find.text(label),
  matching: find.byType(ConditionStatChip),
));

void main() {
  group('WeatherCardWidget — data shape', () {
    testWidgets('prints the air, humidity and UV readings it was handed',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(_weather())));

      expect(find.text('WEATHER'), findsOneWidget);
      expect(find.text('34°C'), findsOneWidget);
      expect(find.text('Feels 38°'), findsOneWidget);
      expect(find.text('68%'), findsOneWidget);
      expect(find.text('Partly cloudy'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('Very high'), findsOneWidget);
      expect(find.text('Wind 18 km/h NE • Rain 5%'), findsOneWidget);
      expect(find.byType(ConditionStatChip), findsNWidgets(3));
    });

    testWidgets('rounds a fractional UV index for display but keeps its band',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather:
                  AsyncData<WeatherConditions>(_weather(uvIndex: 6.8))));

      expect(find.text('7'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('warns on heat stress, which is the felt temperature',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(
                  _weather(tempC: 34, feelsLikeC: 41))));

      expect(_chip(tester, 'AIR TEMP').isWarning, isTrue);
      // UV 9 sits in the very-high band, so two chips may be amber at once.
      expect(_chip(tester, 'UV').isWarning, isTrue);
    });

    testWidgets('a mild day warns nowhere', (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(
                  _weather(feelsLikeC: 33, uvIndex: 4))));

      expect(_chip(tester, 'AIR TEMP').isWarning, isFalse);
      expect(_chip(tester, 'UV').isWarning, isFalse);
      expect(find.text('Moderate'), findsOneWidget);
    });

    testWidgets('quotes the proxy note verbatim instead of paraphrasing it',
        (tester) async {
      const note = 'AccuWeather is not configured; serving Open-Meteo.';
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather:
                  AsyncData<WeatherConditions>(_weather(note: note))));

      expect(find.text(note), findsOneWidget);
      // The note replaces the source line rather than duplicating it.
      expect(find.text('Source: Open-Meteo.com'), findsNothing);
    });

    testWidgets('falls back to attribution when the proxy has nothing to explain',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(_weather())));

      expect(find.text('Source: Open-Meteo.com'), findsOneWidget);
    });
  });

  group('WeatherCardWidget — honest provenance', () {
    testWidgets('calls a sample reading a sample', (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(
                  _weather(source: 'mock'))));

      expect(find.text('Sample data — no weather provider is connected'),
          findsOneWidget);
    });

    testWidgets('stamps a cached reading with the time it was taken',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(
                  _weather(isCached: true))));

      expect(find.textContaining('showing last known weather'), findsOneWidget);
      expect(find.text('Sample data — no weather provider is connected'),
          findsNothing);
    });

    testWidgets('live data gets neither warning', (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(_weather())));

      expect(find.textContaining('showing last known weather'), findsNothing);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      expect(find.byIcon(Icons.science_outlined), findsNothing);
    });

    testWidgets('an hour strip is drawn only from the hours provided',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
            asyncWeather: AsyncData<WeatherConditions>(_weather(hourly: const [
              WeatherHour(
                  time: '14:00',
                  tempC: 35.4,
                  condition: 'Sunny',
                  rainProbabilityPct: 0),
              WeatherHour(
                  time: '15:00',
                  tempC: 35.0,
                  condition: 'Sunny',
                  rainProbabilityPct: 10),
            ])),
          ),
        );

      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('35°'), findsNWidgets(2));
      expect(find.text('10%'), findsOneWidget);
    });

    testWidgets('no hour strip at all when the provider sent no hours',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(_weather())));

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('the five-day outlook is drawn from the days provided',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(_weather(daily: const [
                WeatherDay(
                    date: '2026-09-21',
                    highC: 33.2,
                    lowC: 26.4,
                    condition: 'Sunny'),
                WeatherDay(
                    date: '2026-09-22',
                    highC: 31.2,
                    lowC: 24.4,
                    condition: 'Partly cloudy'),
              ]))));

      // 2026-09-21 is a Monday; the label is the model's, not the widget's.
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('33°'), findsOneWidget);
      expect(find.text('26°'), findsOneWidget);
    });

    testWidgets('a sixth day does not widen the row past five', (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(_weather(daily: const [
                WeatherDay(date: '2026-09-21', highC: 33, lowC: 26, condition: ''),
                WeatherDay(date: '2026-09-22', highC: 32, lowC: 26, condition: ''),
                WeatherDay(date: '2026-09-23', highC: 32, lowC: 25, condition: ''),
                WeatherDay(date: '2026-09-24', highC: 31, lowC: 25, condition: ''),
                WeatherDay(date: '2026-09-25', highC: 32, lowC: 26, condition: ''),
                WeatherDay(date: '2026-09-26', highC: 33, lowC: 26, condition: ''),
              ]))));

      // Six entries in, five tiles out — the proxy sends five and so does the card.
      expect(find.text('Sat'), findsNothing);
      expect(find.text('31°'), findsOneWidget);
    });

    testWidgets('the outlook is read in Arabic when the app is', (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              isArabic: true,
              asyncWeather: AsyncData<WeatherConditions>(_weather(daily: const [
                WeatherDay(
                    date: '2026-09-21',
                    highC: 33,
                    lowC: 26,
                    condition: 'Sunny'),
              ]))));

      expect(find.text('اثنين'), findsOneWidget);
      expect(find.text('Mon'), findsNothing);
    });
  });

  group('WeatherCardWidget — alerts only when someone issued one', () {
    testWidgets('renders no alert block when the provider published none',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(_weather())));

      // Nothing in the card's own copy uses ' — ' unless an alert or the stale row
      // is present, so a clean reading carries no dash at all.
      expect(find.textContaining(' — '), findsNothing);
    });

    testWidgets('renders the alert title and its severity', (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
            asyncWeather: AsyncData<WeatherConditions>(_weather(alerts: const [
              WeatherAlert(title: 'Dense fog advisory', severity: 'Moderate'),
            ])),
          ),
        );

      expect(find.text('Dense fog advisory — Moderate'), findsOneWidget);
    });

    testWidgets('an alert with no stated severity does not invent one',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
            asyncWeather: AsyncData<WeatherConditions>(_weather(alerts: const [
              WeatherAlert(title: 'Thunderstorm watch'),
            ])),
          ),
        );

      expect(find.text('Thunderstorm watch'), findsOneWidget);
    });
  });

  group('WeatherCardWidget — missing data', () {
    testWidgets('omits a wind bearing nobody measured', (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather:
                  AsyncData<WeatherConditions>(_weather(windDir: null))));

      expect(find.text('Wind 18 km/h • Rain 5%'), findsOneWidget);
      expect(find.textContaining('NE'), findsNothing);
    });

    testWidgets('an absent rain probability reads as none expected',
        (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncData<WeatherConditions>(
                  _weather(rainProbabilityPct: null))));

      expect(find.text('Wind 18 km/h NE • Rain 0%'), findsOneWidget);
    });
  });

  group('WeatherCardWidget — loading, error, Arabic', () {
    testWidgets('loading shows three skeletons, not an empty card',
        (tester) async {
      // No pumpAndSettle here: SkeletonBox shimmers on a repeating ticker, so the
      // loading frame never settles — and it is exactly this frame being checked.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WeatherCardWidget(
                asyncWeather: const AsyncLoading<WeatherConditions>()),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('WEATHER'), findsOneWidget);
      expect(find.byType(ConditionStatChip), findsNothing);
      expect(find.byType(SkeletonBox), findsNWidgets(3));
    });

    testWidgets('error says the weather failed, in English', (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              asyncWeather: AsyncError<WeatherConditions>(
                  Exception('offline'), StackTrace.empty)));

      expect(find.text('Failed to load weather.'), findsOneWidget);
    });

    testWidgets('error says the same in Arabic', (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              isArabic: true,
              asyncWeather: AsyncError<WeatherConditions>(
                  Exception('offline'), StackTrace.empty)));

      expect(find.text('الطقس'), findsOneWidget);
      expect(find.text('تعذر تحميل حالة الطقس'), findsOneWidget);
    });

    testWidgets('data is read in Arabic when the app is', (tester) async {
      await _pump(
          tester,
          WeatherCardWidget(
              isArabic: true,
              asyncWeather:
                  AsyncData<WeatherConditions>(_weather(uvIndex: 2))));

      expect(find.text('الطقس'), findsOneWidget);
      expect(find.text('الحرارة'), findsOneWidget);
      expect(find.text('الرطوبة'), findsOneWidget);
      expect(find.text('منخفض'), findsOneWidget);
      expect(find.textContaining('الرياح'), findsOneWidget);
      expect(find.text('WEATHER'), findsNothing);
    });
  });
}
