# Changelog

All notable changes to the BAHHAR project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Wind & current particle visualization — website phase (2026-09-21)

The nullschool-style flow layer, built from Bahhar's own Open-Meteo integration — the live
earth.nullschool.net site is never queried or embedded; only the *technique* (particles advecting
through a bilinearly interpolated U/V grid) is reused, from `cambecc/earth` (MIT) and Esri
`wind-js` (Apache 2.0), and credited in the code that ports it.

**Added**
- `GET /api/v1/wind-field` (`backend/main.py`): 0.5° U/V grid over Omani waters (17×21 points),
  fetched as batched multi-coordinate Open-Meteo calls (90/request), wind-js-shaped response,
  3 h TTL cache. Components are derived server-side because the live API rejects `u10` and
  `surface_current_eastward` outright; speed→m/s factors come from the response's own
  `hourly_units` label (the live marine API answers currents in km/h). Land cells stay null.
  7 new pytest cases (shape, units, nulls, cache, partial 200 + note, total 502, 422) —
  **39 passing**.
- `website/map-mockup.html`: canvas particle layer over the Leaflet chart (trails via
  `destination-out` fading, geo-anchored so pan/zoom keeps streaks on the water), Wind /
  Current / Off segmented control, independent Fishing-spots and Protected-area checkboxes,
  a sidebar readout (wind kt + FROM compass, current kt + SETS TO, click-to-pin), speed→colour
  scales, `prefers-reduced-motion` static-arrow fallback, area-scaled particle count capped
  at 900 for mid-range phones, and live-or-sample provenance that never pretends: with no
  reachable backend it draws a synthetic field explicitly labelled "Illustrative sample".
- CORS middleware on the backend (env-configurable `BAHHAR_CORS_ORIGINS`) so browser clients
  can reach the API; every endpoint is a read-only public-data proxy, no cookies or tokens.

**Deferred by design (at the time):** the Flutter native port (`CustomPainter` over `MapLibreMap`,
no WebGL) was written up as its own phase-2 ticket in SPECIFICATION.md §6.7 — it shipped in the
app phase below.

### Wind & current particle overlay — Flutter app phase (2026-09-21)

SPECIFICATION.md §6.7 phase 2, port of the website layer. Technique credit as above
(`cambecc/earth` MIT / Esri `wind-js` Apache 2.0) — in the widget's doc comment.

**Added**
- `FlowOverlay` (`lib/features/map/presentation/widgets/flow_overlay_widget.dart`): animated
  wind/current streaks painted above the MapLibre chart. Particles advect in geo space and are
  re-projected analytically each frame from a two-point Web-Mercator viewport snapshot
  (`getVisibleRegion` + two `toScreenLocation` calls, refreshed ≤ 80 ms) instead of thousands of
  per-frame platform-channel round-trips; tilt/bearing pauses the layer (the linear projection
  holds upright only). Same bilinear land-null-renormalised sampling, life-envelope fading and
  speed→colour ramps as the website, so both surfaces speak one visual language. 380 particles,
  `MediaQuery.disableAnimations` → static per-cell arrows. Canvas 2D, deliberately not WebGL.
- `FlowField`/`FlowGrid` model, `FlowFieldService` (GET `/api/v1/wind-field?fields=wind,current`,
  offline last-known replay like `MarineService`) and a Riverpod `flowFieldProvider` that the
  map invalidates when the layer is switched back on after the grid went stale.
- Fishing Map integration: the previously orphaned `LayerTogglesWidget` is now the screen's chart
  layer panel — wind/current flow (mutually exclusive), hotspot circles, protected areas (real
  `GeofenceService.omaniReserves` drawn as translucent geo-polygon discs) and GPS tracking — and
  the inline species chips were swapped for the shared `MapSpeciesFilterChips`. A glass legend
  shows the colour scale and honest provenance (live/cached + time).
- Tests: `test/unit/flow_field_test.dart` (grid contract, bilinear, land vs calm, freshness) and
  `test/features/map/flow_overlay_test.dart` (projection math, seed/tick lifecycle, off and
  missing-data silence, rotated-camera abstention, reduced-motion fallback, ramp continuity).

### Marine Charts page — JavaScript module split + visual pass (2026-09-21)

