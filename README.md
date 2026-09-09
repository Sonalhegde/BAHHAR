# BAHHAR (بَحّار)
> **Your trusted companion at sea — رفيقك الموثوق في البحر**

BAHHAR is a smart marine companion built specifically for fishermen, boat operators, and marine enthusiasts in the Sultanate of Oman. Designed from the ground up for daylight legibility, sea safety, and reliable operations, BAHHAR combines real-time marine weather, hydrographic data, protected reserve geofencing, and complete vessel/licence management into a clean, human-designed mobile application.

---

## Key Highlights

- **Marine-Tech Design System**: Clean white and royal blue (`#0066CC` + `#0F2644`) interface with subtle soft-depth polymorphic surfaces and daylight-optimized high-contrast typography.
- **Complete Arabic & English (Bilingual & RTL)**: Instant runtime language switching without restarting the app. Full `Directionality` mirroring, Arabic-Indic numerals (`٠١٢٣٤٥٦٧٨٩`), and localized date/unit formatting via `AppTranslations` and `LocaleUtils`.
- **Real Fisherman Profile Ecosystem**: Structured identity management with masked Civil IDs (`••••••1234`), multi-licence management, vessel specifications, crew records, gear permits, and document expiration alerts.
- **Safety Center & Pre-Departure Checklist**: 10-point critical pre-departure verification (life jackets, fuel calculation, communications, flares, float plans) with status indicators and emergency contact integration.
- **Granular Location Privacy**: 3-mode location tracking control (`Off`, `On for Map`, `On for Active Trip`) with persistent live indicator and explicit privacy disclosures.
- **Oman Marine Regulations & Reference**: Geo-fenced alerts for marine reserves (e.g., Daymaniyat Islands) pursuant to Royal Decree 23/96 and Ministerial Decision 12/2008, plus official reference guides from the Ministry of Agriculture, Fisheries and Water Resources (MAFWR).
- **Offline Resilience**: Essential profile data, emergency contacts, document metadata, and safety checklists remain available offline when out of mobile range.

---

## System Architecture

```text
┌──────────────────────────────────────────────────────────────────┐
│                   BAHHAR Mobile Application                      │
│                            (Flutter)                             │
├──────────────┬──────────────┬──────────────┬─────────────────────┤
│   Command    │    Chart     │     Trip     │  Logbook & Profile  │
│  (Dashboard) │ (Marine Map) │  (Voyage)    │ (Licences & Safety) │
└──────┬───────┴──────┬───────┴──────┬───────┴──────────┬──────────┘
       │              │              │                  │
       ▼              ▼              ▼                  ▼
┌──────────────────────────────────────────────────────────────────┐
│             Riverpod 2.x State Management Layer                  │
│  • isArabicProvider (RTL toggle) • preferencesProvider           │
│  • fishermanProfileProvider      • licencesProvider              │
│  • vesselsProvider               • crewProvider                  │
│  • documentsProvider             • safetyChecklistProvider       │
│  • locationTrackingProvider      • reportIssuesProvider          │
└────────────────┬───────────────────────────────┬─────────────────┘
                 │                               │
                 ▼                               ▼
┌────────────────────────────────┐ ┌───────────────────────────────┐
│     Firebase Cloud Backend     │ │   FastAPI Marine ML Engine    │
│ • Firebase Auth (OTP/Social)   │ │ • Strike Probability Models   │
│ • Cloud Firestore Documents    │ │ • Geofencing & Decrees Engine │
│ • Cloud Storage (Scans/Photos) │ │ • Open-Meteo & Marine Proxy   │
│ • App Check & Push Alerts      │ │ • Fuel & Route Estimation     │
└────────────────────────────────┘ └───────────────────────────────┘
```

---

## Core Application Screens

### 1. Command (Home Dashboard)
- **Live Conditions Strip**: Real-time wave height, wind speed, and sea water temperature.
- **Fishing Score Gauge**: Daylight-legible radial gauge scoring overall fishing conditions.
- **Nearby Hotspots Carousel**: Ranked fishing spots with distance, depth, and target species.
- **Live Location Banner**: Persistent status indicator showing active location tracking status.

### 2. Chart (Interactive Marine Map)
- Full-screen nautical chart with depth contours and bathymetric layers.
- Color-coded pins for fishing hotspots (blue) and protected marine reserves (red).
- Geofence alerts warning fishermen when nearing restricted waters (e.g., Daymaniyat Islands).

### 3. Trip Planner & Smart Wizard
- Step-by-step voyage planning: Target Species → Departure Port → Date/Time → Vessel Selection → Fuel Budget.
- Fuel consumption calculation (liters and OMR cost) based on engine horsepower and cruising distance.

