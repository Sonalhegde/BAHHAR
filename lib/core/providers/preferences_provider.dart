import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserPreferences {
  final bool isMetric;
  final ThemeMode themeMode;
  final bool weatherAlerts;
  final bool marineAlerts;
  final bool tripReminders;
  final bool hotspotUpdates;

  const UserPreferences({
    this.isMetric = true,
    this.themeMode = ThemeMode.system,
    this.weatherAlerts = true,
    this.marineAlerts = true,
    this.tripReminders = true,
    this.hotspotUpdates = true,
  });

  UserPreferences copyWith({
    bool? isMetric,
    ThemeMode? themeMode,
    bool? weatherAlerts,
    bool? marineAlerts,
    bool? tripReminders,
    bool? hotspotUpdates,
  }) {
    return UserPreferences(
      isMetric: isMetric ?? this.isMetric,
      themeMode: themeMode ?? this.themeMode,
      weatherAlerts: weatherAlerts ?? this.weatherAlerts,
      marineAlerts: marineAlerts ?? this.marineAlerts,
      tripReminders: tripReminders ?? this.tripReminders,
      hotspotUpdates: hotspotUpdates ?? this.hotspotUpdates,
    );
  }
}

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  PreferencesNotifier() : super(const UserPreferences());

  void toggleUnits() {
    state = state.copyWith(isMetric: !state.isMetric);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleWeatherAlerts(bool val) => state = state.copyWith(weatherAlerts: val);
  void toggleMarineAlerts(bool val) => state = state.copyWith(marineAlerts: val);
  void toggleTripReminders(bool val) => state = state.copyWith(tripReminders: val);
  void toggleHotspotUpdates(bool val) => state = state.copyWith(hotspotUpdates: val);
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
  return PreferencesNotifier();
});