`website/map-mockup.html` no longer carries inline application JavaScript: it is markup + CSS
with the flow layer as ES modules under `website/assets/js/` (`flow-field.js` data/grid,
`flow-render.js` renderer, `map-page.js` page wiring). Visual pass on the particle layer —
continuous (non-banded) speed→colour ramps, glow + core two-pass strokes, particle life-envelope
fading, a blurred per-cell speed-tint texture under the streaks — plus glass-panel, marker-pulse
and segmented-control polish; `prefers-reduced-motion` keeps static arrows.


### Firebase connection + card-free storage & auth (2026-09-21)

The brief said to connect the real Firebase project, and the first step was to confirm the project ID
rather than trust the console. The console shows **`bahar`**; the service-account key the project owner
supplied says `"project_id": "bahar-3719a"`, so `bahar` is a display name and every prior reference to
`bahhar-ai-prod` in `.env.example` was a placeholder nobody had replaced. Everything below was then
checked against the live project rather than assumed, which changed two of the brief's premises.

**Added / changed — against the live project**
- `firebase.json`, `.firebaserc` (`default: bahar-3719a`) and `firestore.indexes.json` committed.
  Hand-authored instead of `firebase init`, because init offers to overwrite the reviewed
  `firestore.rules` / `storage.rules` with a scaffold.
- **`com.google.gms.google-services` is now applied** in `android/app/build.gradle`. It was declared
  `apply false`, which meant the plugin never ran, `google-services.json` was ignored, and the
  option-less `Firebase.initializeApp()` the app has always called had no Android config to pick up.
  Consequence accepted deliberately: an Android build now fails loudly until that file is present.
- `backend/requirements.txt` gained `firebase-admin>=6.5.0`. Without it `seed_firestore.py` catches
  `ImportError` and prints a *verified dry run* — a green-looking seed that wrote nothing.
- Reference data **seeded and read back** on `bahar-3719a`: 7 regions, 6 species, 7 hotspots.

**Two things the probes found, which the brief assumed were already fine**
- **The catch log was broken by a missing index.** `fetchCatchesForUser` pairs `where('userId')` with
  `orderBy('caughtAt', descending: true)`; live Firestore rejected exactly that query with
  `FAILED_PRECONDITION: The query requires an index`. Declared in `firestore.indexes.json`.
- **The live security rules are not this repo's rules.** The released Firestore ruleset is Google's
  deny-all production template (`allow read, write: if false`), so §5's "redeploy the existing rules"
  and §8's "check the profile rule now that it's live" rested on a false premise. Nothing client-side
  can read or write yet.

Both need `firebase deploy --only firestore:rules,firestore:indexes`. The service-account key can write
documents and *create* a ruleset but is refused (403) on **releasing** it and on creating indexes, so
that command belongs to a project owner — recorded rather than worked around, and no deploy is claimed.

**Removed — the card-free migration**
- **`firebase_storage` is gone**, replaced by `supabase_flutter` and
  `lib/core/services/supabase_storage_service.dart`. Cloud Storage requires Blaze at any volume and the
  project carries no card; the same reasoning that put MapLibre/OpenFreeMap where Google Maps was.
  Firestore still owns the catch document and stores the returned URL — only the bytes moved.
  `storage.rules` is kept with an INACTIVE header rather than deleted, so the policy is still on record.
- **Phone/OTP is off the login screen** (Blaze since September 2024): the method selector, the phone
  field and the OTP step were removed from `login_register_screen.dart`; `sendOtp`/`verifyOtp` stay in
  `auth_repository.dart` doc-guarded, and `phone_otp_widget.dart` stays unused, so reversing this is a
  UI change and not a rewrite.
- `catches_provider.addCatch` now returns `Future<String?>` — a photo it could not store comes back as a
  warning the `Add Catch` screen shows, instead of a record silently saved with a URL pointing at nothing.

**Fixed — a stub that looked like a feature**
With Phone removed and Apple needing a paid developer account, the only non-Google method on screen was
`_handleEmailAuth`, which validated the fields and then apologised. The email form now performs real
`signInWithEmail` / `registerWithEmail`, routed through a new `_finishSignIn` so account creation also
upserts `users/{uid}` (it never passes through a credential exchange), with six added `_friendlyError`
cases including one that names the console switch when the provider is off. **Verified against the live
project**: a probe user was created, signed in through the same `accounts:signInWithPassword` endpoint
the SDK calls (200 + idToken), and deleted. That also established the Email provider is already enabled,
and that the project has **no registered web app**, hence no web API key — Google sign-in still needs
the device config.

