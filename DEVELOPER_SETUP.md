# BAHHAR Developer Setup Guide

Complete guide for setting up the BAHHAR development environment.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Setup](#detailed-setup)
4. [IDE Configuration](#ide-configuration)
5. [Running the App](#running-the-app)
6. [Common Issues](#common-issues)

---

## Prerequisites

### Required Software

#### Flutter Development
- **Flutter SDK**: 3.24.0 or higher
  - Download: https://docs.flutter.dev/get-started/install
- **Dart SDK**: 3.5.0+ (bundled with Flutter)
- **Git**: For version control

#### Android Development
- **Android Studio**: Latest stable (Hedgehog 2023.1.1+)
  - Download: https://developer.android.com/studio
- **Android SDK**: API 34 (Android 14)
- **Java Development Kit (JDK)**: Version 17 or higher

#### Python Development (Backend)
- **Python**: 3.11 or higher
  - Download: https://www.python.org/downloads/
- **pip**: Python package manager (bundled with Python)

#### Optional but Recommended
- **VS Code** with Flutter/Dart extensions
- **Postman** or **Insomnia** for API testing
- **Firebase CLI** for deploying rules
- **Docker** for containerized backend

### Account Setup

You'll need accounts for:
- **GitHub** (to clone the repository)
- **Firebase** (for backend services)
- **Google Cloud Platform** (for Maps API)
- **Google Play Console** (for publishing - $25 one-time fee)

---

## Quick Start

For developers who already have Flutter and Android Studio set up:

```bash
# Clone the repository
git clone https://github.com/Sonalhegde/BAHHAR.git
cd BAHHAR

# Install Flutter dependencies
flutter pub get

# Check Flutter setup
flutter doctor

# Run the app in debug mode (demo mode - no Firebase)
flutter run

# Backend (optional for mobile dev)
cd backend
pip install -r requirements.txt
pytest tests/ -v
uvicorn main:app --reload
```

The app will run in **demo mode** with simulated data until Firebase is configured.

---

## Detailed Setup

### 1. Install Flutter

#### Windows
```powershell
# Download Flutter SDK
# Extract to C:\src\flutter
# Add to PATH: C:\src\flutter\bin

# Verify installation
flutter --version
flutter doctor
```

#### macOS
```bash
# Using Homebrew
brew install flutter

# Or download from flutter.dev
# Extract to ~/flutter
# Add to PATH in ~/.zshrc or ~/.bash_profile
export PATH="$PATH:$HOME/flutter/bin"

# Verify installation
flutter --version
flutter doctor
```

#### Linux
```bash
# Download and extract Flutter SDK
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
tar xf flutter_linux_3.24.0-stable.tar.xz

# Add to PATH in ~/.bashrc
export PATH="$PATH:$HOME/flutter/bin"

# Verify installation
flutter --version
flutter doctor
```

### 2. Install Android Studio

1. Download from https://developer.android.com/studio
2. Run installer and follow setup wizard
3. Install Android SDK Platform-Tools
4. Install Android SDK Build-Tools
5. Accept Android licenses:
   ```bash
   flutter doctor --android-licenses
   ```

### 3. Set Up Android Emulator

#### In Android Studio:
1. Tools → Device Manager
2. Click "Create Device"
3. Select device (e.g., Pixel 7)
4. Select system image (API 34 - Android 14)
5. Click "Finish"
6. Launch the emulator

#### Or use a physical device:
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect via USB
4. Run `flutter devices` to verify

### 4. Clone and Configure Project

```bash
# Clone repository
git clone https://github.com/Sonalhegde/BAHHAR.git
cd BAHHAR

# Install dependencies
flutter pub get

# Verify everything is set up
flutter doctor -v
```

### 5. Firebase Setup (Required for Full Functionality)

#### Option A: Skip for Now (Demo Mode)
The app will run with simulated data. Skip to [Running the App](#running-the-app).

#### Option B: Configure Firebase

The project this repo is wired to is **`bahar-3719a`** — `bahar` is only the console display name,
the ID is in the `project_id` field of the service-account JSON. The steps below are for a project
of your own; they are identical apart from the IDs.

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com/
   - Click "Add project"
   - Name: `bahhar-dev` (or your choice)
   - Enable Google Analytics (optional)
   - **Do not attach a billing account.** Nothing below needs one, and two of the services the app
     used to assume (Cloud Storage, Phone auth) are the ones that do — see step 5.

2. **Register Android App**
   - Click "Add app" → Android icon
   - Package name: `com.bahharai.bahhar` (must match `android/app/build.gradle` exactly)
   - App nickname: `BAHHAR Dev`
   - Click "Register app"

3. **Download Configuration**
   - Download `google-services.json`
   - Place in `android/app/google-services.json` (gitignored)
   - The `com.google.gms.google-services` plugin is **applied** in `android/app/build.gradle`, so it
     reads that file at build time — which is what lets the option-less `Firebase.initializeApp()` in
     `lib/core/services/firebase_service.dart` find the project on Android. It also means the Gradle
     build **fails** until the file exists, rather than quietly running unconfigured.

4. **`flutterfire configure` is optional**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<your-project-id>
   ```

   It writes `lib/firebase_options.dart`, which **nothing in `lib/` imports** — the app is configured
   by the native file from step 3 (`ios/Runner/GoogleService-Info.plist` on iOS). Run it only if you
   prefer explicit options; `firebase_options.dart` is gitignored either way.

5. **Enable Firebase Services**
   
   In Firebase Console:
   - **Authentication** → Sign-in method → enable the three the login screen actually offers:
     - **Email/Password** — the only non-social method, and the one that costs nothing
     - **Google** (add the SHA-1 fingerprint from step 2's app)
     - **Apple** (needs an Apple developer account, so expect this one to stay off in dev)
     - *Phone:* leave it off. `sendOtp`/`verifyOtp` are still implemented in
       `lib/features/auth/data/auth_repository.dart` but no longer reachable from the UI — Phone auth
       has required Blaze since September 2024. Re-enabling it is one console switch plus re-adding
       the widget, not a rewrite. *Anonymous* is not used.
   - **Firestore Database** → Create database, **production mode**. Test mode opens every collection to
     any signed-in client; `firestore.rules` in this repo is the version that should be live.
   - **Storage** → nothing to create. Catch photos go to **Supabase** instead (step 7) because Cloud
     Storage sits behind Blaze at any volume; `storage.rules` is kept in the repo but inactive.
   - **Cloud Messaging** → Enable (used by `lib/core/services/notification_service.dart`)

6. **Deploy Security Rules and Indexes**
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase deploy --only firestore:rules,firestore:indexes
   ```

   **Skip `firebase init`.** `firebase.json`, `.firebaserc` and `firestore.indexes.json` are committed,
   so the CLI already knows the project and the rule files — running init would offer to overwrite the
   reviewed `firestore.rules` / `storage.rules` with a scaffold.

   The index is not optional housekeeping: `fetchCatchesForUser` runs
   `where('userId') + orderBy('caughtAt', descending:)`, and an equality paired with a sort needs a
   composite index. Without it live Firestore answers `FAILED_PRECONDITION` and the catch log is empty
   for every user. Every other query in the app is a plain document read.

   Do not deploy `--only storage:rules` — there is no bucket for it to attach to.

7. **Seed the Reference Collections**
   ```bash
   cd backend
   pip install -r requirements.txt
   python seed_firestore.py ..\path\to\service-account-key.json
   ```

   Generate the service-account key under *Project settings → Service accounts* and keep it **outside
   the repo**. Two things to know about this script:
   - It catches `ImportError` and falls back to a *dry run*, so a missing `firebase-admin` looks like
     success. The output must say it wrote documents, not `[DRY RUN]`.
   - It writes `regions`, `species` and `hotspots`. There is **no `regulations` data** in
     `firestore_seed.json`, so that collection stays empty until real Omani regulations are sourced —
     it is not guessed at.

8. **Photo Storage (Supabase)**

   Create a Supabase project, add a bucket named **`bahhar-uploads`** with public read, then pass the
   client config at build time:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
               --dart-define=SUPABASE_ANON_KEY=<anon-key>
   ```
   With nothing set, uploads fail visibly (`SupabaseStorageService.isConfigured` is false) and the
   catch still saves without its photo — see `lib/core/services/supabase_storage_service.dart`.

> **What a service-account key cannot do.** It writes documents and can *create* a Firebase Rules
> ruleset, but releasing that ruleset and creating Firestore indexes are refused (403) — those need
> `firebase login` as a project owner, i.e. step 6 above run by a human.

### 6. Google Maps API Key

1. **Create GCP Project**
   - Go to https://console.cloud.google.com/
   - Create new project: `bahhar-dev`

2. **Enable APIs**
   - APIs & Services → Library
   - Enable "Maps SDK for Android"

3. **Create API Key**
   - APIs & Services → Credentials
   - Create Credentials → API Key
   - Note the key (e.g., `AIzaSy...`)

4. **Restrict API Key** (Important!)
   - Click on the key
   - Application restrictions → Android apps
   - Add package name: `com.bahharai.bahhar`
   - Get SHA-1 fingerprint:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore \
       -alias androiddebugkey -storepass android -keypass android
     ```
   - Add SHA-1 to restrictions
   - API restrictions → Restrict key
   - Select "Maps SDK for Android"
   - Save

5. **Configure in Project**
   
   Create `android/local.properties`:
   ```properties
   sdk.dir=/path/to/Android/sdk
   flutter.sdk=/path/to/flutter
   MAPS_API_KEY=AIzaSy...your_key_here
   ```

### 7. Backend Setup (Optional)

```bash
# Navigate to backend
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest tests/ -v

# Start server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Backend will be available at http://localhost:8000

---

## IDE Configuration

### VS Code

#### Install Extensions
1. Flutter (by Dart Code)
2. Dart (by Dart Code)
3. Python (by Microsoft)
4. Pylance (by Microsoft)

#### Recommended Settings (.vscode/settings.json)
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "editor.formatOnSave": true,
  "editor.rulers": [80, 120],
  "dart.lineLength": 80,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.formatOnSave": true
  },
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black"
}
```

### Android Studio

#### Install Plugins
1. File → Settings → Plugins
2. Install:
   - Flutter
   - Dart
   - Python (if doing backend work)

#### Configure Flutter SDK
1. File → Settings → Languages & Frameworks → Flutter
2. Set Flutter SDK path
3. Apply and OK

---

## Running the App

### Debug Mode (Development)

```bash
# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# Run with specific device
flutter run -d <device_id>

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R'
# Open DevTools: Press 'h'
# Quit: Press 'q'
```

### With Firebase (if configured)
```bash
# Run normally - Firebase will initialize
flutter run
```

### Without Firebase (Demo Mode)
```bash
# App automatically detects missing Firebase
# Shows demo data and warning banners
flutter run
```

### Release Mode (Testing Production Build)

```bash
# Build and run release APK
flutter build apk --release
flutter install --release

# Or build App Bundle
flutter build appbundle --release
```

### Backend (Separate Terminal)

```bash
cd backend
python -m uvicorn main:app --reload
```

---

## Development Workflow

### 1. Starting a New Feature

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes
# Test thoroughly

# Commit
git add .
git commit -m "feat: add your feature description"

# Push
git push origin feature/your-feature-name

# Create Pull Request on GitHub
```

### 2. Running Tests

```bash
# Flutter tests
flutter test

# Backend tests
cd backend
pytest tests/ -v

# Flutter analyze (linting)
flutter analyze

# Format code
dart format .
```

### 3. Debugging

#### Flutter
```bash
# Run in debug mode
flutter run --debug

# Open DevTools
flutter pub global activate devtools
devtools

# View logs
flutter logs
```

#### Backend
```python
# Add breakpoints in code
import pdb; pdb.set_trace()

# Or use VS Code debugger
# Create .vscode/launch.json
```

### 4. Hot Reload vs Hot Restart

- **Hot Reload (`r`)**: Preserves state, updates UI
- **Hot Restart (`R`)**: Resets state, rebuilds everything
- **Full Restart**: Stop and `flutter run` again

---

## Common Issues

### Flutter Doctor Issues

#### Android licenses not accepted
```bash
flutter doctor --android-licenses
```

#### Unable to locate Android SDK
```bash
# Set ANDROID_HOME environment variable
# Windows:
setx ANDROID_HOME "C:\Users\YourUser\AppData\Local\Android\Sdk"

# macOS/Linux:
export ANDROID_HOME=$HOME/Android/Sdk
```

### Build Errors

#### Gradle sync failed
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### Google Services plugin error
Make sure `google-services.json` is in `android/app/` (not `android/`)

### Maps Not Rendering

#### Blank map tiles
- Verify `MAPS_API_KEY` in `android/local.properties`
- Check API key restrictions in Cloud Console
- Ensure SHA-1 fingerprint is added
- Verify Maps SDK for Android is enabled

#### Maps crashing app
- Check logcat: `flutter logs`
- Verify package name matches everywhere
- Ensure API key has no typos

### Firebase Issues

#### FirebaseUnavailableException
This is normal in demo mode. Add `google-services.json` to fix.

#### Auth not working
- Enable the provider you are using under Authentication → Sign-in method. The screen offers
  Email/Password, Google and Apple; with Email off, Firebase returns `operation-not-allowed` and the
  app names that switch rather than looking like a bad password.
- Add SHA-1 for Google Sign-In
- Sign-in then fails to persist data? Check the rules are deployed — a live deny-all ruleset signs you
  in successfully and rejects every read afterwards, which looks like an auth bug and is not one.
- Phone OTP is not on the screen. It needs Blaze; see §5 step 5.

#### Catch log is empty for a signed-in user
Not an auth failure. `catches` needs the `userId` / `caughtAt` composite index from
`firestore.indexes.json`; without it the query is rejected with `FAILED_PRECONDITION`. Deploy with
`firebase deploy --only firestore:indexes`.

### Backend Issues

#### Port 8000 already in use
```bash
# Find and kill process
# Windows:
netstat -ano | findstr :8000
taskkill /PID <pid> /F

# macOS/Linux:
lsof -ti:8000 | xargs kill -9
```

#### Import errors
```bash
# Ensure virtual environment is activated
# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### Performance Issues

#### Slow build times
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### App laggy on emulator
- Allocate more RAM to emulator (4GB+)
- Enable hardware acceleration
- Use physical device for better performance

---

## Tips & Best Practices

### Development
- Use `debugPrint()` instead of `print()`
- Run `flutter analyze` before committing
- Write tests for new features
- Keep dependencies up to date: `flutter pub outdated`

### Git Workflow
- Commit often with descriptive messages
- Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Never commit secrets or API keys
- Keep `.gitignore` updated

### Testing
- Test on multiple devices/screen sizes
- Test offline functionality
- Test different network conditions
- Use Flutter DevTools for performance profiling

### Code Quality
- Follow Dart style guide
- Use `dart format` before committing
- Keep functions small and focused
- Document public APIs

---

## Additional Resources

### Official Documentation
- [Flutter Docs](https://docs.flutter.dev/)
- [Dart Docs](https://dart.dev/guides)
- [Firebase Docs](https://firebase.google.com/docs)
- [Google Maps Platform](https://developers.google.com/maps)

### Project Documentation
- [README.md](README.md) - Project overview
- [ANDROID_PUBLICATION_GUIDE.md](ANDROID_PUBLICATION_GUIDE.md) - Publishing guide
- [SPECIFICATION.md](SPECIFICATION.md) - Unified master specification (architecture, features, status & roadmap)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [GitHub Discussions](https://github.com/flutter/flutter/discussions)

---

## Getting Help

### Internal
- Check existing documentation first
- Review [SPECIFICATION.md](SPECIFICATION.md) §9 (Implementation Status & Roadmap)
- Ask team members

### External
- Stack Overflow with `flutter` and `dart` tags
- Flutter Discord/Reddit communities
- GitHub Issues for Flutter SDK issues

### Support
- **Email**: support@bahharai.com
- **GitHub Issues**: https://github.com/Sonalhegde/BAHHAR/issues

---

**Happy Coding! 🚀**

---

**Last Updated**: September 15, 2026  
**Document Version**: 1.0  
**Maintained by**: BAHHAR Development Team
