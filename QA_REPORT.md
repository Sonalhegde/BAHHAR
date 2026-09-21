# BAHHAR — QA, Testing & Debugging Report

**Pass:** `qa-testing-docs-cleanup` · **Date:** 2026-09-19 · **Scope:** Part A of the
QA/Testing/Docs/Cleanup specification.

## 0. Environment constraints (affect what could be executed vs deferred)

| Capability | Available? | Consequence |
| :-- | :-- | :-- |
| Python 3.13 + pytest | ✅ | Backend suite fully executed |
| Node 24 (vercel CLI) | ✅ (logged **out**) | Deploy attempted, blocked at OAuth |
| Flutter / Dart SDK | ❌ not installed | `flutter test`, `analyze`, `dart format`, device runs **cannot** execute locally — delegated to CI (`flutter_ci.yml`) |
| Netlify CLI | ❌ not installed | Netlify path requires token |
| gh CLI | ✅ authenticated | Push + PR possible |

Per the spec ("skip sections that don't apply and say so explicitly"), Flutter runtime QA
(A.2 screen runs, A.3 widget tests, A.4 device matrix, A.5 jank profiling) is **deferred to CI /
a Flutter-equipped machine** rather than faked here.

---

## A.1–A.2 Test matrix (executed where possible)

| Area | Test case | Expected | Actual | Status | Severity |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Backend | `GET /` health | 200, `status:online` | pass | ✅ Pass | — |
| Backend | `POST /predict` kingfish optimal | prob ≥75, conf >0.8 | pass | ✅ Pass | — |
| Backend | `POST /geofence/verify` Daymaniyat | `Protected`, decree 23/96 | pass | ✅ Pass | — |
| Backend | Tide derivation from extremes (rising) | `Rising`, interp height | pass | ✅ Pass | — |
| Backend | Tide derivation (high water ≤45 min) | `High` | pass | ✅ Pass | — |
| Backend | Marine proxy (mocked upstreams) | correct kt conversion, `cached:false`→`true` | pass | ✅ Pass | — |
| Backend | Marine proxy w/ tides | `Rising` / `WorldTides` | pass | ✅ Pass | — |
| Backend | Upstream failure | HTTP **502** | pass | ✅ Pass | major-path |
| Backend | `/tides` without key | HTTP **503** | pass | ✅ Pass | — |
| Backend | Server-side TTL cache (no 2nd upstream hit) | 2nd call served from cache | pass (asserted via `_boom`) | ✅ Pass | — |
| Landing | Pillars alternate L/R (desktop) | media side flips per section | fixed to `order:-1` (prior pass) | ✅ Pass | major |
| Landing | Sticky header transparent→frosted | on scroll | pass (browser verified prior pass) | ✅ Pass | minor |
| Landing | Mobile hamburger opens/closes | 44px targets, slide-out | pass | ✅ Pass | minor |
| Landing | EN ⇄ AR RTL toggle | swaps copy + direction | pass | ✅ Pass | minor |
| Landing | Species grid = 8 distinct silhouettes | anatomically distinct | pass | ✅ Pass | minor |
| Landing | Console clean / no errors | no uncaught errors | pass | ✅ Pass | — |
| Landing | Image 404 → CSS fallback | no broken-photo frames | pass (`onerror` hides img) | ✅ Pass | minor |
| Security | Firestore per-user isolation | non-owner read/write rejected | rules checked on both `resource`/`request.resource` | ✅ Pass (static) | major |
| Security | Reference collections read-only | `write: if false` | present | ✅ Pass | — |
| Security | No secrets tracked | `.env`/keys absent from git | `git log .env` empty; key only in gitignored `.env` | ✅ Pass | blocker-if-fail |
| Docs | No dangling links to deleted docs | 0 broken refs | grep → 0 | ✅ Pass | minor |
| Flutter | `flutter test` / `analyze` / format | pass in CI | **not run locally (no SDK)** | ⏭ Deferred | — |

