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
| Website | Self-contained HTML/CSS/JS + GSAP | Static landing page on Vercel |

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
| 4 | Home dashboard | `home/home_dashboard_screen.dart` | **Wired** | Fishing score gauge, **live marine chips** (wave/wind/current/visibility), **live Weather card**, ranked hotspots, stale-data banner |
| 5 | Marine chart / map | `map/fishing_map_screen.dart` | Functional | **MapLibre GL + OpenFreeMap (keyless)** — v3 migration complete |
| 6 | Hotspot details | `hotspot/hotspot_details_screen.dart` | Functional | Bathymetry, conditions, species, plan-trip CTA |
| 7 | Smart trip wizard | `trip_planner/smart_trip_wizard_screen.dart` | Functional | 3–4-step: species → vessel/range → window → review |
| 8 | Trip recommendation | `trip_planner/trip_recommendation_screen.dart` | **Wired** | Ranked by `POST /api/v1/trip/optimize` over live conditions; falls back to the local heuristic when the backend is unreachable or had no water to rank against, and flags it (§6.6) |
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
| `/api/v1/weather` | GET | **Live atmospheric** weather: current + 8 hours + 5 days + alerts (see §6.5) |
| `/api/v1/trip/optimize` | POST | Ranks the client's candidate spots against the live water (see §6.6) — **rule-based, not a trained model**, and the response says so |

Species thermal envelopes (examples): Kingfish 24–28°C; Yellowfin 26–30°C.

---

## 6. Live Marine Data Integration

Replaces the former fully-simulated `MarineService` with real data + offline resilience.

### 6.1 Upstreams
- **Open-Meteo forecast API** (keyless): air temp, apparent temp, wind speed/dir/gust,
  cloud, pressure, weather code, UV, visibility, day/night — and the atmospheric half of
  `/api/v1/weather` (§6.5), so the weather panel is live with **no key of any kind**.
- **Open-Meteo marine API** (keyless): sea surface temperature, wave height/period/direction,
  and the surface current as `ocean_current_velocity` (m/s) + `ocean_current_direction`. The
  component names one might expect (`surface_current_eastward/northward`) are **not** published,
  and asking for them fails the entire call with 400 — waves and temperature included — so the
  request shape is pinned by a test that inspects what goes out, not what comes back.
- **WorldTides v3** (`/api/v3?extremes`): high/low extremes → derived tide state.
- **AccuWeather** (optional, `ACCUWEATHER_API_KEY`): only consulted for `/api/v1/weather`
  when a key is present. It is not required, and no provider key ever reaches a device.

### 6.2 Server contract (`GET /api/v1/marine/conditions?lat&lon&include_tides`)
Returns: `sea_temperature_c, wave_height_m, wave_period_s, wave_direction_deg,
wave_direction, wind_speed_kts, wind_direction_deg, wind_direction, current_speed_kts,
current_direction_deg, current_sets_to, visibility_km, wind_gust_kts, air_temperature_c,
apparent_temperature_c, cloud_cover_pct, pressure_msl_hpa, weather_code, uv_index, is_day,
tide_state, tide_height_m, tide_source, next_high_tide, sea_state{band,drivers},
copyright, fetched_at, cached` (+ `day_rating` when `boat_length_m`/`gear` are passed).
Two conventions are carried deliberately: wave and wind bearings are the direction the
sea/wind come **from**, while `current_sets_to` is the direction the water goes **to** — the
provider publishes the current bearing the same from-way as the rest, so the payload turns it
half a circle. That turn is inferred from the provider's stated convention rather than a gauge
comparison, so it sits on one line in `main.py` and two tests pin it (including the wrap at 180°).
`visibility_km` is `null` when upstream reported nothing, never `0` (which would read as fog).
**Known data-quality caveat, from the live smoke test:** Open-Meteo's visibility is a model field
and it is grid-cell sensitive on the coast — two positions about a kilometre apart at Al Bustan
read 0.2 km and 21.7 km, under the same clear sky. The value is passed through rather than
filtered, because inventing a plausibility test on someone else's model would be its own lie, but
nothing should treat a single low reading as a warning until that field is cross-checked against a
second source.
Wind arrives from Open-Meteo in km/h and is converted with `KM_PER_HOUR_TO_KNOTS`; currents
arrive in m/s and use `METERS_PER_SECOND_TO_KNOTS` — mixing the two factors overstates wind
3.6× and was the subject of a live-data fix. Upstream failure → HTTP **502**. `/api/v1/tides`
→ **503** when no key.

