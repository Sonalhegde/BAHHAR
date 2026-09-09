# BAHHAR (بحّار)

Oman-specific smart fishing companion.

## Tech Stack
- **Mobile Frontend**: Flutter (Android + iOS)
- **Backend & Cloud Services**: Firebase (Auth, Firestore, Storage, FCM, App Check)
- **Maps & Geospatial**: Google Maps Platform
- **Intelligence**: Python / FastAPI ML service

## Environment & SDK Specifications
- **Flutter SDK**: 3.47.1 (stable)
- **Dart SDK**: 3.13.1 (stable)
- **Target Platforms**: Android, iOS
- **Organization**: `com.bahharai`
- **Application ID**: `com.bahharai.bahhar`

## Project Structure
The project follows a feature-driven architecture mapped directly to the approved 10-screen wireframe:
- `lib/core/`: Constants, Theme, Routing, Services, Utils
- `lib/features/`:
  1. Splash (`splash/presentation/splash_screen.dart`)
  2. Login / Register (`auth/presentation/login_register_screen.dart`)
  3. Home Dashboard (`home/presentation/home_dashboard_screen.dart`)
  4. Fishing Map (`map/presentation/fishing_map_screen.dart`)
  5. Hotspot Details (`hotspot/presentation/hotspot_details_screen.dart`)
  6. Smart Trip Wizard (`smart_trip/presentation/smart_trip_wizard_screen.dart`)
  7. Trip Recommendation (`smart_trip/presentation/trip_recommendation_screen.dart`)
  8. My Catch - Add New (`my_catch/presentation/add_catch_screen.dart`)
  9. My Catch - History (`my_catch/presentation/catch_history_screen.dart`)
  10. Profile (`profile/presentation/profile_screen.dart`)
- `lib/l10n/`: English (`app_en.arb`) and Arabic (`app_ar.arb`) localization with full RTL support

## Getting Started
<!-- TODO: Add setup instructions once Firebase credentials and API keys are provisioned -->
