# Changelog

All notable changes to the BAHHAR project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### ✨ Added
- **Live marine & tide data integration** — FastAPI proxy `GET /api/v1/marine/conditions` +
  `GET /api/v1/tides` aggregating Open-Meteo (weather + marine, keyless) and WorldTides v3,
  with server-side TTL caching and 502/503 upstream-failure handling. WorldTides key is held
  only in `backend/.env`, never shipped in the Flutter binary.
- **Flutter live `MarineService`** — replaces the simulated service; fetches via `ApiClient`,
  falls back to the last-known snapshot when offline/stale, and the Home dashboard shows a
  "Last updated … showing last known conditions" banner.
- **Landing website redesign** (`landing-page.html`) — full-bleed hero, verified glassmorphism
  system, alternating story pillars, custom nautical-chart SVG, 8 distinct species silhouettes,
  GSAP/ScrollTrigger reveals with fallback, mobile hamburger and working EN ⇄ AR RTL toggle.
- **`.vercelignore`** to scope Vercel uploads to web assets (never secrets or app source).
- Backend test suite expanded to **9 passing** cases (marine/tide proxy + tide-state derivation).

### 📚 Documentation
- Consolidated the four overlapping specification docs into a single unified
  **[SPECIFICATION.md](SPECIFICATION.md)** and rewrote **[README.md](README.md)** to the canonical
  structure (removed un-implemented overclaims, fixed dead links).
- Added **[QA_REPORT.md](QA_REPORT.md)** (test matrix, security/secret scan, deferred items).

### 🔧 Fixed
- Landing pillars did not alternate (CSS `order` no-op).
- Stale docs that described the app as "simulation only".

---

## [1.0.0] - 2026-09-15 - Production Release Preparation

### 🎉 Initial Release

This is the first production-ready release of BAHHAR AI, the smart fishing companion for Omani coastal waters.

### ✨ Added - Flutter Application

#### Core Features
- **Home Dashboard**: Real-time fishing score gauge, marine conditions, hotspot recommendations
- **Interactive Map**: Google Maps integration with custom nautical styling, protected area overlays
- **Trip Planner**: 4-step wizard for optimized route planning with fuel estimates
- **Catch Logging**: Comprehensive catch recording with GPS, photos, species, weight, length
- **User Profile**: Bilingual interface (English/Arabic), preferred port selection
- **Splash Screen**: Branded introduction with navigation seal and bilingual typography
- **Authentication**: Multi-method login (Phone OTP, Google, Apple, Email, Guest mode)
- **Notifications**: Marine advisories and weather warnings system

#### Core Utilities (Implemented in this release)
- **validators.dart**: Oman phone number (+968), email, password, coordinate validators
- **formatters.dart**: Temperature, wave height, coordinates, dates, distances, durations
- **geo_helpers.dart**: Haversine distance calculations, bearing, EEZ boundary checks
- **api_client.dart**: Full-featured HTTP client with GET/POST/PUT/DELETE, error handling

#### State Management
- Riverpod 2.5+ providers for reactive state
- Auth state management with Firebase Auth
- Marine conditions provider with real-time updates
- Hotspots provider with location-based filtering
- Trip planning provider with ML integration points
- Catch history provider with Firestore sync

#### Services
- Firebase Auth integration (Phone, Google, Apple, Guest)
- Cloud Firestore for data persistence
- Cloud Storage for catch photos
- Firebase Cloud Messaging for push notifications
- Geofence service for marine reserve boundaries
- Trip service with route optimization
- Marine service for real-time conditions