### 4. Logbook (Catch History)
- Detailed catch logger: Species selection, weight (`kg`/`lb`), length (`cm`/`ft`), catch coordinates, bait/gear notes, and photo uploads.
- Historical statistics: Total catches, trips logged, and top species breakdown.

### 5. Fisherman Profile & Identity System
- **Personal Information**: Full Name (EN/AR), masked Civil ID (`••••••1234`) with secure reveal toggle, phone numbers, governorate/wilayat, and emergency contact details.
- **Profile Completion Score**: Automated tracking (Required, Recommended, Optional) with visual completion bar.
- **Fishing Licences**: Multi-licence management (Artisanal, Commercial, Recreational) with color-coded status badges (`Valid`, `Expiring Soon`, `Expired`, `Pending`) and countdown warnings.
- **My Boats (Vessels)**: Vessel profiles with registration numbers, vessel type (Traditional Dhow, Motorboat), length, engine horsepower, capacity, and navigation licence expiry dates.
- **Crew Management**: Roster of crew members with assigned roles (Captain, Deckhand), Civil IDs, fishing licences, and individual emergency contacts.
- **Fishing Gear & Permits**: Independent tracking for specific equipment and gear permits.
- **Documents Wallet**: Centralized vault for scanned licences, boat registrations, and insurance papers with proactive expiration notifications (30, 14, 7, and 1 day prior).
- **Safety Center**: Pre-Departure Safety Checklist featuring 10 vital marine checks, completion progress, and quick-reset capabilities.
- **Settings & Privacy**: Seamless language switcher, unit converter (Metric vs. Imperial), fine-grained notification toggles, and 3-stage location privacy control.
- **Help & Instructions**: Step-by-step interactive walkthroughs for all core app features, navigation tips, and offline usage guides.
- **Report an Issue**: Built-in ticket submission with category filters, detailed notes, and traceable reference IDs (e.g., `BHR-2026-1001`).
- **Official Oman Fishing Information**: Verified reference section covering fishing seasons, prohibited gear, protected zones, and emergency hotlines (MRCC Oman `+968 2473 0066`, Coast Guard `9999`, MAFWR Hotline `80077400`).

---

## Tech Stack

| Component | Technologies |
| :--- | :--- |
| **Mobile App** | Flutter 3.24+, Dart 3.5+, Riverpod 2.5+, GoRouter 14.2+ |
| **Localization** | Custom `AppTranslations` dictionary, `LocaleUtils`, `flutter_localizations`, RTL layout engine |
| **Design & UI** | Custom Canvas Painters (`_BahharSailWavePainter`, `_CoastalHeadlandsPainter`), Soft Buttons, Glass Tokens |
| **Maps & GIS** | `google_maps_flutter`, Geo-coordinate boundary validation, Marine bathymetry layers |
| **Cloud Services** | Firebase Auth (Phone OTP, Email, Apple, Google), Firestore, Cloud Storage, FCM |
| **Backend API** | Python 3.11+, FastAPI, Pydantic, Scikit-learn, XGBoost, Uvicorn |
| **Testing** | Flutter Test framework, Pytest (Backend API test suite) |

---

## Getting Started

### Prerequisites
- **Flutter SDK**: `>= 3.24.0` (with Dart `>= 3.5.0`)
- **Python**: `>= 3.11` (for backend microservice)
- **Git**

### 1. Flutter Mobile Setup
```bash
# Clone the repository
git clone https://github.com/Sonalhegde/BAHHAR.git
cd BAHHAR

# Fetch Flutter dependencies
flutter pub get

# Launch the app on a connected device or simulator
flutter run
```

### 2. Backend Microservice Setup
```bash
cd backend

# Create and activate a virtual environment
python -m venv venv
# On Windows:
.\venv\Scripts\activate
# On Linux/macOS:
source venv/bin/activate

# Install requirements
pip install -r requirements.txt

# Run backend unit tests
python -m pytest tests/ -v

# Start the FastAPI development server
uvicorn main:app --reload --port 8000
```

The interactive API documentation will be available at `http://localhost:8000/docs`.

### 3. Running Backend in Docker
```bash
cd backend
docker build -t bahhar-backend .
docker run -p 8000:8000 bahhar-backend
```

---

## Verification & Test Status

- **Backend Pytest Suite**: 3/3 Tests Passing (`test_health`, `test_predict_kingfish_optimal`, `test_geofence_daymaniyat_protected`).
- **Data Models**: Fully tested JSON serialization, null-safety, and validation across all fisherman, licence, vessel, crew, document, and safety models.
- **Localization**: Validated across English and Arabic layouts with bidirectional text support.

---

## License

Copyright © 2026 BAHHAR. All rights reserved.