**Automated result actually observed:** `cd backend; python -m pytest tests -q` →
**`9 passed, 1 warning in 11.41s`** (warning = unrelated Starlette/httpx TestClient deprecation).

---

## A.3 Automated coverage
- **Backend:** 9 pytest cases incl. mocked success **and** mocked failure/timeout for each
  external integration (Open-Meteo marine, WorldTides) — confirms the 502/503 error paths fire.
  All upstreams monkeypatched → suite is offline/CI-safe. ✅
- **Website:** no framework-based E2E suite exists. Adding Playwright/Cypress here was
  **deferred** — it could not be executed/validated in this environment, and committing an
  unverified harness violates the "don't ship untested changes" rule. Recommend a follow-up PR on
  a toolchain-equipped machine.
- **Flutter widget tests:** existing `test/**` files are placeholder stubs; **deferred** (no SDK).

## A.4 Cross-platform/browser — **Deferred** (no Flutter SDK / single-OS sandbox). Recommend CI
device matrix + Chrome/Safari/Firefox at 375/768/1440 px; specifically re-check `backdrop-filter`
glass rendering on Safari.

## A.5 Performance
- **Re-fetch guard verified (backend):** TTL cache means Open-Meteo/WorldTides are hit at most
  once per window per coordinate; the "second call must not touch upstream" test enforces it. ✅
- Client-side re-fetch on rebuild is prevented by `MarineService` caching last-known — **not
  runtime-profiled** (no SDK), deferred to `--profile` run.
- Landing hero/CTA photos load from CDN with CSS-scene fallback; no multi-MB local assets added.

## A.6 Security & data integrity ✅
- Firestore/storage rules enforce ownership + read-only reference data (see matrix).
- Secret scan: real WorldTides key found **only** in gitignored `backend/.env`/`.env`; never
  committed (`git log --all -- .env` empty). The only key-shaped string in tracked files is the
  `AIzaSy…` **placeholder** in `.env.example`. No `.jks`, `key.properties`, `google-services.json`
  or service-account JSON tracked.
- ⚠️ **Standing note for the key owner:** any key that has ever been shared in plaintext should be
  treated as compromised — **rotate `WORLDTIDES_API_KEY`** in the WorldTides dashboard as a
  precaution. (It was not pushed to the repo.)
- 🟡 **Known, unfixed (MEDIUM):** the landing page loads GSAP from cdnjs without Subresource
  Integrity hashes. Mitigated by an IntersectionObserver fallback (page still works if the CDN
  script is blocked), but `integrity`+`crossorigin` should be added in a follow-up.

## A.7 Accessibility
- Legal status / probability are conveyed with icon+shape, not colour only (verified in code &
  landing SVGs). ✅
- 44×44 px touch targets on mobile nav/hamburger/buttons. ✅
- Contrast of white-on-hero and muted signal tokens: **not** run through Lighthouse/axe in this
  environment → **deferred**; recommend an automated a11y pass and to log the score.

## A.8 Bugs found & fixed (this + immediately-prior pass)
| Bug | Root cause | Fix |
| :-- | :-- | :-- |
| Landing pillars did not alternate | `.pillar.flip .pillar-media{order:2}` no-op (DOM is body→media) | `order:-1` (desktop + RTL); removed mobile override |
| README overclaimed security | Copied aspirational text | Removed "end-to-end encryption"/"certificate pinning" claims (not implemented) |
| Stale roadmap said "tide integration TODO" | Pre-dated the live WorldTides work | Updated: tides implemented; moved to §9 |
| Broken link `backend/README.md` | File never existed | Removed |
| Dangling links to 4 consolidated docs | Files deleted | Re-pointed to `SPECIFICATION.md` |

---

## E. Reconciliation against *Master Build Prompt v3 (Final)* (this pass)
The authoritative v3 prompt was cross-checked line-by-line against the actual code
(`pubspec.yaml`, `lib/`, `backend/main.py`, platform files). v3 supersedes the v1/v2 direction the
repo was scaffolded from, so the consolidated `SPECIFICATION.md`/`README` were corrected to name
v3 as governing and to record the deltas honestly rather than assert Google Maps as canonical.

