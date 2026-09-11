# BAHHAR — Uncompleted Tasks

Last updated: 2026-09-11 (Phase 2, part 1)

## 🔴 Blockers requiring manual action (config / credentials)

- [ ] **Firebase config files are missing from the repo** (intentionally not
      faked):
  - `android/app/google-services.json`
  - `ios/GoogleService-Info.plist` (note: no full iOS runner project exists in
    the repo yet — only `ios/Runner/Info.plist`)
  - `lib/firebase_options.dart` — run `flutterfire configure` and it will
    generate this; then swap `Firebase.initializeApp()` in
    `lib/core/services/firebase_service.dart` to
    `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
  - Until then the app runs in a visible offline-demo mode (bundled sample
    data + warning banners). Auth/Firestore/Storage throw
    `FirebaseUnavailableException` instead of silently failing.
- [ ] **Google Maps API key** — the Android manifest reads
    `${MAPS_API_KEY}` from gradle properties. Add `MAPS_API_KEY=...` to
    `android/local.properties` (git-ignored) or `gradle.properties`. Without
    it the map renders blank tiles.
- [ ] Enable **Phone auth, Google and Apple providers** in the Firebase
      console; Google Sign-In on Android also needs the SHA-1 debug/release
      fingerprints added to the Firebase project.
- [ ] iOS: generate the full runner project (`flutter create --platforms=ios .`
      in a scratch dir, or via Xcode) — GoogleService-Info.plist and the
      Apple entitlement (`sign_in_with_apple`) go there.

## 🟡 Phase 2 remaining (planned next commits)

- [ ] **Part 2 — Visual redesign**: replace the current navy/corporate-blue
      palette in `app_colors.dart`/`app_theme.dart` with the natural ocean
      palette (deep teal `#0E6E6B`, seafoam `#6FC8B8`, warm sand `#E3A857`,
      coral `#E8694A`, cream `#FBF8F3`, charcoal ink `#24333E`), keeping the
      green/amber/red probability scale for map legend/hotspot cards. Sand
      tone for primary CTAs; soft low-opacity card shadows; custom-painted
      animated probability ring; Cairo font setup (download TTFs into
      `assets/fonts/`, register in `pubspec.yaml`, wire into
      `app_text_styles.dart`).
- [ ] **Part 3 — Motion**: add `flutter_animate` + `shimmer` to pubspec;
      splash logo fade+scale; go_router `CustomTransitionPage` fade-through
      (<250 ms) on top-level routes; animate gauge fill 0→value on first
      load; stagger species chips/hotspot tiles; swap `SkeletonBox`/
      `SkeletonCard` to shimmer (`lib/shared/widgets/skeleton.dart` is the
      single place to change); success check animation on Save Catch; subtle
      pulsing glow (animated `Circle` overlays) on map markers with
      probability ≥ 70.

## 🟢 Functional debt / TODOs in code

- [ ] `lib/core/services/firestore_service.dart` — `fetchHotspots` filters
      client-side; move to geohash range queries when the hotspot collection
      grows.
- [ ] `lib/core/services/trip_service.dart` — `planTrip()` is a deterministic
      heuristic mock; replace with the real ML backend endpoint (TODO marked
      in code). `TripRecommendation.isMock` drives a visible UI disclosure
      until then.
- [ ] Email/password sign-in is intentionally not wired (provider disabled in
      Firebase console); the login screen explains this in-app.
- [ ] Language preference & preferences generally are not persisted with
      `shared_preferences` yet (`preferences_provider.dart` state is
      session-only).
- [ ] Guest mode data (catches added while signed out) lives in memory only;
      consider a local queue that syncs to Firestore after sign-in.
- [ ] Notifications are a static seed list; wire to FCM
      (`firebase_messaging` is already a dependency) and
      `users/{uid}/notifications`.
- [ ] Tests: only unit tests + shared-widget tests are real; the per-screen
      widget tests are empty placeholders.
- [ ] Catch photos: add compression/resize before Storage upload for large
      gallery images (image_picker already caps at 1600 px / q82, but a
      background isolate resize would be safer).
