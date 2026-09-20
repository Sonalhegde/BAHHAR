import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weather_conditions.dart';
import '../services/weather_service.dart';

final weatherServiceProvider =
    Provider<WeatherService>((ref) => WeatherService());

final weatherConditionsProvider = FutureProvider<WeatherConditions>((ref) async {
  // Same coordinate as the marine card, so the two readouts always describe one place.
  return ref.watch(weatherServiceProvider).getConditions(23.6143, 58.5453);
});