**Verification honesty** — no Flutter/Dart SDK, no `firebase`/`flutterfire` CLI and no Chrome exist in
this environment, so `flutter run`, `flutter test` and `flutter analyze` were **not** run; CI
(`flutter_ci.yml`) is the gate for the Dart changes, and the edited files were checked with a
string-aware bracket-balance scanner plus leftover-symbol greps, which is not a compiler.
`pubspec.lock` is stale until someone runs `flutter pub get`. `pytest tests -q` run from `backend/` →
32 passed. From the repo root the same command fails at collection with `No module named 'main'`;
`backend_ci.yml` sets `working-directory: backend` for exactly that reason, so it is a pre-existing
path rule rather than a regression — the README's own instructions already use the `cd backend` form.

### App building pass — one logo, live weather, extended ocean data, persisted profile, trip optimiser (2026-09-20)

A brief written against the actual repo, so the first job was checking each claim in the code: the
MapLibre migration, the RTL toggle, the Hammour/Grouper fix and the profile model were already
done and were left alone. Everything below was not.

**Added**
- **`GET /api/v1/weather` is live.** With no key set it now serves **Open-Meteo** — the keyless
  provider the marine proxy already uses — mapped onto the AccuWeather contract the client was
  built against, so setting `ACCUWEATHER_API_KEY` later changes the source, not the app.
  Degradation: AccuWeather → last good cached answer → live Open-Meteo → documented sample,
  and `note` says which ran. Supersedes the mock-by-default described below.
- **Flutter weather stack** — `WeatherConditions`/`WeatherHour`/`WeatherDay`/`WeatherAlert`,
  `lib/core/services/weather_service.dart` mirroring `MarineService` (live fetch, last-known
  replay, `isStale()`, plus `isSample()` so a mock can never read as a measurement) and
  `WeatherCardWidget` on the Home dashboard **under** Ocean Conditions, same coordinate, one card
  among the existing readouts rather than a new screen: air temp / UV / humidity chips, an
  eight-hour strip and a five-day outlook.
- **Ocean Conditions extended in the app** — `MarineConditions` gained `waveDirectionDeg`,
  `currentSpeedKts`/`currentDirectionDeg` and `visibilityKm` with 16-point compass getters, and
  the dashboard prints two rows of fisherman-worded chips (WAVE HEIGHT / WIND SPEED / WATER TEMP,
  then WAVE FROM / CURRENT / VISIBILITY) over the sea-state band. Wave and wind bearings are the
  direction they come **from**; the current is what it **sets toward** — modelled apart because
  they routinely differ.
- **`POST /api/v1/trip/optimize`** — ranks the client's own candidate spots against the cached
  marine sample for the departure position (bite probability + species match + depth affinity,
  minus crossing distance and the worst live sea-state reading), excluding anything outside the
  radius or over the fuel budget, and returns `recommended`/`alternatives`/`rejected` with
  `blockers`, plus `strategy`, `weights` and per-spot `reasons` **codes** so bilingual wording
  stays the client's job. `trip_service.dart` calls it, keeping the heuristic as the fallback,
  and `TripRecommendation.isMock` is now true when the backend had no water to rank against — a
  ranking that flew blind is the offline case for the fisherman whatever URL produced it. The
  endpoint is **rule-based**: `strategy` reads "not a trained model", which is why this is not
  the "real ML endpoint" the brief asked for.
- **Fisherman Profile persistence** — `fisherman_profiles/{uid}` read on sign-in and written on
  every `updatePersonalInfo`/`addVesselId`/… mutation, mirroring the `catches` pattern, with
  `merge: true` and a `createdAt` stamped only when absent. No parallel local store: the
  in-memory `.demo` state still covers an unconfigured build.
- **`shared_preferences`** behind `PrefsService` for language, port and units, so they survive a
  restart instead of resetting; **FCM handlers** (`NotificationService`) and region
  subscription, all behind `FirebaseService.isConfigured`; a **guest-mode catch queue** that holds
  catches logged before sign-in and flushes on authentication — including mid-session, which
  needed a `reload()` on the catches controller that nothing had.
- **Launcher icons + website logo** — `flutter_launcher_icons` and `flutter_launcher_icons.yaml`
  pointed at the 1024² `app_icon.jpg`; the landing page's sail SVG redrawn from the Flutter
  painter's own geometry (see Fixed).
