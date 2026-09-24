import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marine_conditions.dart';
import '../models/tide_curve.dart';
import '../services/marine_service.dart';
import 'location_provider.dart';

final marineServiceProvider = Provider<MarineService>((ref) => MarineService());

final marineConditionsProvider = FutureProvider<MarineConditions>((ref) async {
  // The fisherman's resolved position - never a hardcoded Muscat coordinate. The
  // weather card watches the same locationProvider so both describe one place.
  final loc = await ref.watch(locationProvider.future);
  return ref.watch(marineServiceProvider).getConditions(loc.latitude, loc.longitude);
});

/// The continuous tide curve behind the "Rising / 1.4 m" reading, sourced from the
/// SAME resolved location so the chart and the number describe the same water.
/// Kept as its own provider (not folded into marineConditionsProvider) so a slow
/// tide fetch cannot block the conditions grid from painting.
final tideCurveProvider = FutureProvider<TideCurve>((ref) async {
  final loc = await ref.watch(locationProvider.future);
  return ref.watch(marineServiceProvider).getTideCurve(loc.latitude, loc.longitude);
});
