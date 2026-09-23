import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weather_conditions.dart';
import '../services/weather_service.dart';
import 'location_provider.dart';

final weatherServiceProvider =
    Provider<WeatherService>((ref) => WeatherService());

final weatherConditionsProvider = FutureProvider<WeatherConditions>((ref) async {
  // Resolved from the fisherman's actual position; the marine card watches the
  // same locationProvider, so both readouts always describe one place.
  final loc = await ref.watch(locationProvider.future);
  return ref.watch(weatherServiceProvider).getConditions(loc.latitude, loc.longitude);
});
