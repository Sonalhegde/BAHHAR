# BAHHAR AI (?????) ????
> **Oman-Specific Smart Fishing Companion & Marine Intelligence Platform**

Bahhar AI converts real-time marine, weather, tide, bathymetric, and regulatory data into **actionable, species-specific fishing recommendations** across the Sultanate of Oman.

---

## ?? System Architecture

```text
??????????????????????????????????????????????????????????
?               BAHHAR AI Mobile (Flutter)               ?
?  Home ? Interactive Map ? Smart Trip ? Catch ? Profile ?
??????????????????????????????????????????????????????????
                            ?
              ?????????????????????????????
              ?                           ?
?????????????????????????????   ??????????????????????????????
?      Firebase Suite       ?   ? Python / FastAPI ML Engine ?
?  ? Auth (Phone OTP/Social)?   ?  ? Strike Probability (ML) ?
?  ? Cloud Firestore        ?   ?  ? Geofencing & Decrees    ?
?  ? Cloud Storage          ?   ?  ? Fuel & Route Optimizer  ?
?  ? App Check & FCM Alerts ?   ?  ? Open-Meteo Proxy/Cache  ?
?????????????????????????????   ??????????????????????????????
```

---

## ?? Tech Stack
- **Mobile Frontend**: Flutter (Android + iOS), State: `flutter_riverpod`, Navigation: `go_router`
- **Design System**: 10-screen wireframe, custom vector brand mark (Omani Dhow sail + wave), Dawn/Dusk Night Mode
- **Backend & Cloud**: Firebase (Auth, Firestore, Storage, Cloud Messaging, App Check)
- **Maps & Geospatial**: Google Maps Platform + Custom Omani Marine Bathymetry Layer
- **Machine Learning**: Python 3.11, FastAPI, Scikit-learn, XGBoost, Uvicorn
- **Security & Regulations**: Declarative Firestore & Storage security rules, Royal Decree 23/96 & MD 12/2008 geofencing checks

---

## ?? Mobile App Overview (10 Screens)

1. **Splash Screen**: Animated Dhow sail + wave brand mark on `#0B3D5C` Deep Sea background.
2. **Onboarding**: 3-slide introduction to fishing probability, legal zoning, and trip planning.
3. **Auth (Sign In / Sign Up)**: Tabbed authentication supporting Email/Phone, Google, Apple, and home coastal region selector.
4. **Home Dashboard**: Live conditions strip (Wind, Wave, Sea Temp, Tide), Fishing Opportunity Gauge (`FishingScoreGauge`), best bite window, and ranked nearby hotspots carousel.
5. **Interactive Fishing Map**: Full-screen chart with depth contours, species filter chips, and layer toggles (Probability Heatmap vs. Protected Marine Reserves).
6. **Hotspot Details**: Marine parameters, species presence, bathymetry, legal notices, and "Plan Smart Trip" CTA.
7. **Smart Trip Wizard**: 6-step `TripStepper` (Species ? Departure Port ? Date/Time ? Duration ? Boat Profile ? Max Fuel Budget).
8. **Trip Recommendations**: Top destinations ranked by strike probability within budget, fuel liters, and OMR cost calculation.
9. **My Catch (Log & History)**: Header statistics tiles (Total Catches, Trips Logged, Top Species) + catch form with photo, GPS, and bait notes.
10. **Profile & Settings**: Unit switcher (Metric/Imperial), Dawn/Dusk Night Mode switch (`#071824`), notification switches, and sign out.

---

## ?? Getting Started

### 1. Flutter Mobile App
```bash
# Ensure dependencies are installed
flutter pub get

# Run on connected Android device or iOS Simulator
flutter run

# Run automated tests
flutter test
```

### 2. Python / FastAPI ML Microservice
```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Run unit tests
pytest -v tests/

# Launch development server (accessible at http://localhost:8000)
uvicorn main:app --reload --port 8000
```

### 3. Docker Container Deployment
```bash
cd backend
docker build -t bahhar-ml-service .
docker run -p 8000:8000 bahhar-ml-service
```

### 4. Firestore Database Seeding
To initialize Omani coastal regions, fish species, and marine hotspot reference data:
```bash
# Dry run verification
python backend/seed_firestore.py

# Live import to Firebase (requires service account key)
python backend/seed_firestore.py path/to/serviceAccountKey.json
```

---

## ?? Security & Environment
Never commit production credentials. Copy `.env.example` to `.env` and fill in your keys:
- `GOOGLE_MAPS_API_KEY`: Restricted by Android package `com.bahharai.bahhar`
- `WORLDTIDES_API_KEY`: Proxied securely via backend
- `FIREBASE_PROJECT_ID`: Cloud Firestore project ID

---

## ?? License
Copyright (c) 2026 BAHHAR AI. All rights reserved.