### 6.3 Caching & tide derivation
In-memory TTL cache (`WEATHER 600s`, `MARINE 1800s`, `TIDES 3600s`, `ACCUWEATHER 900s`) — upstreams are hit at most
once per window per coordinate, never per widget rebuild/scroll. This satisfies the v3 §9
requirement to cache all third-party responses server-side; promoting it to a **Firestore**
snapshot cache (survives restarts / shared across workers) is a listed enhancement (§9). `_tide_state_from_extremes()`
brackets "now" between the previous/next extreme, interpolates height, and reports **High/Low**
within a 45-min window of an extreme, otherwise **Rising/Falling**.

### 6.4 Client behaviour (`lib/core/services/marine_service.dart`)
Instance-based fetch through `ApiClient` (base URL `String.fromEnvironment('ML_API_BASE_URL',
defaultValue: 'http://localhost:8000')`). On `ApiException` it replays the last-known snapshot
with `isCached: true`; `MarineService.isStale()` drives the Home "Last updated … showing last
known conditions" banner. Model `MarineConditions` has `fromJson`/`toJson`/`copyWith`, plus
`windDirectionCompass`/`waveDirectionCompass`/`currentSetsToCompass` (16-point, same table as
the backend's `_compass_deg`) and `isRough`. The Home dashboard shows the six readings in two
rows of fisherman-worded chips — WAVE HEIGHT / WIND SPEED / WATER TEMP, then WAVE FROM /
CURRENT / VISIBILITY — with a sea-state band line under them.

### 6.5 Weather proxy (`GET /api/v1/weather?lat&lon&region`)
One call, one envelope: `current{temp_c, feels_like_c, condition, humidity_pct, wind_kmh,
wind_dir, rain_probability_pct, uv_index, visibility_km}`, `hourly[]` (next 8 hours),
`daily[]` (5 days), `alerts[]`, plus `source` (`accuweather` | `open-meteo` | `mock`),
`attribution`, `note`, `fetched_at`, `cached`. Degradation order is AccuWeather → last good
cached answer → live Open-Meteo → documented sample, and whichever ran, the response says so in
`note`; a spent AccuWeather budget cannot blank the panel. Open-Meteo publishes no
severe-weather alert feed for Omani waters, so `alerts` is empty and the app prints that
absence rather than an all-clear.

Client: `lib/core/services/weather_service.dart` mirrors `MarineService` exactly (live fetch,
last-known replay, `isStale()`) and adds `isSample()` so a mock can never read as a
measurement. `WeatherCardWidget` renders it on the Home dashboard under Ocean Conditions,
from the same coordinate, and takes the `AsyncValue` so its loading/error/data shapes are
tested without the provider graph.

### 6.6 Trip optimiser (`POST /api/v1/trip/optimize`)
Takes the client's own candidate spots plus the boat's economics, scores each against the
cached marine sample for the departure position, and returns `recommended`, `alternatives`,
`rejected` with `blockers`, `strategy`, `weights`, `conditions` and per-spot `reasons` codes
(`species_match`, `sea_state_*`, `no_viable_option`…). Codes, not sentences — bilingual wording
stays the client's job. It is **rule-based and says so in `strategy`**; the trained model the
old `TODO(ml-backend)` pointed at does not exist yet.
`lib/core/services/trip_service.dart` calls it and falls back to the on-device heuristic when
the backend is unreachable *or when the backend had no water to rank against*, and
`TripRecommendation.isMock` records which happened.

### 6.7 Wind/current field grid (`GET /api/v1/wind-field?fields=wind,current`)
The nullschool-style particle layer on the website's Marine Charts needs a **grid**, not a point.
The endpoint samples Open-Meteo across a 0.5° bounding box of Omani waters (16.5–26.5 N,
52–60 E → 17×21 = 357 points), sent as multi-coordinate batched calls (90 points per request,
verified against the live API, which answers several locations in one call), and returns a
wind-js-shaped payload: a header (`nx/ny/lo1/la1/dx/dy`, row-major west→east, north→south)
plus `u`/`v` arrays in m/s per requested field. The API rejects U/V component names on these
endpoints, so components are derived server-side from speed + FROM-bearing; conversion factors
come from the `hourly_units` label the response carries (the live marine API returns currents in
km/h whatever the docs say). Land cells stay `null` — "no water, no particle" — never `0`.
Cached 3 h (`WF_TTL_SECONDS`), matching the models' own refresh cadence; one field surviving an
upstream failure ships with a `note`, total failure is 502. Technique credit: `cambecc/earth`
(MIT) / Esri `wind-js` (Apache 2.0) — the *algorithm*, never the live nullschool site.

**Phase 2 — Flutter native port (SHIPPED):** the same grid renders inside `fishing_map_screen`
via `FlowOverlay` (`lib/features/map/presentation/widgets/flow_overlay_widget.dart`), a
`CustomPainter` in the `Stack` above `MapLibreMap`. Particles live in *geo* space and are
re-projected analytically every frame from a two-point Web-Mercator viewport snapshot
(`getVisibleRegion` + two `toScreenLocation` corner calls, refreshed ≤ every 80 ms and only while
the layer runs) — thousands of per-frame channel round-trips through
`MapLibreMapController.toScreenLocation` would swamp the platform channel; arithmetic on two
anchors does not. The linear projection only holds upright, so tilt/bearing from `onCameraMove`
pause the layer. Bilinear sampling with land-null renormalisation, the age/fade envelope and the
website's exact speed→colour ramps are ported to Dart (`maplibre_gl` is the native SDK, not a
WebView — no JS reuse). Canvas-based, **not** WebGL: the `mapbox/webgl-wind` approach has a known
rendering bug on Android/iOS browsers and this audience is mobile-first. 380 particles by
cap (≈600 ceiling in the ticket), gated behind the chart layer toggles (`windFlow`/`currentFlow`
in `LayerTogglesWidget`, wind on by default) and `MediaQuery.disableAnimations`, which swaps the
streaks for one static speed-coloured arrow per water cell. The fetch path is
`FlowFieldService` → `/api/v1/wind-field?fields=wind,current` with an offline last-known replay
like `MarineService`. **Remaining:** performance-test on real mid-range Android hardware, not an
emulator — tracked below until done.

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
| `FIREBASE_PROJECT_ID` | app `.env` | Which project the repo points at: **`bahar-3719a`** (`bahar` is only the console display name). Documentary — no `flutter_dotenv` exists, so `lib/` never reads it |
| `FIREBASE_STORAGE_BUCKET` | app `.env` | Empty by design. Cloud Storage requires Blaze; this project has no card |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | `--dart-define` | Catch-photo files. Public-by-design client config; RLS is the boundary |

