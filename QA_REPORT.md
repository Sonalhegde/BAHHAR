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
- [x] README features/stack/setup/env/deploy verified & corrected
- [ ] Production deploy verified live (awaiting authorization)