- **Tests** — `test/features/home/weather_card_widget_test.dart` (data shape, warning
  thresholds, provenance wording, missing fields, loading/error, Arabic) and
  `test/core/models/marine_conditions_test.dart` (parsing, string numbers, null-vs-zero
  visibility, separate wave/wind bearings, compass wrapping, JSON round-trip). Backend **32
  passing** (from 16), covering the trip optimiser's exclusions and blockers, the weather
  contract, the wind conversion and the marine request shape.

**Fixed**
- **The Ocean readout was dead on live data.** The current fields had been wired under variable
  names Open-Meteo does not publish (`surface_current_eastward/northward`), and the marine API
  rejects the *whole* request when any one hourly variable is unknown — so waves, sea temperature
  and current all failed together as an upstream 400, and the endpoint returned 502 with nothing
  to show. Every mocked test passed, because every test replaced the fetcher and never looked at
  what it asked for. Found by running the backend against the real API for the demo, not by the
  suite: the fields are `ocean_current_velocity` (m/s) and `ocean_current_direction`, and a new
  test now pins the outgoing request shape so a bad name cannot come back through a stub.
- **Wind was overstated 3.6× on live data.** Open-Meteo's default unit is km/h and the marine
  proxy converted it with the m/s→kt factor, so a 20 km/h breeze (10.8 kt) arrived as 38.9 kt and
  banded *high risk* — warning fishermen off benign water. `KM_PER_HOUR_TO_KNOTS` and
  `METERS_PER_SECOND_TO_KNOTS` are now separate named constants; currents genuinely do arrive in
  m/s and keep theirs.
- **`firestore.rules` rejected every profile write.** The create rule asserted a nested
  `personal`/`boat`/`gear` shape; `FishermanProfileModel.toJson()` writes those keys flat. The
  rule now asserts the set the model actually writes.
- **One logo, not two.** The app paints an open stroke-only sail over a separate wave squiggle;
  the website drew a closed, filled teardrop. The Flutter geometry is canonical — it is the one
  with a documented rationale — and the site's SVG is now the same two paths, normalised to a
  100×90 viewBox, with the wrapper's sizing, filter and drop-shadow untouched. `app_icon.jpg`
  was already byte-identical between the two asset trees, and the favicon and `og:image` still
  point at it.
- **`NotificationService.init()` could abort startup.** It caught `FirebaseException` only, so a
  present-but-unusable push plugin (`UnsupportedError`, `PlatformException`) threw out of `main()`
  before `runApp`. It now degrades to a `debugPrint`.

**Changed**
- **Landing-page copy held to what ships.** The weather pillar said AccuWeather; it now says
  Open-Meteo, live, through the BAHHAR backend, with AccuWeather taking the same shape the day a
  key is configured — in Arabic too. Two pre-existing overclaims found by grepping for
  `trained|ML|water column`: "Our forecasts are trained on Omani ecosystems" → rule-based today,
  trained on local catch data later, and "We model the Omani water column" → resolving the
  upwelling front is planned, not shipped. Where the app grew past the page — the five-day
  outlook — the page was already right and the card was built to match it.

**Verified, and what was not**
- `pytest tests/ -q` → **32 passed**. Every touched Dart file was re-read line by line and put
  through a comment/string-stripping delimiter balance check (21 files, 0 errors).
- **The backend was run against the live upstreams**, which is what surfaced the marine bug: for
  Muscat, `/api/v1/weather` answered live Open-Meteo (29.2 °C, feels like 35.8, visibility 21.7
  km, five days), `/api/v1/marine/conditions` answered 31.9 °C SST, 0.5 m waves from the E, 0.8
  kt current, sea state *good* and a 06:55 high tide, and `POST /api/v1/trip/optimize` ranked the
  candidates against those readings and rejected two for crossing the radius and the budget.
  The current's sets-toward bearing follows the provider's from-convention for every direction it
  publishes; it is pinned by tests and flagged in code as an inference, not a gauge check.
- **No Flutter or Dart SDK exists in this environment**, and `android/app/src/main/res` and the
  iOS asset catalogs are absent from the checkout, so `flutter test`, `flutter analyze`,
  `dart format` and `flutter_launcher_icons` could not be run and `flutter run` could not produce
  the app demo. CI (`flutter_ci.yml`) is the gate for those three, and `flutter analyze` there runs
  `--no-fatal-infos --no-fatal-warnings`, so it fails on errors only.