> Maps need **no** key: the app renders OpenFreeMap tiles via MapLibre (the former
> `GOOGLE_MAPS_API_KEY` was removed with the Google Maps dependency).

`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`,
`android/key.properties` and any service-account JSON are gitignored and supplied out-of-band.
The `com.google.gms.google-services` plugin is applied in `android/app/build.gradle`, which is what
makes the option-less `Firebase.initializeApp()` work on Android — and what makes an Android build
fail loudly until that JSON is present. `firebase_options.dart` stays gitignored for the same
reason: it is generated per project, and CI clones have no business compiling against one.

`firebase.json`, `.firebaserc` and `firestore.indexes.json` **are** committed: they carry the
project id and no secrets, and hand-authoring them (rather than `firebase init`) is what kept the
already-reviewed `firestore.rules` / `storage.rules` from being overwritten by a scaffolder.

---

## 8. Data Model & Security Rules

Firestore collections: `users/{uid}`, `user_preferences/{uid}`, `fisherman_profiles/{uid}`,
`catches/{id}`, `trips/{id}`, plus read-only reference collections (`species`, `hotspots`,
`regions`, `regulations`, `restricted_zones`, `protected_areas`) and backend-refreshed snapshots
(`marine_conditions`, `weather`).

`fisherman_profiles/{uid}` is the flat document `FishermanProfileModel.toJson()` writes — personal
info plus *reference ids* to the vessel/crew/gear/document/licence collections, so a boat shared
by two skippers is stored once. It is read on sign-in and rewritten on every profile mutation
(`merge: true`), which is why the create rule asserts exactly that key set: a rule written for a
nested `personal`/`boat`/`gear` shape rejected writes the model never makes.

