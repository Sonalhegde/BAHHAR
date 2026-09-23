import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/location_service.dart';

/// The device location wrapper. Overridable in tests to inject a fake fix or a
/// forced fallback so the weather/marine/map providers can be exercised without a
/// location plugin.
final locationServiceProvider =
    Provider<LocationService>((_) => const LocationService());

/// The ONE position every location-aware feature shares — weather, marine
/// conditions and the map camera all watch this, so the app never shows Muscat's
/// numbers to a fisherman standing in Salalah. Resolves once per app session and
/// carries an honest [ResolvedLocation.source] flag so a fallback is never mistaken
/// for a real fix.
final locationProvider = FutureProvider<ResolvedLocation>(
  (ref) => ref.watch(locationServiceProvider).resolve(),
);