**Not done, deliberately**
- Catch-photo background-isolate compression — needs `flutter_image_compress`, which cannot be
  resolved or verified without the SDK; `image_picker` already caps at 1600px/q82.
- Geohash Firestore queries — 12 seed hotspots are comfortably client-side filtered, so the
  `TODO(perf)` stays honest where it is.
- `flutter_launcher_icons` was added and configured but **not run**, for the SDK reason above; the
  generated icons are the one deliverable here that is genuinely outstanding rather than deferred.
- Firebase/Copernicus/Apple Developer/Play Store wiring — blocked on credentials the user has to
  supply; nothing was stubbed to pretend otherwise.

---

### Landing page + backend — ocean information, AccuWeather, fisherman profile (2026-09-20)

An additive brief: extend what exists rather than draw a second of anything. Three new panels on
`website/landing-page.html` (Fisherman Profile, Weather, the synthesis banner) and an extended
Ocean readout, with the same fields now returned by the FastAPI backend.

**Added**
- **Ocean Information readout** (`#ocean-readout`): wave direction, wave period, current speed and
  the bearing it *sets toward*, visibility and an explicit *next high tide*, as real text rather
  than more SVG so they can be translated and measured. Chlorophyll and water colour are absent on
  purpose — Copernicus is planned, not live. `GET /api/v1/marine/conditions` gained
  `wave_direction`, `wave_period_s`, `current_speed_kts`, `current_sets_to`, `visibility_km`,
  `uv_index`, `next_high_tide`, `sea_state` and an optional `day_rating`.
- **Five sea-state bands** (Good / Moderate / Rough sea / Strong current / High risk) with the
  thresholds written once in a CSS comment and once in `_sea_state_band()`, and the rule printed
  under the chips: *the worst single reading, never an average*. Colour is not the only carrier —
  each band has a shape (hollow / triangle / square) and the active one carries `aria-current`.
- **Weather pillar** against a real AccuWeather response shape, plus `GET /api/v1/weather`: a
  two-step `locationKey` cached 24 h, current/hourly/daily/alerts cached 30/60 min per region,
  the key held only in the backend's `.env`, a daily call budget that degrades to the last good
  response and then to the documented mock rather than returning a 5xx, and attribution carried
  inside the payload. No alert banner is drawn, because no alert is active.
- **Fisherman Profile pillar** (`#pillar-profile`) in the brief's three groups — Fisherman / My
  Boat / My Gear — with the vessel strings identical to the wallet's and the safety screen's, and
  `fisherman_profiles/{userId}` added to `firestore.rules` under the same owner-only treatment as
  `catches` and `trips`.
- **Synthesis banner** between the trip planner and the charts, stating its own rule in four
  steps and naming which step the fisherman's own boat changes.
- **Nav** now carries Profile / Ocean / Weather alongside the existing five, with a 1200 px
  tightening step so the longer row still fits before the 968 px hamburger.

**Fixed**
- **The Arabic dictionary was keyed by position** (`#features .pillar:nth-of-type(3) …`), so every
  pillar inserted above another silently mis-translated the ones below it. All 128 pillar rows are
  now keyed to stable `#pillar-*` ids; a dictionary probe reports **0 dead selectors and 0
  multi-matching rows** across 259 entries.
- `.cond dd .qual` never matched: five of the eight tiles carry the qualifier as a *sibling* of
  `dd`, so those lines were rendering unstyled.
- The flag wordmark (`Oman`) had no Arabic row at all; it now reads **عُمان**, while the brand
  name stays Latin in both languages.

**Verified**
- WCAG census (every leaf text node, ancestor backgrounds composited, AA by size/weight), now
  including the panels that sit inside `.pillar-media` because they paint their own opaque
  surface: **284 elements EN / 278 AR, 0 failures**.
- RTL collision + nav-overflow probe at 1500/1200/1024/990 px in both directions: no horizontal
  scroll, nav ends 18 px clear of the utility bar at the tightest width, **0 text collisions**.
  One collision is reported at 1024 px AR inside `#regions` (`الخريطة البحرية` over `الوزارة`) —
  reproduced against `HEAD` before this pass, so it is pre-existing and left alone here.
- `backend/tests/test_api.py`: **16 passing**, all upstream calls monkeypatched. New cases pin the
  band thresholds, the worst-reading rule, the boat/gear step in `day_rating`, the Muscat-clock
  high tide, and the mock weather contract (attribution present, `alerts == []`).

