import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  PreferencesNotifier() : super(const UserPreferences());

  void toggleUnits() => state = state.copyWith(isMetric: !state.isMetric);
  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);
  void toggleWeatherAlerts(bool val) => state = state.copyWith(weatherAlerts: val);
  void toggleMarineAlerts(bool val) => state = state.copyWith(marineAlerts: val);
  void toggleTripReminders(bool val) => state = state.copyWith(tripReminders: val);
  void toggleHotspotUpdates(bool val) => state = state.copyWith(hotspotUpdates: val);
  void toggleLicenceExpiryReminders(bool val) => state = state.copyWith(licenceExpiryReminders: val);
  void toggleSafetyAlerts(bool val) => state = state.copyWith(safetyAlerts: val);
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
  return PreferencesNotifier();
});

// ─── Language Provider ────────────────────────────────────────────────────────

class LanguageNotifier extends StateNotifier<bool> {
  LanguageNotifier() : super(false); // false = English, true = Arabic

  void toggleLanguage() => state = !state;
  void setArabic(bool val) => state = val;
  void setEnglish() => state = false;
}

final isArabicProvider =
    StateNotifierProvider<LanguageNotifier, bool>((ref) => LanguageNotifier());

// ─── Governorate Provider ─────────────────────────────────────────────────────

class GovernorateNotifier extends StateNotifier<String> {
  GovernorateNotifier() : super('Muscat');
  void setGovernorate(String g) => state = g;
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
