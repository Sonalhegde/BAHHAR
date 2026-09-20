# BAHHAR AI (بَحّار)

**Smart fishing & marine-intelligence companion for the Sultanate of Oman.**

[![Flutter](https://img.shields.io/badge/Flutter-3.29%2B-blue.svg)](https://flutter.dev/)
[![Python](https://img.shields.io/badge/FastAPI-3.11%2B-green.svg)](https://fastapi.tiangolo.com/)
[![Backend tests](https://img.shields.io/badge/backend%20tests-32%20passing-brightgreen.svg)](backend/tests/test_api.py)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

BAHHAR (بَحّار, "seasoned mariner") converts live oceanographic, meteorologic, tidal and
species-behavioural data into actionable fishing forecasts built specifically for Omani waters —
from the Musandam fjords to the Dhofar monsoon coast.

![BAHHAR](assets/images/app_icon.jpg)

> 📐 **Full specification:** architecture, 10-screen feature list, design system, backend/API,
> live marine integration, security rules, status & roadmap are consolidated in
> **[SPECIFICATION.md](SPECIFICATION.md)**. This README is the entry point only.

---

## 🌐 Live deployment

**Status: live on Vercel —** [https://bahhar-blue.vercel.app](https://bahhar-blue.vercel.app)
(verified: landing page, embedded Leaflet chart, hero and photo-band imagery all loading). The
marketing site lives in the [`website/`](website) folder (`landing-page.html`, with `index.html`
redirecting to it, plus `privacy.html`, `terms.html` and `map-mockup.html`). The bare
`bahhar.vercel.app` subdomain is claimed by a different Vercel project, so this project's
production alias is `bahhar-blue.vercel.app`; rename or retarget it under
**Project → Settings → Domains**.

| Target | How to serve | State |
| :-- | :-- | :-- |
| Vercel (primary) | `website/vercel.json` (root directory `website/`) rewrites `/*` → `/landing-page.html` and sets security headers; `.vercelignore` uploads only `website/` | Deployed — <https://bahhar-blue.vercel.app> |
| GitHub Pages | Set Pages source to `/website` → `https://sonalhegde.github.io/BAHHAR/` | Ready — needs Pages enabled on `main` |

Hosting walkthrough: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

---

## ✨ Features

### ✅ Implemented
- **10 screens in working demo mode** — Splash, Auth, Onboarding, Home, Marine Chart, Hotspot
  Details, Smart Trip wizard, Trip Recommendation, Catch Log/History, Profile (+ 11 sub-screens) & Notifications.
- **Live marine, tide & weather data** — `GET /api/v1/marine/conditions` aggregates Open-Meteo
  (SST, wave height/period/**direction**, **current speed + set**, **visibility**, wind, pressure,
  UV) + WorldTides, and bands the day into five sea-state levels; `GET /api/v1/weather` returns
  current conditions, 8 hours and 5 days. Server-side TTL cache; Flutter shows a "last known
  conditions" banner when offline/stale and names the provider that answered. **No API key is
  needed for any of it** — both run on keyless Open-Meteo by default.
- **Trip optimiser** — `POST /api/v1/trip/optimize` ranks the planner's candidate spots against
  the live water and returns its rule, its weights and its reasons. Rule-based, not a trained
  model, and the response says so; the app falls back to its on-device heuristic when the
  backend is unreachable *or had no water to rank against*.
- **Persisted profile & preferences** — `fisherman_profiles/{uid}` read on sign-in and written on
  every mutation, language/port/units in `shared_preferences`, guest catches queued and flushed on
  sign-in, FCM handlers behind a Firebase-configured guard.
- **ML prediction** — `POST /api/v1/predict` bite-probability (thermal + bathymetric + solunar).
- **Geofencing** — `POST /api/v1/geofence/verify` for Daymaniyat, Ras Al Jinz, Hormuz corridor.
- **Bilingual EN ⇄ AR** with RTL; **Premium White editorial** design system.
- **Security rules** — per-user Firestore isolation + read-only reference collections; storage
  upload limits. **Backend test suite: 32 passing.**
- **CI** — `backend_ci.yml` (pytest) and `flutter_ci.yml` (format, analyze, test).

### ⏳ Planned / blocked
- **Blocked on external credentials:** Firebase project wiring, Copernicus Marine account, release
  keystore + Play Store listing, iOS runner. (Maps are keyless via MapLibre/OpenFreeMap — no API
  key needed.)
- **Deferred in code:** Firestore geohash queries (client-side filtered — 12 seed hotspots do not
  justify it yet), catch-photo background-isolate compression beyond `image_picker`'s 1600px/q82,
  launcher-icon generation (configured, but needs the SDK and the platform icon trees), the
  extracted placeholder widgets, and a trained trip model.

Full status matrix & roadmap: [SPECIFICATION.md §9](SPECIFICATION.md).

---

## 🧱 Tech stack

Flutter 3.29+/Dart 3.7+ · Riverpod 2.x · GoRouter 14.x · **MapLibre GL + OpenFreeMap (keyless
vector tiles — no Google Maps SDK, no API key)** · Firebase
(Auth/Firestore/Storage/FCM/App Check) · `http` client + hand-written JSON models · Python 3.11+
/ FastAPI / Uvicorn / Docker · static HTML/CSS/JS + GSAP website.
(Verified against `pubspec.yaml` and `backend/requirements.txt`.)

---

## 🚀 Setup

### Prerequisites
Flutter 3.29+ / Dart 3.7+ (stable), Python 3.11+, and (for production) Firebase + Google Cloud accounts.

### Flutter client
```bash
git clone https://github.com/Sonalhegde/BAHHAR.git
cd BAHHAR
flutter pub get
flutter run                       # demo mode, no Firebase needed
# point at a non-local backend:
flutter run --dart-define=ML_API_BASE_URL=http://<host>:8000
```

### Backend engine
```bash
cd backend
pip install -r requirements.txt
cp ../.env.example .env          # then set WORLDTIDES_API_KEY (optional: ACCUWEATHER_API_KEY)
pytest tests/ -v                 # offline: every upstream call is monkeypatched
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
Swagger: http://localhost:8000/docs

Detailed environment/IDE setup: [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md).

---

## 🔑 Environment variables

Copy `.env.example` → `.env` (root) and `backend/.env`. All are gitignored — **never commit real
values**.

| Variable | Where | Purpose |
| :-- | :-- | :-- |
| `WORLDTIDES_API_KEY` | `backend/.env` | Tide proxy — **backend only**, never in the app |
| `ACCUWEATHER_API_KEY` | `backend/.env` | Weather proxy — **backend only**, and **optional**: unset, `GET /api/v1/weather` serves live Open-Meteo on the same contract; set, AccuWeather takes over and the payload names whichever answered |
| `ACCUWEATHER_DAILY_CALL_BUDGET` | `backend/.env` | Optional cap on provider calls per day (free tier is a *daily* ceiling; 0 = no cap) |
| `ML_API_BASE_URL` | app `.env` / `--dart-define` | Deployed FastAPI base URL |
| `ML_API_TOKEN` | app `.env` | Service-to-service auth (v3 name) |
| `COPERNICUS_MARINE_USERNAME` / `COPERNICUS_MARINE_PASSWORD` | `backend/.env` | Phase-5 data — not yet provisioned |
| `FIREBASE_PROJECT_ID` / `FIREBASE_STORAGE_BUCKET` | app `.env` | Firebase wiring |

Maps are keyless (MapLibre + OpenFreeMap) — the former `GOOGLE_MAPS_API_KEY` was removed with the
Google Maps dependency.

Also supplied out-of-band (gitignored): `android/app/google-services.json`,
`ios/Runner/GoogleService-Info.plist`, `android/key.properties`.

---

## 📂 Project structure

```
BAHHAR/
├── android/ · ios/         # Native shells (build/sign config)
├── backend/                # FastAPI ML + marine engine (main.py, tests/, Dockerfile)
├── lib/
│   ├── core/               # constants, models, providers, services, theme, utils
│   ├── features/           # auth, home, map, hotspot, trip_planner, my_catch, profile, ...
│   ├── l10n/               # EN/AR localisations
│   └── shared/             # Reusable widgets
├── assets/                 # Flutter app images, icons, fonts
├── website/                # Marketing site: landing-page.html, index.html, privacy.html, terms.html, assets/images
├── test/                   # Flutter tests
├── .github/workflows/      # backend_ci.yml, flutter_ci.yml
├── website/vercel.json · .vercelignore · firestore.rules · storage.rules
└── SPECIFICATION.md        # ← unified master specification
```

---

## 🧪 Testing

```bash
# Backend (offline — upstreams are monkeypatched)
cd backend && pytest tests/ -v            # 32 passing

# Flutter
flutter test
flutter test --coverage
dart format --output=none --set-exit-if-changed .
flutter analyze
```
QA findings, the full test matrix and deferred items are recorded in
**[QA_REPORT.md](QA_REPORT.md)**.

---

## 📄 License & contributing

Proprietary — all rights reserved. © 2024–2026 BAHHAR AI. See [LICENSE](LICENSE). External
contributions are not currently accepted; contact **support@bahharai.com** or open a
[GitHub Issue](https://github.com/Sonalhegde/BAHHAR/issues).

---

## 📚 Related docs
- [SPECIFICATION.md](SPECIFICATION.md) — unified master spec
- [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) · [ANDROID_PUBLICATION_GUIDE.md](ANDROID_PUBLICATION_GUIDE.md)
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) · [CHANGELOG.md](CHANGELOG.md) · [QA_REPORT.md](QA_REPORT.md)

**سلطنة عُمان • Sultanate of Oman**