**Not done, deliberately**
- `documents_wallet_screen.dart` and `safety_center_screen.dart` still keep their own copy of the
  vessel data. The canonical record and its rule are in place, but the Dart rewiring cannot be
  compiled or tested in this environment (no Flutter/Dart SDK) and the app's providers are still
  in-memory `.demo` state with no Firestore writes anywhere — pointing two screens at a record
  that nothing persists yet would be a rewrite that cannot be verified.
- The landing page is a static mock: the new panels read illustrative values, not the live
  endpoints, and say so on their faces.

---

### Landing page — the hero seam, one light background, and the RTL pass (2026-09-20)

A five-point brief, worked as five commits: `fix: remove leftover gradient blobs and blend hero
photo transitions`, `style: unify all light backgrounds to blue-tint system`,
`fix: RTL layout overlap issues`, `fix(i18n): Arabic species labels follow the catalogue…`, plus
the `feat(i18n)` toggle the brief still thought was missing — it had already shipped (see the
audit table).

**Fixed**
- **The hero/stats overlay.** The faint circular "blobs" over the Khore Dhawas photograph were
  decorative radial gradients left behind from the plain-white hero that preceded it — deleted, not
  retuned. One deliberate `linear-gradient` wash now sits on the photo, and the hard cream seam
  under the stats band is gone: the wash reaches full opacity in the last part of the section and
  meets the next section's background at the seam.
- **One light background instead of three.** The root cause was the body itself: a `linear-gradient`
  drifting from warm paper through pure white to cream as you scrolled. `--bg-primary #f4f8fa` and
  `--bg-secondary #ecf2f5` now replace `--paper`, `--off` and `--oman-white`, which are **deleted,
  not aliased**, so a forgotten `var(--paper)` cannot survive the pass. The same tokens went into
  `map-mockup.html`, `privacy.html` and `terms.html`, which still ran the warm gradient — a
  "complete" pass that stopped at the landing page would have reintroduced exactly the drift the
  brief objected to.
- **Contrast, measured rather than assumed.** White → blue tint is a small delta that adds up: an
  automated census (every leaf text element, ancestor backgrounds composited, AA thresholds by
  size) reported **30 real failures**, all seafoam or teal on a light surface. Six groups fixed —
  the frosted-header nav underline, `.pillar-eyebrow`, `.region`, `.region-num`, `.region-legal`,
  and the chart's 8.6 px scale-bar labels at 2.7:1. Seafoam turned out to be a dark-band accent
  only: 1.97–2.47:1 on every light surface, where teal clears 4.8.
- **RTL, which is where the real Arabic bugs were.** Gradients do not mirror: `.hero-overlay` was a
  physical 90° wash, so the Arabic headline moved to its thin end and sat on sunlit rock — median
  white-on-photo contrast **5.37 against 12.27 in English**, restored to **14.06** with a 270°
  twin. Also mirrored: the header corner glow (`100% 0%` → `0% 0%`), the mobile drawer (pinned to
  `right`, so it arrived from the side opposite its own button), the nav underline, the utility-bar
  separator, and the species-card hover nudge.
- **Arabic species labels, against the app's own catalogue.** Arabic mode was echoing the English
  grid's gloss, so each card printed the same word twice (`الكنعد` over `كنعد (Kanaad)`); the second
  line is now the scientific name from `lib/core/constants/fish_species.dart`, and the English
  glosses take the catalogue's definite forms. The construct-state phrase (`من كنعد مسندم إلى ثمد
  ظفار`) is deliberately left bare. The footer note also claimed the live chart tiles stay English;
  OpenStreetMap serves whatever language it holds for a place, so the note now says that.

**Audit — brief claim vs. current source**

| Claim in the brief | Verified against the source | Action |
|---|---|---|
| Arabic toggle is `href="#"`, non-functional | False — a `<button onclick="toggleLanguage()">` with `dir`/`lang` switching and `localStorage` persistence had shipped earlier | Nothing to build; the mirroring layer was the live gap |
| Leftover gradient blobs over the hero photo | True | Deleted, single linear wash, seams blended |
| White **and** cream in use inconsistently | True, three shades including the body gradient | Unified across four files |
| AA still passes on the new tint | Not assumed | 30 measured failures → **0** (151 EN / 145 AR elements) |
| Duplicate `عربي` in the toggle label | Already fixed — chip reads *Oman*, one button | None |
| Empty `<img src="">` for the fishermen photo | Already fixed — real `webp` src | None |
| Footer Changelog → `#top` | Already fixed — points at the repository `CHANGELOG.md` | None |
| Stats render literal `0` in the source | Already fixed — markup carries `12+ / 50+ / 24/7 / 100%`, JS only counts up | None |
| `ثمد` wrong for Yellowfin Tuna | Correct but indefinite | Now `الثمد`, matching the catalogue |
| `عقرب` ("scorpion") for Grouper | Never on this page — it is `الهامور` | None |
| `فراخ` ("chicks") for Snapper | Never on this page — Latin *Lutjanus* stands in, with the reason printed on the tile | None |
| `قرفص` for Barracuda, unverified | The catalogue says **القد** | `القد` kept; the brief's suggestion was wrong, not unconfirmed |

