import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import '../services/prefs_service.dart';

// ─── User Preferences ────────────────────────────────────────────────────────

class UserPreferences {
  final bool isMetric;
  final ThemeMode themeMode;
  final bool weatherAlerts;
  final bool marineAlerts;
  final bool tripReminders;
  final bool hotspotUpdates;
  final bool licenceExpiryReminders;
  final bool safetyAlerts;

  const UserPreferences({
    this.isMetric = true,
    this.themeMode = ThemeMode.light,
    this.weatherAlerts = true,
    this.marineAlerts = true,
    this.tripReminders = true,
    this.hotspotUpdates = true,
    this.licenceExpiryReminders = true,
    this.safetyAlerts = true,
  });

  UserPreferences copyWith({
    bool? isMetric,
    ThemeMode? themeMode,
    bool? weatherAlerts,
    bool? marineAlerts,
    bool? tripReminders,
    bool? hotspotUpdates,
    bool? licenceExpiryReminders,
    bool? safetyAlerts,
  }) {
    return UserPreferences(
      isMetric: isMetric ?? this.isMetric,
      themeMode: themeMode ?? this.themeMode,
      weatherAlerts: weatherAlerts ?? this.weatherAlerts,
      marineAlerts: marineAlerts ?? this.marineAlerts,
      tripReminders: tripReminders ?? this.tripReminders,
      hotspotUpdates: hotspotUpdates ?? this.hotspotUpdates,
      licenceExpiryReminders: licenceExpiryReminders ?? this.licenceExpiryReminders,
      safetyAlerts: safetyAlerts ?? this.safetyAlerts,
    );
  }
}

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  PreferencesNotifier() : super(UserPreferences(
        isMetric: PrefsService.getMetricUnits(),
        themeMode: PrefsService.getThemeMode(),
      ));

  void toggleUnits() {
    state = state.copyWith(isMetric: !state.isMetric);
    _remember(PrefsService.setMetricUnits(state.isMetric));
  }
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _remember(PrefsService.setThemeMode(mode));
  }
  void toggleWeatherAlerts(bool val) => state = state.copyWith(weatherAlerts: val);
  void toggleMarineAlerts(bool val) => state = state.copyWith(marineAlerts: val);
  void toggleTripReminders(bool val) => state = state.copyWith(tripReminders: val);
  void toggleHotspotUpdates(bool val) => state = state.copyWith(hotspotUpdates: val);
  void toggleLicenceExpiryReminders(bool val) => state = state.copyWith(licenceExpiryReminders: val);
  void toggleSafetyAlerts(bool val) => state = state.copyWith(safetyAlerts: val);
}

/// Fire-and-forget a preference write.
///
/// A setting that fails to persist is still the setting the fisherman chose for this
/// session; refusing to toggle it because the device could not remember it would be
/// the worse answer. Returns void on purpose, so no caller is tricked into awaiting a
/// save that has already taken effect on screen.
void _remember(Future<void> future) {
  future.catchError((Object _) {});
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
  return PreferencesNotifier();
});

// ─── Language Provider ────────────────────────────────────────────────────────

class LanguageNotifier extends StateNotifier<bool> {
  // false = English, true = Arabic. Restored from the device, not re-asked each run.
  LanguageNotifier() : super(PrefsService.getArabic());

  void toggleLanguage() {
    state = !state;
    _remember(PrefsService.setArabic(state));
  }

  void setArabic(bool val) {
    state = val;
    _remember(PrefsService.setArabic(val));
  }

  void setEnglish() => setArabic(false);
}

final isArabicProvider =
    StateNotifierProvider<LanguageNotifier, bool>((ref) => LanguageNotifier());

// ─── Governorate Provider ─────────────────────────────────────────────────────

class GovernorateNotifier extends StateNotifier<String> {
  GovernorateNotifier() : super(PrefsService.getGovernorate());

  /// Changing the port changes which coast the fisherman wants warnings about, so the
  /// push topic follows it. Inert without Firebase, so a demo build pays nothing.
  void setGovernorate(String g) {
    final previous = state;
    state = g;
    _remember(PrefsService.setGovernorate(g));
    if (previous != g) {
      _remember(NotificationService.unsubscribeRegion(previous));
      _remember(NotificationService.subscribeRegion(g));
    }
  }
}

final selectedGovernorateProvider =
    StateNotifierProvider<GovernorateNotifier, String>(
        (ref) => GovernorateNotifier());

// ─── Location Tracking Mode ───────────────────────────────────────────────────

enum LocationTrackingMode { off, mapOnly, activeTrip }

class LocationTrackingNotifier extends StateNotifier<LocationTrackingMode> {
  LocationTrackingNotifier() : super(LocationTrackingMode.off);
  void setMode(LocationTrackingMode mode) => state = mode;
  void turnOff() => state = LocationTrackingMode.off;
}

final locationTrackingProvider =
    StateNotifierProvider<LocationTrackingNotifier, LocationTrackingMode>(
        (ref) => LocationTrackingNotifier());