`firestore.rules`: users read/write only their own `catches`/`trips`/`preferences`/profile
(ownership checked on both `resource.data.userId` and `request.resource.data.userId`); reference
collections are authenticated-read / `write: if false`.

**Deployment state on `bahar-3719a`**, because "written" and "live" are different claims: the
reference collections are seeded (7 regions, 6 species, 7 hotspots — read back and confirmed), but
the live Firestore ruleset is still the deny-all production template and the composite index below
does not exist yet. Both need `firebase deploy --only firestore:rules,firestore:indexes` run by a
project owner; the Firebase Admin service-account key can write documents and create a ruleset but
is refused on releasing it and on creating indexes (403).

`catches` needs that index: `fetchCatchesForUser` issues `where('userId') + orderBy('caughtAt')`,
which live Firestore rejects with `FAILED_PRECONDITION` until a composite
`userId ASC / caughtAt DESC` index exists. It is declared in `firestore.indexes.json`. Every other
query in the app is a plain document read or a client-side filter.

Catch photos are **not** in Firebase Storage. `storage.rules` is kept but inactive — Cloud Storage
sits behind Blaze at any volume — and the bytes go to Supabase Storage instead, which holds files
only: Firestore still owns the catch document and stores the returned public URL.

---

## 9. Implementation Status & Roadmap

**Complete / wired:** backend predict + geofence + health; live marine + tide proxy with TTL
cache and 502/503 semantics; Flutter `MarineService` live fetch + offline fallback + stale
banner; extended Ocean Conditions (wave direction, current speed/set, visibility, sea-state
band) with the fisherman-worded chip row on Home; **live `/api/v1/weather` on keyless
Open-Meteo** plus `WeatherService`/`WeatherCardWidget` on the same screen; **`POST
/api/v1/trip/optimize`** wired into `trip_service.dart` with the heuristic as offline fallback;
Fisherman Profile Firestore read/write; `shared_preferences` persistence for
language/port/units; guest-mode catch queue flushed on sign-in; FCM handlers behind a
`FirebaseService.isConfigured` guard; **MapLibre GL + OpenFreeMap map migration (v3) — Google
Maps fully removed**; core utils (`validators`, `formatters`, `geo_helpers`, `api_client`); 10
screens in demo mode; Android build/sign/ProGuard config; `firestore.rules` + `storage.rules`;
landing-page redesign; backend pytest suite (**39 passing**); `/api/v1/wind-field` grid endpoint +
nullschool-style wind/current particle layer on the website's Marine Charts.

> The Dart side of the items above is verified by CI (`flutter analyze`, `flutter test`).
> A Flutter SDK 3.47 now exists at `C:\flutter` locally (web target added via `web/`), so the app
> can also be exercised with `flutter run -d web-server`; the Android `res` tree and the iOS
> project remain outside this checkout, so mobile targets still build in CI only.

**Blocked on external credentials (cannot be done in-repo):** Copernicus
Marine account (Phase 5), Apple Developer account (iOS), app signing keystore + Play Store listing.

**Sign-in surface, as of the card-free pass:** email/password (verified working against the live
project), Google, Apple and guest. Phone OTP is still implemented in `auth_repository.dart` and
`phone_otp_widget.dart` but is not offered on screen — SMS sending has required Blaze since
September 2024. The email form previously validated the fields and then apologised; it calls real
Firebase Auth now.

**Deferred functional gaps (by design / high effort):**
- **Flutter native particle overlay on-device performance test** — the overlay itself shipped
  (§6.7 phase 2); the mid-range-Android hardware perf gate is still open until a device exists.
