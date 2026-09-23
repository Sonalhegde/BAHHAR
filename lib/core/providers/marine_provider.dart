import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marine_conditions.dart';
import '../services/marine_service.dart';
import 'location_provider.dart';

final marineServiceProvider = Provider<MarineService>((ref) => MarineService());

final marineConditionsProvider = FutureProvider<MarineConditions>((ref) async {
  // The fisherman's resolved position — never a hardcoded Muscat coordinate. The
  // weather card watches the same locationProvider so both describe one place.
  final loc = await ref.watch(locationProvider.future);
  return ref.watch(marineServiceProvider).getConditions(loc.latitude, loc.longitude);
});
