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

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com/
   - Click "Add project"
   - Name: `bahhar-dev` (or your choice)
   - Enable Google Analytics (optional)

2. **Register Android App**
   - Click "Add app" → Android icon
   - Package name: `com.bahharai.bahhar`
   - App nickname: `BAHHAR Dev`
   - Click "Register app"

3. **Download Configuration**
   - Download `google-services.json`
   - Place in `android/app/google-services.json`

4. **Generate Firebase Options**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure --project=bahhar-dev
   ```
   
   This creates `lib/firebase_options.dart`

5. **Enable Firebase Services**
   
   In Firebase Console:
   - **Authentication** → Enable:
     - Phone (requires billing)
     - Google
     - Anonymous
   - **Firestore Database** → Create database (start in test mode for dev)
   - **Storage** → Get started
   - **Cloud Messaging** → Enable

6. **Deploy Security Rules (Optional for Dev)**
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init
   firebase deploy --only firestore:rules
   firebase deploy --only storage:rules
   ```

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
- Enable auth methods in Firebase Console
- Add SHA-1 for Google Sign-In
- Enable billing for Phone auth

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
- [CLIENT_ARCHITECTURE_AND_FEATURE_SPECIFICATION.md](CLIENT_ARCHITECTURE_AND_FEATURE_SPECIFICATION.md) - Architecture
- [UNCOMPLETED_TASKS.md](UNCOMPLETED_TASKS.md) - Known issues and TODOs

### Community
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [GitHub Discussions](https://github.com/flutter/flutter/discussions)

---

## Getting Help

### Internal
- Check existing documentation first
- Review [UNCOMPLETED_TASKS.md](UNCOMPLETED_TASKS.md)
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
