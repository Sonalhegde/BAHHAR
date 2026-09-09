# BAHHAR AI (بَحّار) — System Architecture, Features & Delivery Specification

**Version:** 2.0 (Premium White Editorial Release)  
**Target Platforms:** iOS & Android (Flutter)  
**Backend Infrastructure:** Firebase (Auth, Firestore, Cloud Storage, FCM) + Python/FastAPI ML Microservice  
**Repository:** [https://github.com/Sonalhegde/BAHHAR](https://github.com/Sonalhegde/BAHHAR)  
**Target Market:** Sultanate of Oman (Coastal Fishermen, Charter Skippers, Sport Anglers)

---

## 1. Executive Summary & Product Vision

**Bahhar AI (بحّار)** is an enterprise-grade, Oman-specific marine intelligence and smart fishing companion mobile application. In Arabic, *"Bahhar"* (بحّار) designates a traditional mariner or seasoned fisherman—a name deeply rooted in Omani maritime heritage.

The application converts complex oceanographic, meteorologic, tidal, bathymetric, and species-behavioral datasets into actionable, real-time fishing recommendations. Unlike generic global marine apps that treat all coastlines identically, Bahhar AI is architected from the ground up for the distinctive marine ecosystems of Oman—from the fjords of the **Musandam Peninsula** in the north, along the **Batinah coast** and **Muscat shelf**, to the deep upwelling trenches of **Ash Sharqiyah**, **Al Wusta**, and the seasonal monsoon (Khareef) waters of **Dhofar (Salalah)**.

### Core Value Propositions
1. **Oman-Tuned Machine Learning (ML)**: Predicts bite windows and target species presence (Kingfish/Kanaad, Yellowfin Tuna/Thamad, Hamoor, Amberjack, Sailfish) based on localized Sea Surface Temperature (SST) gradients, thermoclines, bathymetric drop-offs, and solunar tidal cycles.
2. **Strict Environmental & Regulatory Compliance**: Distinct geofencing and warning systems for protected marine sanctuaries (such as the *Daymaniyat Islands Nature Reserve* and *Khawr nature reserves*), ensuring fishermen operate lawfully under decrees of the Ministry of Agriculture, Fisheries and Water Resources and the Environment Authority.
3. **v2 Premium White Editorial Aesthetic**: A clean, quiet, distraction-free interface engineered for maximum legibility under bright Arabian sun at sea, utilizing neutral whites, hairline dividers, single accent navy, and muted probability signals.
4. **Resilient Offline Architecture**: Cached charts, offline GPS track logging, and local catch recording for offshore voyages outside cellular range.

---

## 2. End-to-End System Architecture

```
                                 ┌─────────────────────────────────────────────────┐
                                 │          BAHHAR FLUTTER CLIENT APP              │
                                 │       (Android & iOS - Riverpod 2.x)            │
                                 └───────┬─────────────────┬─────────────────┬─────┘
                                         │                 │                 │
                           Firebase Auth │                 │ Cloud Firestore │ Catch Photos
                           (Phone / OTP) │                 │ Sync & Caching  │ Uploads
                                         ▼                 ▼                 ▼
                         ┌─────────────────────────────────────────────────────────┐
                         │                    FIREBASE BACKEND                     │
                         │  • Firebase Auth (Oman +968 SMS OTP / Apple / Google)  │
                         │  • Cloud Firestore (Regional: me-central1 / me-west1)   │
                         │  • Cloud Storage (Compressed Catch Photos & Logs)       │
                         │  • Cloud Messaging (FCM Marine Hazard Advisories)       │
                         └─────────────────────────┬───────────────────────────────┘
                                                   │
                                                   ▼
                         ┌─────────────────────────────────────────────────────────┐
                         │               INTERNAL FASTAPI ML ENGINE                │
                         │             (Python 3.11+ / Uvicorn / Docker)           │
                         │  • /api/v1/predict (Solunar + SST Fishing Probabilities)│
                         │  • /api/v1/geofence/verify (Reserve Boundary Checking)  │
                         │  • /api/v1/trip/optimize (Waypoint & Fuel Routing)      │
                         └───────┬─────────────────────────────────┬───────────────┘
                                 │                                 │
                   External Marine Feeds             Astronomical & Bathymetric
                                 ▼                                 ▼
                     ┌───────────────────────┐         ┌───────────────────────┐
                     │ Open-Meteo / CMEMS /  │         │ NOAA / GEBCO 15-arcsec│
                     │  Copernicus Marine    │         │ Omani Coastal Tides   │
                     │ (Wave, Swell, Wind,   │         │ (High/Low Harmonics,  │
                     │      SST, Currents)   │         │   Solunar Tables)     │
                     └───────────────────────┘         └───────────────────────┘
```

### 2.1 Technology Stack

| Layer | Technology | Justification |
| :--- | :--- | :--- |
| **Mobile Client** | Flutter 3.x (Dart 3.x) | Cross-platform compilation for iOS and Android from a single performant codebase. |
| **State Management** | Flutter Riverpod 2.x | Compile-time safe, testable, reactive state providers with zero boilerplate. |
| **Routing** | GoRouter 14.x | Declarative, deep-link ready shell routing supporting persistent bottom tab navigation. |
| **Cartography & Maps** | Google Maps Platform SDK | Native vector rendering, custom nautical styling, and polygon geofence overlays. |
| **Cloud Infrastructure** | Firebase Suite | Real-time synchronization, enterprise-grade phone SMS verification, and automatic offline caching. |
| **ML Microservice** | Python 3.11+ / FastAPI | High-throughput asynchronous REST API for numerical matrix scoring and geofence polygon checks. |
| **Data Models** | Pydantic v2 / Freezed | Strict schema enforcement, input validation, and bidirectional JSON serialization. |

---

## 3. Comprehensive Feature Breakdown

### 3.1 Screen & Feature Directory

The application comprises **10 fully realized screens**, organized into modular, domain-driven feature packages:

#### 1. Introductory Splash & Brand Seal (`splash_screen.dart`)
- Features the authentic Bahhar nautical seal emblem with subtle smooth scale-in and fade transitions.
- Displays the bilingual brand typography (**BAHHAR / بَحّار**) and national sovereignty subline: *"سلطنة عُمان • Sultanate of Oman"*.
- Automatically verifies session persistence before routing to Onboarding or the Home Dashboard.

#### 2. Multi-Method Authentication & Registration (`login_register_screen.dart`)
- **Oman Mobile Phone OTP (Primary)**: Seamless entry with international prefix `+968`, localized carrier formatting, and 6-digit SMS OTP verification code.
- **Email & Password**: Alternative access method for charter captains and commercial operators.
- **Sign in with Apple (Apple ID)**: Fully compliant with Apple Human Interface Guidelines and App Store Review Guideline 4.8.
- **Sign in with Google**: One-tap OAuth integration.
- **Governorate Localization**: User profile creation ties each captain to their primary coastal governorate (Muscat, Dhofar, Musandam, Al Batinah South, Al Batinah North, Ash Sharqiyah South, Al Wusta).
- **Guest / Exploration Mode**: One-tap visitor access enabling users to explore live charts and sea conditions immediately.

#### 3. Educational Onboarding Carousel (`onboarding_screen.dart`)
- Editorial 3-slide walkthrough introducing Solunar indices, marine reserve boundaries, and fuel-optimized trip routing.
- Minimal hairline progress indicators and clean primary action buttons.

#### 4. Home Dashboard (`home_dashboard_screen.dart`)
- **Port Selector**: Dynamically switches between key fishing ports (Mutrah, Marina Bandar Al Rowdha, Sur, Khasab, Salalah, Duqm).
- **Daily Fishing Index (`FishingScoreGauge`)**: 80px circular gauge indicating the overall bite score (0–100) calculated by the ML engine.
- **Live Marine Stat Chips (`ConditionStatChip`)**: Instant readouts of wave height (m), swell direction, wind velocity (knots), and Sea Surface Temperature (SST in °C).
- **Ranked Hotspots List**: High-scoring spots in the local governorate with direct badges distinguishing open waters from protected reserves.

#### 5. Interactive Oman Marine Chart (`fishing_map_screen.dart`)
- Custom-styled nautical chart with muted cream landmasses (`#F4F2EC`) and soft blue-gray water (`#E5E9EC`).
- **Protected Reserve Overlays**: Marine reserves (such as the *Daymaniyat Islands*) rendered with distinct violet outlines (`#6B5B95`) and semi-transparent fills with permit notices.
- **Categorized Spot Filtering**: Instant toggling between *All Spots*, *Pelagic Runs*, *Bottom/Reef*, and *Marine Reserves*.
- **Floating Inspector Card**: Tapping any pin displays depth, distance from port, primary species, and a direct button to plan a trip.

#### 6. Hotspot Deep-Dive Details (`hotspot_details_screen.dart`)
- Detailed bathymetric specifications: exact GPS coordinates, contour depth (m), distance from nearest port (nmi), and bottom substrate type (rocky drop-off, gravel, sand).
- Real-time weather and oceanographic conditions specific to the coordinates.
- Target species tags with seasonal availability indicators.
- One-touch navigation launch to the Smart Trip Planner.

#### 7. Smart Trip Planner Wizard (`smart_trip_wizard_screen.dart`)
A streamlined 3-step route generator:
- **Step 1 — Target Species**: Calibrates optimal thermal layers (Kingfish, Yellowfin Tuna, Hamoor, Amberjack, Mahi Mahi).
- **Step 2 — Vessel & Range Selection**: Inputs hull type (Fiberglass Skiff 24–28ft, Traditional Dhow, Offshore Cruiser 32ft+) and max cruise distance (5–50 nmi).
- **Step 3 — Departure Window**: Selects launch timing (Pre-dawn 04:30, Dawn 05:00, Afternoon Slack 14:30) to align with tidal currents.

#### 8. Trip Recommendation Plan (`trip_recommendation_screen.dart`)
- Generates a minute-by-minute itinerary (Departure → Transit → Trolling Run → Jigging Window → Return cruise before afternoon winds).
- Estimates fuel consumption (Liters) based on vessel displacement and nautical distance.
- Advises on recommended tackle, trolling depth, and lure/rig setups.

#### 9. Catch Log & History (`add_catch_screen.dart` & `catch_history_screen.dart`)
- Comprehensive catch logging: species, weight (kg), length (cm), GPS coordinates, fishing gear/method (Trolling, Deep Drop Jig, Live Bait, Popper), and Catch & Release status.
- Photo attachment placeholder for catch verification.
- Personal analytics and logbook history stored in Firestore, feeding user catch data back into ML personalization models.

#### 10. Captain Profile, Compliance & Alerts (`profile_screen.dart` & `notifications_screen.dart`)
- Profile overview with boat identification and primary coastal governorate.
- Language switcher: instantaneous toggling between **English** and **Arabic (عربي)**.
- Official regulatory links to the Ministry of Agriculture, Fisheries and Water Resources regulations and Environment Authority permits.
- Push notification inbox for marine weather advisories (rough seas, shamal winds, high swell warnings).

---

## 4. Design System (v2 — Premium White Direction)

The visual design system adheres strictly to the **v2 White-First Editorial Specification**:

### 4.1 Design Philosophy
- **Quiet, Editorial, Functional**: Replaces bright, candy-colored startup gradients with an authoritative, restrained white-first design language.
- **High Sun Contrast**: Built with pure white surfaces (`#FFFFFF`) and dark neutral typography (`#1A1A1A`) to ensure legibility when operating vessels under direct glare at sea.
- **Zero Drop Shadows**: Structural separation is achieved exclusively through 1px solid hairline borders (`#E7E7E4`) and subtle background shifts (`#F7F7F5`).

### 4.2 Color Token Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        BAHHAR v2 COLOR PALETTE                         │
├───────────────────┬───────────────────┬────────────────────────────────┤
│ Token Name        │ Hex Code          │ Architectural Usage            │
├───────────────────┼───────────────────┼────────────────────────────────┤
│ surfacePure       │ #FFFFFF           │ Dominant app background & cards│
│ surfaceSubtle     │ #F7F7F5           │ Stat chips & secondary toggles │
│ borderHairline    │ #E7E7E4           │ 1px dividers, card hairlines   │
│ textPrimary       │ #1A1A1A           │ Primary headings & body text   │
│ textSecondary     │ #6B6B6B           │ Captions, metadata, subtitles  │
│ textTertiary      │ #9E9E9E           │ Placeholders, borders, accents │
│ accentNavy        │ #12263A           │ Single primary brand accent    │
│ signalGood        │ #2E7D5B           │ Favorable bite (Score >= 70)   │
│ signalCaution     │ #B8862E           │ Moderate bite (Score 40 - 69)  │
│ signalAlert       │ #B23A2E           │ Poor bite / Weather hazard     │
│ legalRestricted   │ #6B5B95           │ Marine reserves (Daymaniyat)   │
│ mapWater          │ #E5E9EC           │ Soft nautical chart ocean      │
│ mapLand           │ #F4F2EC           │ Muted editorial coastline      │
└───────────────────┴───────────────────┴────────────────────────────────┘
```

### 4.3 Typography Scale
- **Screen Title**: 22–24pt Semibold, tracking -0.3, lining figures.
- **Subhead / AppBar**: 18pt Semibold, tracking -0.2.
- **Section Header**: 11pt Bold, tracking +1.0, UPPERCASE editorial micro-label.
- **Body / Body Medium**: 15pt Regular / Medium, line height 1.45.
- **Metric Figure**: 26–32pt Bold, tabular lining numerals (`fontFeatures: [FontFeature.tabularFigures()]`).
- **Caption / Metadata**: 12pt Regular, neutral ink.

---

## 5. Backend & Machine Learning Microservice

### 5.1 Python FastAPI Engine (`backend/`)
Located in the repository at `backend/main.py`, the backend runs independently as a high-performance Python service:

1. **Prediction Endpoint (`POST /api/v1/predict`)**:
   - Accepts latitude, longitude, target species, hour, date, and live marine conditions (temperature, wave, wind).
   - Computes probability scores (0–100) using a multi-factor weighting algorithm:
     - **Thermal Affinity**: Matches current SST against species-specific temperature envelopes (e.g., Kingfish: 24–28°C; Yellowfin: 26–30°C).
     - **Bathymetric Preference**: Scores depth suitability against target species habitats.
     - **Solunar Tidal Factor**: Calculates lunar phase and tidal current velocity impact on predatory feeding behavior.
   - Generates bite window recommendations, safety advisories, and tackle strategies.

2. **Geofence Verification (`POST /api/v1/geofence/verify`)**:
   - Performs point-in-polygon verification against coordinates of Oman's marine protected areas.
   - Specifically enforces boundaries for the **Daymaniyat Islands Nature Reserve** (`[23.82°N, 58.05°E] - [23.90°N, 58.18°E]`).
   - Flags permit requirements, allowed gear, and restricted zones.

3. **System Health Endpoint (`GET /health`)**:
   - Returns uptime, service version, and status checks for monitoring.

### 5.2 Automated Backend Test Suite
The microservice includes automated unit tests (`backend/tests/test_api.py`) passing with 100% success rate:
- `test_health`: Validates API availability.
- `test_predict_kingfish_optimal`: Validates ML scoring algorithm outputs.
- `test_geofence_daymaniyat_protected`: Verifies legal geofence detection.

---

## 6. Security, Compliance & Omani Localization

1. **Environmental Law Alignment**:
   - Integrates guidelines from the Ministry of Agriculture, Fisheries and Water Resources regarding closed fishing seasons (e.g., Kingfish seasonal net bans).
   - Provides clear warnings in marine reserves to prevent accidental poaching penalties.
2. **Data Privacy & Storage Security**:
   - Cloud Firestore Security Rules (`firestore.rules`) enforce user isolation: users can only read and write their private catch records.
   - Public reference data (hotspots, species catalogs, regulatory notices) is read-only.
   - Cloud Storage Security Rules (`storage.rules`) restrict photo uploads to 10MB JPEG/PNG formats within user-authenticated directories.
3. **Bilingual Support**:
   - Built from the ground up for instantaneous switching between **Arabic (Oman)** and **English**.

---

## 7. Client Deployment & Integration Guide

### 7.1 Required Production Keys & Credentials

To transition from the current autonomous simulation mode to live production, provide the following credentials:

| Key / File | Purpose | Configuration Location |
| :--- | :--- | :--- |
| **Google Maps API Key** | Native map rendering on iOS & Android | `.env` (`GOOGLE_MAPS_API_KEY`), `android/app/src/main/AndroidManifest.xml`, `ios/Runner/AppDelegate.swift` |
| `google-services.json` | Firebase Android configuration | Place in `android/app/google-services.json` |
| `GoogleService-Info.plist` | Firebase iOS configuration | Place in `ios/Runner/GoogleService-Info.plist` |
| `WORLDTIDES_API_KEY` *(Optional)* | High-precision tidal predictions | Set in backend `.env` |
| `ML_API_BASE_URL` | Deployed URL of FastAPI backend | Set in mobile `.env` (defaults to local/cloud instance) |

### 7.2 Running the Application Locally

#### Flutter Mobile Client:
```bash
# Clone the repository
git clone https://github.com/Sonalhegde/BAHHAR.git
cd BAHHAR

# Install dependencies
flutter pub get

# Run on connected device or simulator
flutter run
```

#### Python ML Microservice:
```bash
cd backend

# Install Python dependencies
pip install -r requirements.txt

# Run automated tests
pytest tests/ -v

# Start FastAPI server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 8. Summary of Completed Deliverables

- [x] **Private Git Repository**: Initialized, tracked, and pushed at `https://github.com/Sonalhegde/BAHHAR`.
- [x] **v2 Premium White Re-theming**: Applied across all 10 screens and all shared widgets.
- [x] **Introductory Brand Seal & Splash Flow**: Animated splash with authentic Bahhar calligraphy.
- [x] **Multi-Method Login Screen**: Phone OTP (+968), Email/Password, Sign in with Apple, Google, and Guest mode.
- [x] **Cartography & Geofencing**: Custom nautical styling with Daymaniyat reserve crosshatch overlay.
- [x] **FastAPI ML Microservice**: Fully operational with 100% test coverage.
- [x] **Security & Storage Rules**: Enterprise `firestore.rules` and `storage.rules`.
- [x] **Interactive Web Simulator**: Standalone HTML prototype for client inspection (`bahhar_interactive_simulator.html`).