- Phase-5 Copernicus Marine integration (chlorophyll/SST fronts) — account not yet provisioned.
  No placeholder field implies it is live.
- `/api/v1/trip/optimize` is **rule-based**, not the trained model the original
  `TODO(ml-backend)` asked for; `strategy` in the response states this. The learned ranker
  waits on enough local catch data to train on.
- Bilingual wording for the optimiser's `reasons` codes — the server returns codes, and the
  client wording table has not been written, so no screen reads them yet.
- Firestore geohash queries — still client-side filtered (`TODO(perf)`); justified to defer at
  the 12-hotspot seed size, revisit when that count grows.
- Catch-photo background-isolate compression beyond `image_picker`'s 1600px/q82 — needs
  `flutter_image_compress`, which cannot be resolved or verified without a Flutter SDK.
- Launcher icons — dependency and `flutter_launcher_icons.yaml` are configured; generation
  needs the SDK and the platform `res`/`xcassets` trees absent from this checkout.
- Extracted placeholder widgets (§3) — main screens inline working equivalents.

**Longer term (CHANGELOG "Unreleased"):** tide-model enhancements, social/leaderboards, offline
OSM maps, CV fish-ID, iOS release, IoT/fish-finder overlays.

---

## 10. Marketing Website (`website/landing-page.html`)

Self-contained static landing site. Rebuilt to the "Landing Redesign" spec: full-bleed hero with
real Omani photography + CSS ocean-scene fallback, transparent→frosted sticky header, verified
glassmorphism system, alternating story pillars (Smart Trip / Marine Charts / Catch Log) with
custom nautical-chart SVG, species grid with 8 anatomically distinct fish silhouettes, real Oman
flag SVG, GSAP + ScrollTrigger reveals (IntersectionObserver fallback so content is visible if
scripts fail), mobile hamburger (44px targets), email-capture form, working EN ⇄ AR RTL toggle,
`prefers-reduced-motion` gating. `index.html` redirects to it.

The copy is cross-checked against the shipped API shape rather than the ambition: the Ocean
Conditions and Weather pillars name the provider that actually answers (`Open-Meteo`, live,
through the BAHHAR backend), say that AccuWeather takes the same contract only once a key is
configured, and say plainly that no severe-weather alert feed exists for Omani waters instead of
implying an all-clear. Where the app now shows something the page under-described — the five-day
outlook in the Weather card — the page was brought in line with the code, not the reverse.

The Marine Charts pillar embeds `website/map-mockup.html`, which carries the wind/current
particle-flow layer (§6.7) as ES modules — `assets/js/flow-field.js` (fetch + bilinear grid),
`assets/js/flow-render.js` (advection, glow/core strokes, speed-tint texture, reduced-motion
static arrows) and `assets/js/map-page.js` (page wiring) — the HTML holding markup and styles
only. A canvas of advected streaks over the Leaflet chart, switchable
Wind / Current / Off independently of the spots and protected-area layers, with a sidebar that
reads wind kt + FROM compass and current kt + SETS TO under the cursor, and an honest provenance
line that says *"Illustrative sample"* whenever the live grid is unreachable.

**Deployment:** `website/vercel.json` (deployed with Vercel root directory set to `website/`)
rewrites `/*` → `/landing-page.html` and sets security headers; a `.vercelignore` excludes non-web
and secret paths. GitHub Pages alternative: `https://sonalhegde.github.io/BAHHAR/`. Detailed host
setup: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) (kept as an operational how-to reference).

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
pytest tests/ -v                # 32 passing
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

`pytest tests/ -v` needs no credentials: the weather and marine tests stub their upstreams, and
`/api/v1/weather` works with no key at all.

Full environment/IDE setup: [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md). Release publication:
[ANDROID_PUBLICATION_GUIDE.md](ANDROID_PUBLICATION_GUIDE.md).

---

## 12. Contact & Provenance
- Repository: https://github.com/Sonalhegde/BAHHAR · Issues: GitHub Issues
- Support: support@bahharai.com
- سلطنة عُمان • Sultanate of Oman