#### Design System
- Premium White Editorial theme (v2)
- Clean, distraction-free interface optimized for bright sun
- Neutral white surfaces with dark typography
- Hairline dividers and subtle backgrounds
- Single navy accent color (#12263A)
- Signal colors: Good (green), Caution (amber), Alert (red)
- Protected area purple (#6B5B95)

#### Localization
- English and Arabic (عربي) support
- Instant language switching
- RTL layout support
- Bilingual species names and maritime terminology

### ✨ Added - Backend ML Service

#### API Endpoints
- `GET /`: Health check endpoint
- `POST /api/v1/predict`: ML-powered fishing probability predictions
  - Species-specific scoring (Kingfish, Tuna, Hammour, etc.)
  - SST (Sea Surface Temperature) analysis
  - Tidal influence calculations
  - Wave and wind safety modulation
- `POST /api/v1/geofence/verify`: Marine reserve boundary verification
  - Daymaniyat Islands Nature Reserve
  - Ras Al Jinz Turtle Sanctuary
  - Strait of Hormuz shipping corridor

#### Marine Data
- Omani coastal species database
- Protected marine reserves with legal decrees
- Haversine distance calculations
- Geofencing polygon checks

#### Testing
- Comprehensive pytest test suite (3/3 passing)
- Health check validation
- Kingfish optimal condition prediction test
- Daymaniyat protected area geofence test

### ✨ Added - Android Configuration

#### Build System
- Gradle 8.x configuration
- Multi-dex support for large app size
- Version management from pubspec.yaml
- Firebase Google Services plugin integration

#### App Signing
- Release signing configuration with keystore support
- Key properties file integration
- Separate debug and release build types

#### Code Obfuscation
- ProGuard/R8 minification and shrinking
- Custom ProGuard rules for Flutter, Firebase, Google Maps
- Preserved line numbers for crash reports

#### Dependencies
- Material Design Components 1.11.0
- Google Play Services Maps 18.2.0
- Google Play Services Location 21.1.0
- Firebase BOM 32.7.2 (Analytics, Auth, Firestore, Storage, Messaging)

#### Permissions
- ACCESS_FINE_LOCATION: GPS tracking
- ACCESS_COARSE_LOCATION: Network-based location
- INTERNET: API calls and Firebase sync
- CAMERA: Catch photo capture

### 📚 Added - Documentation

#### Comprehensive Guides
- **README.md**: 500+ lines covering architecture, installation, testing, deployment
- **ANDROID_PUBLICATION_GUIDE.md**: 1000+ lines step-by-step Play Store publication
  - Firebase setup instructions
  - Google Maps API configuration
  - App signing with keystore creation
  - Play Store listing and submission
  - Security checklist
  - Post-publication monitoring
- **UNCOMPLETED_TASKS.md**: Updated with current blockers and completion status
- **CHANGELOG.md**: This file
- **CLIENT_ARCHITECTURE_AND_FEATURE_SPECIFICATION.md**: Technical architecture (existing)

#### Code Documentation
- Comprehensive inline comments in all utility classes
- API documentation for all public methods
- Model documentation with field descriptions
- Service class documentation

### 🔧 Fixed - Backend

#### Deprecation Warnings
- **Pydantic v2**: Replaced deprecated `Field(example=...)` with `json_schema_extra`
- **datetime**: Replaced `datetime.utcnow()` with `datetime.now(UTC)`

#### Code Quality
- Proper ConfigDict usage for Pydantic models
- Type hints throughout
- Clean import statements

### 🔧 Fixed - Flutter

#### Missing Implementations
- Implemented all core utility classes (previously empty placeholders)
- Added HTTP client for backend communication
- Completed validation and formatting utilities
- Implemented geolocation helpers

#### Dependencies
- Added `http: ^1.2.0` for API communication
- Updated pubspec.yaml with proper versioning

### 🚀 Build & Deployment

#### Build Commands
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

#### Backend Deployment
```bash
# Local development
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# Docker (future)
docker build -t bahhar-backend .
docker run -p 8000:8000 bahhar-backend
```

### 📊 Testing

#### Backend Tests
- ✅ 3/3 tests passing
- ✅ Health check validation
- ✅ ML prediction accuracy
- ✅ Geofence boundary verification

#### Flutter Tests
- ⚠️ Core unit tests implemented
- ⚠️ Widget tests are placeholders (future implementation)
- ⚠️ Integration tests not yet implemented

### 🔒 Security

#### Implemented
- ProGuard code obfuscation for release builds
- Firebase security rules (firestore.rules, storage.rules)
- API key restrictions framework
- User data isolation in Firestore
- Secure keystore signing

#### Recommendations
- Enable Firebase App Check
- Implement certificate pinning
- Regular dependency security audits
- Penetration testing before production

### 📱 Supported Platforms

- **Android**: API 23+ (Android 6.0 Marshmallow and above)
- **iOS**: Not yet configured (future release)

### 🌍 Supported Regions

All Omani coastal regions:
- Musandam (Khasab, Bukha)
- Al Batinah (Sohar, Barka)
- Muscat (Mutrah, Marina Bandar Al Rowdha)
- Ash Sharqiyah (Sur, Ras Al Hadd)
- Al Wusta (Duqm)
- Dhofar (Salalah, Mirbat)

### 🐠 Supported Species

- Kingfish (كنعد / Kanaad)
- Yellowfin Tuna (ثمد / Thamad)
- Hammour (هامور / Grouper)
- Amberjack
- Sailfish
- Mahi Mahi
- And more...

### ⚠️ Known Limitations

#### Configuration Required
- Firebase configuration files not included (security)
- Google Maps API key not included (security)
- App signing keystore must be generated
- Requires manual Firebase service enablement

#### Functional Gaps
- Some widget implementations are placeholders
- Trip planning uses heuristic (not full ML yet)
- Guest mode data not persisted
- iOS platform not configured
- Email/password auth intentionally disabled

See [SPECIFICATION.md](SPECIFICATION.md) §9 (Implementation Status & Roadmap) for the complete list.

### 📦 Dependencies

#### Flutter (pubspec.yaml)
```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.2
  firebase_messaging: ^15.1.3
  google_maps_flutter: ^2.10.0
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^6.1.2
  image_picker: ^1.1.2
  geolocator: ^13.0.2
  http: ^1.2.0
  intl: ^0.19.0
  shared_preferences: ^2.2.3
  flutter_svg: ^2.0.10
```

#### Python (requirements.txt)
```
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
pydantic>=2.5.0
pytest>=7.4.0
httpx>=0.25.0
```

### 👥 Contributors

- **Development Team**: BAHHAR AI Engineering
- **Architecture**: System design and technical specification
- **Backend**: Python FastAPI ML microservice
- **Frontend**: Flutter mobile application
- **Documentation**: Comprehensive guides and API docs

### 🔗 Links

- **Repository**: https://github.com/Sonalhegde/BAHHAR
- **Documentation**: See README.md and guides
- **Support**: support@bahharai.com

---

## [Unreleased] - Future Versions

### Planned for v1.1.0 (Q4 2026)

#### Features
- [x] Tide prediction API integration (WorldTides v3, proxied via backend)
- [ ] Enhanced ML models with historical catch data
- [ ] Social features: catch sharing, leaderboards
- [ ] Advanced weather forecasting
- [ ] Implement all placeholder widgets
- [ ] Complete authentication providers
- [ ] Add shared_preferences persistence

#### Improvements
- [ ] Geohash-based Firestore queries
- [ ] Image compression before upload
- [ ] Comprehensive widget tests
- [ ] Performance optimizations

### Planned for v1.2.0 (Q1 2027)

#### Features
- [ ] Offline maps with OpenStreetMap
- [ ] Fish identification with computer vision
- [ ] Charter booking marketplace
- [ ] Multi-language support (Urdu, Hindi)

### Planned for v2.0.0 (Q2 2027)

#### Major Features
- [ ] IoT integration with boat sensors
- [ ] Real-time fish finder data overlay
- [ ] Community hotspot reporting
- [ ] Professional captain dashboard
- [ ] iOS App Store release

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2026-09-15 | Initial production release preparation |
| 0.9.0 | 2026-09-11 | Phase 2 development (v2 White theme) |
| 0.8.0 | 2026-09-01 | Phase 1 core features |
| 0.1.0 | 2026-08-15 | Project initialization |

---

**Maintained by**: BAHHAR Development Team  
**Last Updated**: September 15, 2026  
**Document Version**: 1.0.0
