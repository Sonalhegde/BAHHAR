# BAHHAR AI (بَحّار) — Unified Master Specification

> **This is the single canonical specification for the BAHHAR project.** It consolidates the
> previously separate specification documents — `CLIENT_ARCHITECTURE_AND_FEATURE_SPECIFICATION.md`,
> `APP_DEMO_WALKTHROUGH.md`, `UNCOMPLETED_TASKS.md`, and `PRODUCTION_RELEASE_SUMMARY.md` — into one
> de-duplicated master. Step-by-step *how-to* guides (rather than *what-to-build* specs) are kept
> as linked references and are not duplicated here:
> [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md), [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md),
> [ANDROID_PUBLICATION_GUIDE.md](ANDROID_PUBLICATION_GUIDE.md), and [CHANGELOG.md](CHANGELOG.md).
> The repository entry point is [README.md](README.md).

**Version:** 3.0 (Live Marine Data + Landing Redesign)
**Authoritative build spec:** *BAHHAR AI — Master Build Prompt (v3, Final)* — where earlier docs
and this specification conflict on stack or direction, v3 governs. Known code-vs-v3 gaps are
listed explicitly in §2.2 and §9.
**Target Platforms:** iOS & Android (Flutter), Marketing Website (static)
**Backend:** Firebase (Auth, Firestore, Storage, FCM) + Python/FastAPI ML microservice
**Repository:** https://github.com/Sonalhegde/BAHHAR
**Target Market:** Sultanate of Oman — coastal fishermen, charter skippers, sport anglers

---

## 1. Product Vision

**Bahhar** (بحّار, "seasoned mariner") is an enterprise-grade, Oman-specific marine-intelligence
and smart-fishing companion. It converts oceanographic, meteorologic, tidal, bathymetric and
species-behavioural data into actionable, real-time fishing recommendations — engineered for
Oman's distinct ecosystems, from the Musandam fjords through the Batinah coast and Muscat shelf
to the upwelling trenches of Ash Sharqiyah/Al Wusta and the Khareef (monsoon) waters of Dhofar.

### Core value propositions
1. **Oman-tuned ML** — bite-window and species-presence predictions from localised SST
   gradients, thermoclines, bathymetric drop-offs and solunar tidal cycles. Target species:
   Kingfish (كنعد), Yellowfin Tuna (ثمد), Hammour (هامور), Amberjack, Sailfish, Mahi Mahi.
2. **Regulatory compliance** — geofencing and warnings for protected sanctuaries
   (Daymaniyat Islands Nature Reserve, Ras Al Jinz), aligned to Ministry of Agriculture,
   Fisheries & Water Resources decrees and the Environment Authority.
3. **Premium White editorial design** — quiet, high-contrast, distraction-free UI legible
   under direct Arabian sun at sea.
4. **Resilient offline architecture** — cached charts, offline GPS track logging, local catch
   recording, and a "last known conditions" fallback when the network is unavailable.
5. **Bilingual** — instantaneous English ⇄ Arabic (RTL) switching with localised species and
   maritime terminology.

---

## 2. System Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │          BAHHAR FLUTTER CLIENT (Riverpod)   │
                    └───────┬───────────────┬───────────────┬─────┘
             Firebase Auth  │  Firestore    │  Catch photos │  ML + marine REST
                            ▼               ▼               ▼
                    ┌─────────────────────────────────────────────┐
                    │               FIREBASE BACKEND              │
                    │  Auth (+968 OTP / Google / Apple / Anonymous)│
                    │  Cloud Firestore (me-central1) · Storage ·FCM│
                    └─────────────────────┬───────────────────────┘
                                          │ (catch/user data only)
                                          ▼
                    ┌─────────────────────────────────────────────┐
                    │           PYTHON FASTAPI ML ENGINE          │
                    │  /predict  /geofence/verify  /trip/optimize │
                    │  /marine/conditions   /tides   /health      │
                    └───────┬─────────────────────────┬───────────┘
                            ▼                         ▼
              Open-Meteo (weather + marine)   WorldTides v3 (tides)
              NOAA / GEBCO bathymetry         Solunar / astronomical