**RTL evidence** — rect-collision probe (pairwise leaf-text intersection > 45 % of the smaller box)
plus overflow and computed-style checks, EN and AR at 1600 px and 390 px: **0 collisions** and no
horizontal scroll in any of the four, arrows flip (`matrix(-1, 0, 0, 1, 0, 0)`), the dense
live-conditions / trip-planner / catch-log mockups stay pinned `dir="ltr"` on purpose, and stats
numerals are Western — the Gulf convention, confirmed as a choice rather than an oversight.
Captured English/Arabic pairs for the hero, a feature pillar and the species grid.

### 🗺️ Landing page — the fishing coast, plus a fix / i18n / motion pass (2026-09-20)

Four separate commits: `fix(website)`, `feat(i18n)`, `feat` (regions section), `perf(motion)`.

**Added**
- **`#regions` — "Six governorates, six different fisheries"**: a new full-bleed chapter between
  Species intelligence and the closing CTA. Musandam → Al Batinah → Muscat → A'Sharqiyah →
  Al Wusta → Dhofar, written from the verified reference table only: no invented coordinates,
  permit fees or catch limits, the Dhofar season worded as "usually counted … confirm the current
  year", and both protected reserves (Daymaniyat, Hallaniyat) referred to MAFWR rather than
  restated as rules, tied to the existing Legal Compliance / chart features.
- **Interactive coastline chart, not six cards**: governorate outlines projected Web Mercator from
  an ADM-1 geojson at ~440 m tolerance into a 51.4–61.2 E / 15.9–27.1 N frame, with 2° graticule,
  named water bodies, a latitude-true scale bar, dashed reserve rings drawn explicitly as symbols,
  and the six regions pinned north-to-south. The chart is sticky while the chapters scroll and both
  directions are coupled — tapping a governorate jumps to its chapter, and an IntersectionObserver
  tints whichever chapter is in view. Every pin is a real anchor and every chapter stays in the DOM,
  so the section navigates with no JavaScript at all.
- **Regions links** in the desktop nav, the slide-out menu and the footer Product list; the nav and
  footer dictionaries now resolve by `href` instead of by child index, so adding an item cannot
  silently shift a translation onto the wrong link.

**Motion** — reveals trimmed from 34 px / 0.9 s to 30 px / 0.66 s, which is also the distance the
no-JS CSS state uses and the two previously disagreed about; the six feature chapters now alternate
their slide side (mirrored under RTL) instead of every block rising identically; and
`prefers-reduced-data` now drops the full-viewport grain layer, the glare and glow, the button
shine and all scroll-linked parallax — but not the photographs, because the page ships no
lower-resolution variant to degrade to and says so in the stylesheet.

**Before → after, per section**

| Section | Before | After |
|---|---|---|
| Utility bar | Toggle printed the word "عربي" twice in one label; a decorative flag sat next to it | Flag chip reads *Oman*, the toggle is a single `<button>` with an `aria-label`, and its state is kept in `localStorage` |
| Hero | `<img src="">` — the Musandam photograph never loaded, only the CSS waves | Real 274 KB photograph with parallax, a documented reason for shipping no hero clip, and a `prefers-reduced-data` branch |
| Stats | Counters rendered `0` before script executed | Real values in the markup (`12+`, `50+`, `24/7`, `100%`), counted up on reveal |
| Species | Hammour and Grouper listed as two animals; `عقرب`/`فراخ` guesses; symmetric 4×2 | Duplicate merged into an editorial tile that says why, names taken from `lib/core/constants/fish_species.dart`, *Lutjanus* printed instead of guessing a snapper name |
| Regions | Absent — the site named three spots and no geography | New chapter, six governorates, coastline chart |
| CTA | An orphaned unheaded "General instructions…" paragraph in the footer | `Before you go` aside under the CTA, with the MAFWR link and the limits of what the app decides |
| Footer | Changelog link pointed at `#top` | Points at the repository CHANGELOG; privacy/terms verified serving; honest Arabic-coverage note added |
| `map-mockup.html` | White tile grid under a coloured overlay, green/amber/purple markers, attribution removed, dead `Filter ▾` `<div>` | Sea-toned canvas, desaturated tiles, teal/sand palette, OpenStreetMap attribution restored, working species filter |