| v3 requirement | Code reality | Verdict | Action taken |
| :-- | :-- | :-- | :-- |
| §2 Maps = **MapLibre GL + OpenFreeMap**, keyless, "no Google Maps SDK" | **Migrated this pass** — `google_maps_flutter` removed, `maplibre_gl ^0.27` added; map + `LatLng` imports rewritten; Android Maps key/dep/ProGuard deleted | ✅ Resolved | Pending CI verify (no local Flutter SDK) |
| §3.1 deps `dio`, `freezed`/`json_serializable`, `flutter_dotenv`, `riverpod_annotation`, `flutter_launcher_icons` | client uses `http` + hand-written JSON + plain `flutter_riverpod` | ✅ Accepted | v3 status log: equally valid — **not** migrated (leave working code alone) |
| §3.2 `.env`: `ML_API_TOKEN`, `COPERNICUS_MARINE_*` | `.env.example` had `ML_API_AUTH_TOKEN`, no Copernicus, `GOOGLE_MAPS_API_KEY` required | ✅ Reconciled | `.env.example` updated to v3 names; Maps key removed entirely (keyless) |
| §9 cache 3rd-party responses server-side | in-memory TTL cache in `main.py` | ✅ Satisfied | Firestore persistence noted as enhancement |
| §9 offline last-known + "last updated" | `MarineService` stale replay + Home banner | ✅ Done | — |
| §5 design system (Premium White), §6 10 screens, nav | implemented | ✅ Match | — |
| §9 accessibility icon/shape, Riverpod-only | implemented | ✅ Match | — |

**Decision:** the MapLibre code migration is **executed this pass** (v3 status log confirms it was
an approved, settled decision — leftover `google_maps_flutter` was to be removed, and the
`http`/hand-written-JSON/plain-Riverpod packaging choices are valid and were left untouched).
Because there is **no Flutter SDK in this environment**, the Dart changes cannot be `analyze`/`test`
ed locally; **`flutter_ci.yml` is the verification gate** and will run `dart format`, `flutter
analyze` and `flutter test` on push. Code was written against the verified `maplibre_gl 0.27` API
(`MapLibreMap`, `addCircle(s)`/`clearCircles`/`getCircleLatLng`, `onCircleTapped`, `CircleOptions`).

<!-- v3 reconciliation date: 2026-09-20 -->

---

## Deferred (with reason) — carried into `SPECIFICATION.md §9`
1. All Flutter runtime QA, widget/integration tests, device matrix, profiling — **no SDK locally**.
2. Website E2E harness (Playwright/Cypress) — cannot validate without executing it.
3. Lighthouse/axe accessibility scoring — tooling unavailable in sandbox.
4. Firebase/Google-Maps/auth wiring, `/api/v1/trip/optimize`, geohash queries, persistence,
   FCM handlers — credential-gated or larger feature work.
5. Production deploy verification — **blocked** on Vercel browser authorization / Netlify token.

## D. Checklist
- [x] Test matrix executed & documented here
- [x] Backend blocker/major paths tested & passing (9/9)
- [~] Automated tests: backend done; website/Flutter deferred (reasons above)
- [x] Security check (rules + secret scan)
- [~] Accessibility partial; a11y tooling score deferred
- [x] Docs consolidated into one canonical `SPECIFICATION.md`
- [x] Reconciled against *Master Build Prompt v3*: `SPECIFICATION.md`/`README`/`.env.example` corrected; MapLibre code migration deferred (§E)
- [x] README features/stack/setup/env/deploy verified & corrected
- [ ] Production deploy verified live (awaiting authorization)

---

## Live demo QA — app building pass (2026-09-20)

The same environment constraint applies (no Flutter/Dart SDK, so `flutter test`/`analyze`/`format`
stayed with CI), but this pass **ran the backend against the real upstreams** for the demo, which
is the one QA step a monkeypatched suite cannot substitute.

