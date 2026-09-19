import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marine_conditions.dart';
import '../services/marine_service.dart';

final marineServiceProvider = Provider<MarineService>((ref) => MarineService());

final marineConditionsProvider = FutureProvider<MarineConditions>((ref) async {
  // Coordinates default to Muscat coastal waters
  return ref.watch(marineServiceProvider).getConditions(23.6143, 58.5453);
});