**Section 8 — button & UX audit, completed**

| Element | Expected behaviour | Verified? |
|---|---|---|
| Nav: Why Oman / Features / Species / Regions / Get Access | Scrolls to the correct anchor | ✅ All five resolve (46 links on the page, zero dead). Anchored sections now clear the fixed header via `scroll-margin-top` |
| Language toggle | Actually switches language + RTL | ✅ Switches `dir`/`lang`, mirrors arrows, keeps the choice across reloads; every headline and paragraph translated, device mockups pinned LTR with the gap stated on the page |
| Hero "Get Early Access" | Submits email, shows success state | ✅ Re-verified after the redesign: success row shows, invalid-address alert is localised |
| Live-conditions "Plan this trip →" | Goes to trip planner / `#access` | ⚠️ By design. It is text inside the hero phone mock, which is `role="img"` artwork — an illustration of the app, not a control. Reported rather than wired to a half-fictional tap target |
| Each feature section's "Explore ___ →" | Resolves to a real destination | ✅ All six reach `#access`; the two new coast links reach `#pillar-live` / `#pillar-charts`, whose ids were created so they could not be dead |
| Footer Product / Resources / Legal | Every link resolves | ✅ Changelog fixed (was a no-op `#top`); `privacy.html` and `terms.html` confirmed present and serving 200 |
| Trip planner Back / Next | Changes state if interactive | ⚠️ Preview artwork inside the wizard mock (`role="img"`); the real wizard is the Flutter screen |
| "Set a bite alert" | Real action or clearly a preview | ⚠️ Same: drawn inside the live-conditions mock, not tappable |
| "＋ Add document" | Real action or clearly a preview | ⚠️ Same: drawn inside the wallet mock, not tappable |
| "Call now" | `tel:` if real, not tappable-but-broken if mock | ✅ Not clickable (mock artwork), so it cannot be broken. The one genuinely interactive control on the mock page — the species `Filter` — was a dead `<div>` and is now a working `<button>` |

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

### 🔄 Changed
- **Maps migrated from Google Maps to MapLibre GL + OpenFreeMap** (Master Build Prompt v3 §2/§3.5):
  removed `google_maps_flutter`, added `maplibre_gl ^0.27`; rewrote `fishing_map_screen.dart` to a
  `MapLibreMap` (keyless `positron` style) rendering probability-coloured hotspot circles via the
  controller's circle API; repointed `LatLng` imports in `hotspots_provider`/`firestore_service`.
  Deleted the Android Maps `meta-data` (`MAPS_API_KEY`), `play-services-maps` dependency and
  Google Maps ProGuard rules. Raised the SDK floor to Flutter 3.29 / Dart 3.7 (v3 §3.0). No maps
  API key is required anymore. **Verified via `flutter_ci.yml`** (no local Flutter SDK).

### 📚 Documentation
- Consolidated the four overlapping specification docs into a single unified
  **[SPECIFICATION.md](SPECIFICATION.md)** and rewrote **[README.md](README.md)** to the canonical
  structure (removed un-implemented overclaims, fixed dead links).
- Added **[QA_REPORT.md](QA_REPORT.md)** (test matrix, security/secret scan, deferred items).
- Reconciled `SPECIFICATION.md`/`README`/`.env.example` against the authoritative **Master Build
  Prompt v3 (Final)**: named v3 as governing, documented the MapLibre/OpenFreeMap-vs-Google-Maps
  and missing-dependency gaps (§2.2), and added v3 env names (`ML_API_TOKEN`,
  `COPERNICUS_MARINE_USERNAME/PASSWORD`) with `GOOGLE_MAPS_API_KEY` demoted to transitional.

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
