import 'package:geolocator/geolocator.dart';

import 'prefs_service.dart';

/// A position the app actually used, plus the honesty flag describing *how* it was
/// obtained. The whole point of the flag is that a fallback coordinate can never
/// quietly masquerade as the fisherman's real location: every consumer (map camera,
/// weather/marine query, the visible chip) reads [source] and behaves accordingly.
class ResolvedLocation {
  const ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final LocationSource source;

  /// True when the coordinate is the Muscat default because we could not get a real
  /// fix — the UI must say so rather than silently showing Muscat's weather.
  bool get isFallback => source == LocationSource.fallback;

  /// Fresh GPS or restored cache: usable as "where you are".
  bool get isReal => source == LocationSource.live || source == LocationSource.lastKnown;

  ({double lat, double lon}) toLatLngPair() => (lat: latitude, lon: longitude);
}

/// How a [ResolvedLocation] was arrived at. Ordered by confidence.
enum LocationSource {
  /// A live GPS fix from the device this session.
  live,

  /// The last fix we cached on this device (a real position, just not current).
  lastKnown,

  /// The Muscat reference coordinate, used only when nothing better was available.
  fallback,
}

/// Wraps the `geolocator` plugin behind one resilient entry point.
///
/// The rule this service exists to enforce: never pretend a fallback is a fix. It
/// asks permission (only when told to), reads a position, caches it for next time,
/// and on any denial or platform failure degrades to the last cached position and
/// then to the Muscat default — each step labelled by [ResolvedLocation.source].
///
/// Every plugin call is guarded: on a host with no location plugin (widget tests)
/// the calls throw, are caught, and the service returns an honest fallback instead
/// of hanging or crashing the caller.
class LocationService {
  /// Muscat/Seeb coastal waters — the app's reference point, never the assumed home.
  static const double fallbackLat = 23.6143;
  static const double fallbackLon = 58.5453;

  const LocationService();

  static ResolvedLocation? _lastResolved;

  /// The most recent [resolve] outcome, so the map recenter button and the weather
  /// card agree on one position without re-prompting for permission.
  static ResolvedLocation? get lastResolved => _lastResolved;

  /// Resolves the position to build the app around.
  ///
  /// [prompt] gates whether a denied permission may escalate to the OS request
  /// dialog; the first automatic pass uses `true`, a silent re-read uses `false`.
  Future<ResolvedLocation> resolve({bool prompt = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _degrade();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && prompt) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _degrade();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.best),
      );

      await PrefsService.setLastKnownLocation(position.latitude, position.longitude);
      final resolved = ResolvedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        source: LocationSource.live,
      );
      _lastResolved = resolved;
      return resolved;
    } catch (_) {
      // MissingPluginException on a test host, service errors on a real device —
      // either way, fall back honestly rather than throw into a provider build.
      return _degrade();
    }
  }

  /// Restores a cached position if we have one, otherwise the labelled fallback.
  ResolvedLocation _degrade() {
    final cached = PrefsService.getLastKnownLocation();
    final resolved = cached != null
        ? ResolvedLocation(
            latitude: cached.lat,
            longitude: cached.lon,
            source: LocationSource.lastKnown,
          )
        : const ResolvedLocation(
            latitude: fallbackLat,
            longitude: fallbackLon,
            source: LocationSource.fallback,
          );
    _lastResolved = resolved;
    return resolved;
  }
}