```

The Flutter client talks to Firebase directly for auth/persistence and to the FastAPI engine for
predictions and aggregated marine data. **The FastAPI engine is the only component that holds
third-party API keys** — the WorldTides key never ships in the mobile binary (see §7).

### 2.1 Technology stack

| Layer | Technology | Rationale |
| :-- | :-- | :-- |
| Mobile client | Flutter 3.24+ / Dart 3.5+ | Single iOS + Android codebase |
| State | Riverpod 2.x | Compile-safe, testable reactive providers |
| Routing | GoRouter 14.x | Declarative, deep-link shell + bottom tabs |
| Maps | **MapLibre GL (`maplibre_gl`) + OpenFreeMap vector tiles** (v3: keyless, no card, no Google Maps SDK) | Free unlimited tiles; re-skins the `positron` style |
| Geocoding/search | Nominatim (OpenStreetMap) — proxied via backend | Keyless; centralise rate-limit/cache |
| Cloud | Firebase (Auth/Firestore/Storage/FCM/App Check) | Realtime sync, offline cache, OTP |
| ML/marine microservice | Python 3.11+ / FastAPI / Uvicorn / Docker | Async REST scoring + upstream proxying |
| Models | Pydantic v2 (backend); Dart models are hand-written `fromJson`/`toJson` (equally valid per v3 status log) | Strict schema + JSON serialisation |
| HTTP (client) | `http` routed via backend (equally valid per v3 status log — not migrated to `dio`) | Single client, cache + central auth |
| Website | Self-contained HTML/CSS/JS + GSAP | Static landing page on Netlify/Vercel |

### 2.2 v3 reconciliation status
The repo was originally scaffolded on the older Google-Maps direction. Per the v3 status log:

- **Maps engine — RESOLVED (this pass):** `google_maps_flutter` has been removed and the map,
  `hotspots_provider` and `firestore_service` migrated to **MapLibre GL (`maplibre_gl ^0.27`) +
  OpenFreeMap** (keyless). Android Maps `meta-data`/`play-services-maps`/ProGuard rules deleted.
  No local Flutter SDK here, so **CI (`flutter_ci.yml`) is the verification gate** for `analyze`/`test`.
- **Packaging choices — ACCEPTED, do NOT migrate:** `http` (not `dio`), hand-written JSON models
  (not `freezed`/codegen), plain `flutter_riverpod` (not `riverpod_annotation`) are explicitly
  called out in v3 as *equally valid implementations of the same requirement*, not divergences.
- **Marine cache — SATISFIED:** server-side in-memory TTL cache meets v3 §9; Firestore-backed
  persistence is a non-blocking enhancement (§9).

---

## 3. Feature Specification (10 screens)

Screens live under `lib/features/<feature>/presentation/`. Status reflects the code as it exists
now — "Functional" means the screen renders and the flow works in demo mode; "Wired" means the
data source is live.

| # | Screen | File | Status | Notes |
| :-- | :-- | :-- | :-- | :-- |
| 1 | Splash / brand seal | `splash/splash_screen.dart` | Functional | Animated sail emblem, EN/AR, sovereignty subline |
| 2 | Auth & registration | `auth/login_register_screen.dart` | Partial | UI complete; Firebase providers need credentials |
| 3 | Onboarding carousel | `onboarding/onboarding_screen.dart` | Functional | 3 editorial slides |
| 4 | Home dashboard | `home/home_dashboard_screen.dart` | **Wired** | Fishing score gauge, **live marine chips**, ranked hotspots, stale-data banner |
| 5 | Marine chart / map | `map/fishing_map_screen.dart` | Functional | **MapLibre GL + OpenFreeMap (keyless)** — v3 migration complete |
| 6 | Hotspot details | `hotspot/hotspot_details_screen.dart` | Functional | Bathymetry, conditions, species, plan-trip CTA |
| 7 | Smart trip wizard | `trip_planner/smart_trip_wizard_screen.dart` | Functional | 3–4-step: species → vessel/range → window → review |
| 8 | Trip recommendation | `trip_planner/trip_recommendation_screen.dart` | Heuristic | Fuel/route uses local heuristic (see §9 roadmap) |
| 9 | Catch log & history | `my_catch/add_catch_screen.dart`, `catch_history_screen.dart` | Functional | Species/weight/length/GPS/gear/photo; Firestore-backed |
| 10 | Profile, compliance, alerts | `profile/*`, `notifications/notifications_screen.dart` | Functional | 11 profile sub-screens; language switcher; regulatory links |

Placeholder sub-widgets (`12-line` files returning `Placeholder()`): `home/widgets/{species_chips,
opportunity_gauge,hotspot_list}_widget.dart`, `map/widgets/{layer_toggles,probability_markers,
species_filter_chips}.dart`, `auth/widgets/{phone_otp,google_sign_in,apple_sign_in}_*.dart`.
Main screens inline their own equivalents and are functional; these extracted widgets remain to be
implemented (roadmap §9).

### 3.1 Screen flow (demo)
`Splash → Auth (Guest or sign-in) → Home ⇄ { Map · Trip · Catch · Profile }` via bottom tabs.
Deep-link and back-button behaviour must survive mid-flow interruption (stepper back-out, app
background/resume).

---

## 4. Design System (v2 Premium White)

### 4.1 Philosophy
Quiet, editorial, functional. Pure-white surfaces, hairline dividers instead of drop shadows,
a single navy accent, and muted signal colours. Built for high sun-glare legibility.

### 4.2 Colour tokens

| Token | Hex | Usage |
| :-- | :-- | :-- |
| surfacePure | `#FFFFFF` | App background & cards |
| surfaceSubtle | `#F7F7F5` | Stat chips, secondary toggles |
| borderHairline | `#E7E7E4` | 1px dividers |
| textPrimary | `#1A1A1A` | Headings & body |
| textSecondary | `#6B6B6B` | Captions, metadata |
| textTertiary | `#9E9E9E` | Placeholders |
| accentNavy | `#12263A` | Single primary accent |
| signalGood | `#2E7D5B` | Favourable (score ≥ 70) |
| signalCaution | `#B8862E` | Moderate (40–69) |
| signalAlert | `#B23A2E` | Poor / hazard |
| legalRestricted | `#6B5B95` | Marine reserves |
| mapWater | `#E5E9EC` | Nautical chart ocean |
| mapLand | `#F4F2EC` | Editorially muted coastline |

**Accessibility requirement:** legal status and probability must be distinguishable by
icon/shape, **not colour alone**; text contrast must meet WCAG AA (incl. signal colours on
white); every tappable element ≥ 44×44 px.

### 4.3 Typography
Screen title 22–24pt semibold (tracking −0.3); subhead 18pt; section micro-label 11pt bold
uppercase (+1.0); body 15pt (line-height 1.45); metric figures 26–32pt bold with
`FontFeature.tabularFigures()`; caption 12pt. Arabic face: IBM Plex Sans Arabic / system.

### 4.4 Motion
Gauge fill 0→score (800ms ease-out); hotspot cards stagger-fade (100ms each); tab transitions
250ms; map marker pulse for high-probability spots; input-focus + success-check animations.
All motion gated behind `prefers-reduced-motion`.

---

## 5. Backend — FastAPI ML & Marine Engine (`backend/main.py`)

Async Uvicorn service (Dockerised). Endpoints:

| Endpoint | Method | Purpose |
| :-- | :-- | :-- |
| `/` (and `/health`) | GET | Uptime, version, status |
| `/api/v1/predict` | POST | Bite probability (0–100) from thermal affinity, bathymetric preference, solunar factor; returns contributing factors, confidence, advisories |
| `/api/v1/geofence/verify` | POST | Point-in-polygon against Oman MPAs (Daymaniyat `[23.82–23.90°N, 58.05–58.18°E]`, Ras Al Jinz, Hormuz corridor); returns status, reserve name, legal decree, gear/permit notes |
| `/api/v1/marine/conditions` | GET | **Live aggregate** proxy (see §6) |
| `/api/v1/tides` | GET | **Live tide** extremes + derived state (see §6) |
| `/api/v1/trip/optimize` | POST | Waypoint & fuel routing — **not yet implemented** (roadmap §9) |

Species thermal envelopes (examples): Kingfish 24–28°C; Yellowfin 26–30°C.

---

## 6. Live Marine Data Integration

Replaces the former fully-simulated `MarineService` with real data + offline resilience.

### 6.1 Upstreams
- **Open-Meteo forecast API** (keyless): air temp, apparent temp, wind speed/dir/gust (km/h →
  knots ×1.943844), cloud, pressure, weather code, day/night.
- **Open-Meteo marine API** (keyless): sea surface temperature, wave height/period/direction.
- **WorldTides v3** (`/api/v3?extremes`): high/low extremes → derived tide state.

### 6.2 Server contract (`GET /api/v1/marine/conditions?lat&lon&include_tides`)
Returns: `sea_temperature_c, wave_height_m, wave_period_s, wave_direction_deg, wind_speed_kts,
wind_direction_deg, wind_gust_kts, air_temperature_c, apparent_temperature_c, cloud_cover_pct,
pressure_msl_hpa, weather_code, is_day, tide_state, tide_height_m, tide_source, copyright,
fetched_at, cached`. Upstream failure → HTTP **502**. `/api/v1/tides` → **503** when no key.

### 6.3 Caching & tide derivation
In-memory TTL cache (`WEATHER 600s`, `MARINE 1800s`, `TIDES 3600s`) — upstreams are hit at most
once per window per coordinate, never per widget rebuild/scroll. This satisfies the v3 §9
requirement to cache all third-party responses server-side; promoting it to a **Firestore**
snapshot cache (survives restarts / shared across workers) is a listed enhancement (§9). `_tide_state_from_extremes()`
brackets "now" between the previous/next extreme, interpolates height, and reports **High/Low**
within a 45-min window of an extreme, otherwise **Rising/Falling**.

### 6.4 Client behaviour (`lib/core/services/marine_service.dart`)
Instance-based fetch through `ApiClient` (base URL `String.fromEnvironment('ML_API_BASE_URL',
defaultValue: 'http://localhost:8000')`). On `ApiException` it replays the last-known snapshot
with `isCached: true`; `MarineService.isStale()` drives the Home "Last updated … showing last
known conditions" banner. Model `MarineConditions` has `fromJson`/`toJson`/`copyWith`.

---

## 7. Environment Variables & Secrets

All secrets live in gitignored `.env` (root) and `backend/.env`. `.env.example` documents names
with placeholder values only. **`.env` must never be committed** and is listed in `.gitignore`.

| Variable | Location | Purpose |
| :-- | :-- | :-- |
| `WORLDTIDES_API_KEY` | `backend/.env` | Tides proxy — **backend only**, never in the app |
| `ML_API_BASE_URL` | app `.env` / `--dart-define` | Deployed FastAPI base URL |
| `ML_API_TOKEN` | app `.env` | Service-to-service auth token (v3 name; supersedes the older `ML_API_AUTH_TOKEN`) |
| `COPERNICUS_MARINE_USERNAME` / `COPERNICUS_MARINE_PASSWORD` | `backend/.env` | Phase-5 chlorophyll/SST-front data — **not yet provisioned** |
| `FIREBASE_PROJECT_ID` / `FIREBASE_STORAGE_BUCKET` | app `.env` | Firebase project wiring |

> Maps need **no** key: the app renders OpenFreeMap tiles via MapLibre (the former
> `GOOGLE_MAPS_API_KEY` was removed with the Google Maps dependency).

`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`,
`android/key.properties` and any service-account JSON are gitignored and supplied out-of-band.

---

## 8. Data Model & Security Rules

Firestore collections: `users/{uid}`, `user_preferences/{uid}`, `catches/{id}`, `trips/{id}`,
plus read-only reference collections (`species`, `hotspots`, `regions`, `regulations`,
`restricted_zones`, `protected_areas`) and backend-refreshed snapshots (`marine_conditions`,
`weather`).

`firestore.rules`: users read/write only their own `catches`/`trips`/`preferences`/profile
(ownership checked on both `resource.data.userId` and `request.resource.data.userId`); reference
collections are authenticated-read / `write: if false`. `storage.rules` limit catch photos to
≤ 10 MB JPEG/PNG under the owner's authenticated path.

---

## 9. Implementation Status & Roadmap

**Complete / wired:** backend predict + geofence + health; live marine + tide proxy with TTL
cache and 502/503 semantics; Flutter `MarineService` live fetch + offline fallback + stale
banner; **MapLibre GL + OpenFreeMap map migration (v3) — Google Maps fully removed**; core
utils (`validators`, `formatters`, `geo_helpers`, `api_client`); 10 screens in demo mode; Android
build/sign/ProGuard config; `firestore.rules` + `storage.rules`; landing-page redesign; backend
pytest suite (**9/9 passing**).

**Blocked on external credentials (cannot be done in-repo):** Firebase project wiring
(`google-services.json`, `firebase_options.dart`, enable Auth/Firestore/Storage/FCM), Copernicus
Marine account (Phase 5), Apple Developer account (iOS), app signing keystore + Play Store listing.

**Deferred functional gaps (by design / high effort):**
- Phase-5 Copernicus Marine integration (chlorophyll/SST fronts) — account not yet provisioned.
- `/api/v1/trip/optimize` — trip planner still uses a deterministic heuristic.
- Extracted placeholder widgets (§3) — main screens inline working equivalents.
- Firestore geohash queries — currently client-side filtered (`TODO(perf)`).
- `shared_preferences` persistence for language/port/units; guest-mode catch queue.
- Push notification (FCM) handler wiring.
- Catch-photo background-isolate compression beyond `image_picker` 1600px/q82.

**Longer term (CHANGELOG "Unreleased"):** tide-model enhancements, social/leaderboards, offline
OSM maps, CV fish-ID, iOS release, IoT/fish-finder overlays.

---

## 10. Marketing Website (`landing-page.html`)

Self-contained static landing site. Rebuilt to the "Landing Redesign" spec: full-bleed hero with
real Omani photography + CSS ocean-scene fallback, transparent→frosted sticky header, verified
glassmorphism system, alternating story pillars (Smart Trip / Marine Charts / Catch Log) with
custom nautical-chart SVG, species grid with 8 anatomically distinct fish silhouettes, real Oman
flag SVG, GSAP + ScrollTrigger reveals (IntersectionObserver fallback so content is visible if
scripts fail), mobile hamburger (44px targets), email-capture form, working EN ⇄ AR RTL toggle,
`prefers-reduced-motion` gating. `index.html` redirects to it.

**Deployment:** `netlify.toml` publishes `.` and SPA-redirects `/*` → `/landing-page.html` with
security headers; a `.vercelignore` excludes non-web and secret paths for Vercel uploads. GitHub
Pages alternative: `https://sonalhegde.github.io/BAHHAR/`. Detailed host setup:
[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) (kept as an operational how-to reference).

---

## 11. Local Development Quick Start

```bash
# Flutter client
flutter pub get
flutter run            # add --dart-define=ML_API_BASE_URL=http://<host>:8000

# Backend engine
cd backend
pip install -r requirements.txt
cp ../.env.example .env         # then set WORLDTIDES_API_KEY
pytest tests/ -v                # 9 passing
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Full environment/IDE setup: [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md). Release publication:
[ANDROID_PUBLICATION_GUIDE.md](ANDROID_PUBLICATION_GUIDE.md).

---

## 12. Contact & Provenance
- Repository: https://github.com/Sonalhegde/BAHHAR · Issues: GitHub Issues
- Support: support@bahharai.com
- سلطنة عُمان • Sultanate of Oman
