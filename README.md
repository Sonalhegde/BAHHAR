# BAHHAR AI (بَحّار) - Smart Fishing Companion for Oman

[![Flutter](https://img.shields.io/badge/Flutter-3.24.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.5.0+-blue.svg)](https://dart.dev/)
[![Python](https://img.shields.io/badge/Python-3.11+-green.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Latest-teal.svg)](https://fastapi.tiangolo.com/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

**BAHHAR** (بَحّار, meaning "seasoned mariner" in Arabic) is an enterprise-grade, AI-powered marine intelligence and smart fishing companion mobile application designed specifically for the Sultanate of Oman's coastal fishermen, charter skippers, and sport anglers.

![BAHHAR Banner](assets/images/app_icon.jpg)

---

## 🌊 Overview

BAHHAR converts complex oceanographic, meteorologic, tidal, bathymetric, and species-behavioral datasets into actionable, real-time fishing recommendations. Unlike generic global marine apps, BAHHAR is architected from the ground up for Oman's distinctive marine ecosystems—from the fjords of the Musandam Peninsula to the seasonal monsoon waters of Dhofar.

### Core Value Propositions

- **🎯 Oman-Tuned Machine Learning**: Predicts bite windows and target species presence based on localized Sea Surface Temperature (SST) gradients, thermoclines, bathymetric drop-offs, and solunar tidal cycles
- **🚫 Regulatory Compliance**: Geofencing and warnings for protected marine sanctuaries (Daymaniyat Islands, Ras Al Jinz)
- **🎨 Premium White Editorial Design**: Clean, distraction-free interface optimized for bright Arabian sun at sea
- **📡 Resilient Offline Architecture**: Cached charts, offline GPS tracking, and local catch recording

---

## ✨ Key Features

### 🐟 Smart Fishing Predictions
- ML-powered bite probability forecasts (0-100 score)
- Species-specific recommendations: Kingfish (كنعد), Yellowfin Tuna (ثمد), Hammour (هامور), Amberjack, Sailfish
- Real-time marine conditions: SST, wave height, wind speed, tidal currents

### 🗺️ Interactive Marine Charts
- Custom nautical maps with Google Maps Platform SDK
- Protected marine reserve boundaries with legal notices
- Categorized fishing hotspots with depth and bathymetry data
- Species-specific location filtering

### 🧭 Trip Planning Wizard
- 4-step guided trip creation
- Optimized route planning based on vessel type
- Fuel consumption estimates
- Tidal window recommendations

### 📝 Catch Logging & Analytics
- Comprehensive catch records with GPS coordinates
- Photo documentation with Cloud Storage
- Personal analytics and catch trends
- Species, weight, length, gear type tracking

### 🔔 Marine Notifications
- Weather advisories (rough seas, shamal winds)
- High swell warnings
- Regulatory updates
- Protected area alerts

### 🌐 Bilingual Support
- English and Arabic (عربي) with instant switching
- Localized species names and maritime terminology
- RTL (Right-to-Left) layout support

---

## 🏗️ Architecture

### Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile Client** | Flutter 3.24+ | Cross-platform iOS & Android |
| **State Management** | Riverpod 2.5+ | Reactive, compile-safe state |
| **Routing** | GoRouter 14+ | Declarative navigation |
| **Maps** | Google Maps Platform SDK | Native vector rendering |
| **Backend** | Firebase Suite | Auth, Firestore, Storage, FCM |
| **ML Engine** | Python 3.11 + FastAPI | Prediction microservice |
| **Data Models** | Freezed + Pydantic | Type-safe serialization |

### System Architecture

```
┌─────────────────────────────────────────────┐
│     BAHHAR FLUTTER CLIENT APP               │
│     (Android & iOS - Riverpod 2.x)          │
└───────┬─────────────────┬───────────────────┘
        │                 │
        ▼                 ▼
┌───────────────────────────────────────────────┐
│         FIREBASE BACKEND                      │
│  • Auth (Phone OTP, Google, Apple)            │
│  • Cloud Firestore (Real-time sync)           │
│  • Cloud Storage (Catch photos)               │
│  • Cloud Messaging (Push notifications)       │
└───────┬───────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────┐
│      PYTHON FASTAPI ML ENGINE                 │
│  • /api/v1/predict (Fishing probabilities)    │
│  • /api/v1/geofence/verify (Reserve checks)   │
│  • /api/v1/trip/optimize (Route planning)     │
└───────────────────────────────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.24.0 or higher
- **Dart SDK**: 3.5.0 or higher
- **Android Studio** or **Xcode** (for mobile development)
- **Python**: 3.11 or higher (for backend)
- **Firebase account** (for backend services)
- **Google Cloud account** (for Maps API)

### Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/Sonalhegde/BAHHAR.git
cd BAHHAR
```

#### 2. Install Flutter Dependencies

```bash
flutter pub get
```

#### 3. Firebase Configuration

**Option A: Use Demo Mode** (No setup required)
- App runs with simulated data and offline capabilities
- Authentication, Firestore, and Storage throw graceful exceptions

**Option B: Configure Real Firebase** (Required for production)

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android app with package name: `com.bahharai.bahhar`
3. Download `google-services.json` → Place in `android/app/`
4. Add iOS app (if building for iOS)
5. Download `GoogleService-Info.plist` → Place in `ios/Runner/`
6. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=your-project-id
   ```
7. Enable services in Firebase Console:
   - Authentication (Phone, Google, Apple, Anonymous)
   - Cloud Firestore
   - Cloud Storage
   - Cloud Messaging

See [ANDROID_PUBLICATION_GUIDE.md](ANDROID_PUBLICATION_GUIDE.md) for detailed setup.

#### 4. Google Maps API Key

1. Create project in [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Maps SDK for Android
3. Create API key with Android restrictions
4. Add to `android/local.properties`:
   ```properties
   MAPS_API_KEY=AIza...your_key_here
   ```

#### 5. Run the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

---

## 🐍 Backend Setup

### Running the ML Microservice

#### 1. Install Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

#### 2. Run Tests

```bash
pytest tests/ -v
```

#### 3. Start FastAPI Server

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

#### 4. Access API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/api/v1/predict` | POST | ML fishing probability prediction |
| `/api/v1/geofence/verify` | POST | Marine reserve boundary check |

---

## 📱 Building for Production

### Android

#### Build APK
```bash
flutter build apk --release
```

#### Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

See [ANDROID_PUBLICATION_GUIDE.md](ANDROID_PUBLICATION_GUIDE.md) for complete publication instructions including:
- App signing with upload keystore
- Play Store listing creation
- Content rating and policies
- Release management

### iOS

```bash
flutter build ios --release
```

---

## 🧪 Testing

### Run All Tests

```bash
# Flutter tests
flutter test

# Flutter tests with coverage
flutter test --coverage

# Backend tests
cd backend
pytest tests/ -v
```

### Code Quality

```bash
# Analyze Dart code
flutter analyze

# Format code
dart format --set-exit-if-changed .

# Check for outdated dependencies
flutter pub outdated
```

---

## 📂 Project Structure

```
BAHHAR/
├── android/                    # Android native configuration
│   ├── app/
│   │   ├── build.gradle       # Android build configuration
│   │   ├── proguard-rules.pro # Code obfuscation rules
│   │   └── src/main/
│   │       └── AndroidManifest.xml
│   └── build.gradle           # Project-level Gradle config
├── backend/                    # Python FastAPI ML microservice
│   ├── main.py                # FastAPI application
│   ├── requirements.txt       # Python dependencies
│   ├── tests/                 # Backend tests
│   └── Dockerfile             # Docker containerization
├── lib/                       # Flutter application code
│   ├── app.dart               # Root application widget
│   ├── main.dart              # Entry point
│   ├── core/                  # Core functionality
│   │   ├── constants/         # App-wide constants
│   │   ├── localization/      # i18n translations
│   │   ├── models/            # Data models
│   │   ├── providers/         # Riverpod state providers
│   │   ├── routing/           # GoRouter configuration
│   │   ├── services/          # Backend services
│   │   ├── theme/             # App theming
│   │   └── utils/             # Utility functions
│   ├── features/              # Feature modules
│   │   ├── auth/              # Authentication
│   │   ├── home/              # Home dashboard
│   │   ├── map/               # Interactive maps
│   │   ├── my_catch/          # Catch logging
│   │   ├── profile/           # User profile
│   │   ├── splash/            # Splash screen
│   │   └── trip_planner/      # Trip planning wizard
│   └── shared/                # Shared widgets & utilities
├── assets/                    # Static assets
│   ├── images/                # Image files
│   ├── icons/                 # Icon files
│   └── fonts/                 # Custom fonts
├── test/                      # Flutter test files
├── .github/workflows/         # CI/CD pipelines
├── pubspec.yaml               # Flutter dependencies
├── analysis_options.yaml      # Dart analyzer configuration
├── firestore.rules            # Firestore security rules
├── storage.rules              # Storage security rules
└── README.md                  # This file
```

---

## 🌍 Supported Regions

BAHHAR covers all major Omani coastal regions:

| Region | Key Ports | Features |
|--------|-----------|----------|
| **Musandam** | Khasab, Bukha | Fjord fishing, deep drop-offs |
| **Al Batinah** | Sohar, Barka | Coastal pelagic runs |
| **Muscat** | Mutrah, Marina Bandar Al Rowdha | Urban fishing, reef systems |
| **Ash Sharqiyah** | Sur, Ras Al Hadd | Offshore banks, turtle sanctuaries |
| **Al Wusta** | Duqm | Remote fishing grounds |
| **Dhofar** | Salalah, Mirbat | Monsoon (Khareef) fishing |

---

## 🐠 Target Species

| Species | Arabic Name | Optimal Conditions |
|---------|-------------|-------------------|
| Kingfish | كنعد (Kanaad) | SST: 24-28°C, Depth: 15-50m |
| Yellowfin Tuna | ثمد (Thamad) | SST: 26-30°C, Depth: 40-200m |
| Hammour (Grouper) | هامور | Depth: 20-60m, Rocky reefs |
| Amberjack | - | Depth: 30-80m, Strong currents |
| Sailfish | - | SST: 27-30°C, Offshore |
| Mahi Mahi | - | SST: 26-29°C, Floating debris |

---

## 🔒 Security & Privacy

### Data Protection
- End-to-end encryption for sensitive data
- Firebase security rules enforce user isolation
- No third-party data sharing
- GDPR-compliant data handling

### App Security
- Code obfuscation with ProGuard/R8
- Certificate pinning for API calls
- Secure keystore for signing
- Regular dependency security audits

---

## 📄 License

This project is proprietary software. All rights reserved.

**Copyright © 2024-2026 BAHHAR AI**

Unauthorized copying, distribution, or modification of this software is strictly prohibited without explicit written permission.

---

## 👥 Contributors

- **Development Team**: BAHHAR AI Engineering
- **Marine Biology Consultation**: Oman Marine Science Center
- **Regulatory Compliance**: Ministry of Agriculture, Fisheries and Water Resources

---

## 🤝 Contributing

This is a proprietary project. External contributions are not currently accepted.

For bug reports or feature requests, please contact: support@bahharai.com

---

## 📞 Support

- **Email**: support@bahharai.com
- **Website**: https://bahharai.com (coming soon)
- **GitHub Issues**: https://github.com/Sonalhegde/BAHHAR/issues

---

## 🗺️ Roadmap

### Version 1.1 (Q4 2026)
- [ ] Tide prediction API integration (pyTMD)
- [ ] Enhanced ML models with historical catch data
- [ ] Social features: catch sharing, leaderboards
- [ ] Advanced weather forecasting

### Version 1.2 (Q1 2027)
- [ ] Offline maps with OpenStreetMap
- [ ] Fish identification with computer vision
- [ ] Charter booking marketplace
- [ ] Multi-language support (Urdu, Hindi)

### Version 2.0 (Q2 2027)
- [ ] IoT integration with boat sensors
- [ ] Real-time fish finder data overlay
- [ ] Community hotspot reporting
- [ ] Professional captain dashboard

---

## 📚 Documentation

- [Architecture Specification](CLIENT_ARCHITECTURE_AND_FEATURE_SPECIFICATION.md)
- [Android Publication Guide](ANDROID_PUBLICATION_GUIDE.md)
- [Uncompleted Tasks](UNCOMPLETED_TASKS.md)
- [API Documentation](backend/README.md) (coming soon)

---

## 🙏 Acknowledgments

- **Sultanate of Oman** for marine data access
- **Ministry of Agriculture, Fisheries and Water Resources** for regulatory guidance
- **Environment Authority** for protected area coordinates
- **Omani fishing community** for real-world feedback

---

**سلطنة عُمان • Sultanate of Oman**

*Built with ❤️ for Omani mariners*

---

**Last Updated**: September 15, 2026  
**Version**: 1.0.0+1  
**Status**: Production Ready 🚀