| Check | Result |
| :-- | :-- |
| `pytest tests/ -q` | **32 passed** (9 at the time of the tables above, 16 before this pass) |
| `GET /api/v1/weather` (live, no key) | 200, `source: open-meteo` — 29.2 °C, feels like 35.8, humidity 80 %, wind 3.2 km/h ESE, visibility 21.7 km, 8 hours + 5 days, `alerts: []` with the reason in `note` |
| `GET /api/v1/marine/conditions` (live) | 200 — SST 31.5 °C, waves 0.5 m from E, period 4.8 s, wind 4 kt, current 0.8 kt setting W, tide Rising 0.47 m, next high 06:55, band **good**, `day_rating` for a 6.7 m open boat on handlines |
| `POST /api/v1/trip/optimize` (live) | 200 — 3 candidates evaluated against those readings, recommended Qurayyat Ridge (score 98.2, 1.9 nm out, 16.6 L, OMR 3.97), `strategy` printed, `conditions` present |
| TTL cache | second identical call → `cached: true` |
| Landing page in a 390 × 844 frame, EN + AR | measured in the DOM rather than by eye (the browser window would not come to the foreground, so screenshots were unavailable): both new section ids exist, the mobile layout is active at this width (`#hamburger` computes `display:flex`), the weather eyebrow reads **"Weather — Open-Meteo, through the BAHHAR backend"** and the Arabic row localises it (`الأحوال الجوية — OPEN-METEO عبر خلفيّة بحّار`), and the ocean/weather panels hold real text — `CURRENT 0.6 kt setting south`, `31 °C · Sunny · feels like 34°`. **Not** verified: pixel-level rendering at this width |

### Bugs this found that the stubbed suite passed
| Bug | Root cause | Fix |
| :-- | :-- | :-- |
| **Ocean readout returned 502 for every request** | the current was wired as `surface_current_eastward/northward`, which Open-Meteo does not publish — and an unknown hourly variable fails the *whole* call, taking waves and SST with it. Every test replaced `_fetch_open_meteo_marine`, so none of them could see the request | use `ocean_current_velocity`/`ocean_current_direction`; a new test asserts the **outgoing** variable list, so a bad name cannot return through a stub |
| Wind 3.6× too strong on live data | km/h values converted with the m/s→kt factor, pushing benign days into the *high risk* band | separate named `KM_PER_HOUR_TO_KNOTS` / `METERS_PER_SECOND_TO_KNOTS`, pinned by tests |
| Guest catches never synced | the queue flushed only when the catches controller was constructed, so signing in mid-session did nothing | `reload()` + an `authProvider` listener |
| Startup could be killed by the push plugin | `NotificationService.init()` caught only `FirebaseException`; an `UnsupportedError` escaped `main()` before `runApp` | broad try/catch, degrade to a log line |

### Known data-quality limit, recorded rather than papered over
Open-Meteo's **visibility** is a model field and is grid-cell sensitive on the coast: two positions
about a kilometre apart at Al Bustan read **0.2 km** and **21.7 km** under the same clear sky. It is
passed through unfiltered — inventing a plausibility test against someone else's model would be its
own lie — but nothing should treat a single low reading as a warning until the field is
cross-checked against a second source. The same discipline applies to the current's sets-toward
bearing, which follows the provider's stated from-convention by inference and is flagged as such in
`backend/main.py`.

### Deferred list, corrected
Item 4 above deferred trip-optimize, geohash, persistence and FCM handlers. **Closed this pass:**
`/api/v1/trip/optimize` (rule-based, not the trained model), `shared_preferences` persistence,
guest queue, FCM handlers, fisherman-profile Firestore writes. **Still deferred, with the reason:**
geohash queries (12 seed hotspots), background-isolate photo compression (needs an unresolvable
dependency), launcher-icon *generation* (configured; no SDK or platform icon tree), and everything
in §0 that needs credentials the user has to supply.
