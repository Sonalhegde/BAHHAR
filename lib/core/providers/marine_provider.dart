import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marine_conditions.dart';
import '../services/marine_service.dart';

final marineConditionsProvider = FutureProvider<MarineConditions>((ref) async {
  // Coordinates default to Muscat coastal waters
  return MarineService.getConditions(23.6143, 58.5453);
});
