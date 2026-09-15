# BAHHAR Android Publication Guide

This comprehensive guide walks through the complete process of preparing and publishing the BAHHAR app to the Google Play Store.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase Setup](#firebase-setup)
3. [Google Maps API Configuration](#google-maps-api-configuration)
4. [App Signing](#app-signing)
5. [Build Configuration](#build-configuration)
6. [Testing](#testing)
7. [Play Store Preparation](#play-store-preparation)
8. [Publishing Process](#publishing-process)
9. [Post-Publication](#post-publication)

---

## 1. Prerequisites

### Required Tools

- **Flutter SDK**: Version 3.24.0 or higher
- **Android Studio**: Latest stable version
- **Java Development Kit (JDK)**: Version 17 or higher
- **Google Cloud Console** account
- **Firebase Console** account
- **Google Play Console** account (requires $25 one-time registration fee)

### Verify Installation

```bash
flutter --version
flutter doctor -v
java -version
```

---

## 2. Firebase Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or select existing project
3. Enter project name: `BAHHAR` or `bahhar-production`
4. Enable Google Analytics (optional but recommended)
5. Click **"Create project"**

### Step 2: Register Android App

1. In Firebase Console, click **"Add app"** → Select Android icon
2. Enter package name: `com.bahharai.bahhar` (must match `applicationId` in `android/app/build.gradle`)
3. Enter app nickname: `BAHHAR Android`
4. Enter SHA-1 certificate fingerprint (see below)
5. Click **"Register app"**

### Step 3: Get SHA-1 Fingerprints

#### Debug SHA-1 (for development)
```bash
cd android
./gradlew signingReport
```

Or using keytool:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Release SHA-1 (for production)
```bash
keytool -list -v -keystore upload-keystore.jks -alias upload
```

Copy both SHA-1 fingerprints and add them to Firebase project settings.

### Step 4: Download Configuration Files

1. Download `google-services.json`
2. Place it in `android/app/google-services.json`
3. **Never commit this file to Git** (already in `.gitignore`)

### Step 5: Enable Firebase Services

In Firebase Console, enable:

- **Authentication**
  - Phone authentication (requires enabling billing)
  - Google Sign-In
  - Apple Sign-In (requires Apple Developer account)
  - Anonymous authentication (for guest mode)

- **Cloud Firestore**
  - Start in production mode
  - Deploy security rules from `firestore.rules`

- **Cloud Storage**
  - Start in production mode
  - Deploy security rules from `storage.rules`

- **Cloud Messaging (FCM)**
  - Enable for push notifications

### Step 6: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

### Step 7: Generate Firebase Options Dart File

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure --project=bahhar-production
```

This creates `lib/firebase_options.dart` with your project configuration.

### Step 8: Update Firebase Service Initialization

The file `lib/core/services/firebase_service.dart` should initialize with:

```dart
import 'package:bahhar/firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## 3. Google Maps API Configuration

### Step 1: Enable Google Maps SDK

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create new one)
3. Navigate to **"APIs & Services"** → **"Library"**
4. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API (if using place search)
   - Geolocation API (if using IP geolocation)

### Step 2: Create API Key

1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"Create Credentials"** → **"API Key"**
3. Click **"Restrict Key"** (IMPORTANT for security)

### Step 3: Restrict API Key

**Application restrictions:**
- Select "Android apps"
- Add package name: `com.bahharai.bahhar`
- Add SHA-1 certificate fingerprint (from step 2.3)

**API restrictions:**
- Select "Restrict key"
- Choose only the APIs you enabled above

### Step 4: Configure API Key in Android

Create or edit `android/local.properties`:

```properties
sdk.dir=/path/to/Android/sdk
flutter.sdk=/path/to/flutter
MAPS_API_KEY=AIza...your_actual_key_here
```

Or add to `android/gradle.properties`:

```properties
MAPS_API_KEY=AIza...your_actual_key_here
```

**⚠️ IMPORTANT:** Never commit `local.properties` to Git (already in `.gitignore`)

---

## 4. App Signing

### Step 1: Create Upload Keystore

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- **Keystore password**: Choose a strong password (save it securely!)
- **Key password**: Can be same as keystore password
- **Distinguished Name fields**: Enter your organization details

Example:
```
First and last name: Bahhar AI
Organizational unit: Development
Organization: Bahhar AI
City: Muscat
State: Muscat
Country code: OM
```

**⚠️ CRITICAL:** Back up this keystore file securely! If you lose it, you cannot update your app.

### Step 2: Create Key Properties File

Create `android/key.properties`:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

Or use relative path:
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=../upload-keystore.jks
```

**⚠️ IMPORTANT:** Never commit `key.properties` to Git (add to `.gitignore`)

### Step 3: Configure Signing in build.gradle

The signing configuration is already set up in `android/app/build.gradle`. Verify it includes:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

---

## 5. Build Configuration

### Step 1: Update Version Numbers

In `pubspec.yaml`, update version:

```yaml
version: 1.0.0+1
```

Format: `major.minor.patch+buildNumber`
- Increment build number for every upload to Play Store
- Increment version for user-visible updates

### Step 2: Update App Metadata

In `android/app/build.gradle`:

```gradle
defaultConfig {
    applicationId "com.bahharai.bahhar"
    minSdk 23  // Android 6.0 (Marshmallow)
    targetSdk 34  // Android 14
    versionCode 1  // Must increment for each release
    versionName "1.0.0"  // User-visible version
}
```

### Step 3: Configure ProGuard (Code Obfuscation)

Create `android/app/proguard-rules.pro`:

```proguard
## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

## Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.libraries.maps.** { *; }
```

Enable in `build.gradle`:

```gradle
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

---

## 6. Testing

### Step 1: Build Debug APK

```bash
flutter build apk --debug
```

Install on device:
```bash
flutter install
```

### Step 2: Build Release APK

```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

### Step 3: Build App Bundle (Recommended)

```bash
flutter build appbundle --release
```

AAB location: `build/app/outputs/bundle/release/app-release.aab`

**Note:** Google Play requires App Bundles (.aab) for new apps starting August 2021.

### Step 4: Test Release Build

Install release APK on device:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Test all features:
- [ ] Authentication (Phone OTP, Google, Apple, Guest)
- [ ] Google Maps rendering
- [ ] Firebase Firestore sync
- [ ] Photo upload to Cloud Storage
- [ ] Push notifications
- [ ] Location services
- [ ] Offline functionality

### Step 5: Run Flutter Tests

```bash
flutter test
flutter test --coverage
```

### Step 6: Analyze Code Quality

```bash
flutter analyze
dart format --set-exit-if-changed .
```

---

## 7. Play Store Preparation

### Step 1: Create App Icons

Required icon sizes (already included in `android/app/src/main/res/`):

- `mipmap-mdpi/ic_launcher.png` - 48x48px
- `mipmap-hdpi/ic_launcher.png` - 72x72px
- `mipmap-xhdpi/ic_launcher.png` - 96x96px
- `mipmap-xxhdpi/ic_launcher.png` - 144x144px
- `mipmap-xxxhdpi/ic_launcher.png` - 192x192px

Generate using [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/icons-launcher.html)

### Step 2: Create Feature Graphic

Dimensions: 1024 x 500 pixels
- Used in Play Store listing
- Should showcase app branding and key features

### Step 3: Prepare Screenshots

Required:
- Minimum 2 screenshots
- Recommended: 4-8 screenshots
- Dimensions: 
  - Phone: 1080 x 1920px (9:16 ratio)
  - Tablet: 1200 x 1920px (optional)

Recommended screenshots:
1. Home dashboard with fishing score
2. Interactive map with hotspots
3. Trip planner wizard
4. Catch log and history
5. Profile with marine conditions

### Step 4: Write Store Listing Content

**App Title** (max 30 characters):
```
BAHHAR - Smart Fishing Oman
```

**Short Description** (max 80 characters):
```
AI-powered fishing companion for Omani coastal waters and marine intelligence
```

**Full Description** (max 4000 characters):

```
BAHHAR (بَحّار) - Oman's Premier Smart Fishing Companion

Transform your fishing experience with BAHHAR, the first AI-powered marine intelligence app designed specifically for Omani coastal waters. Whether you're a traditional fisherman, charter skipper, or sport angler, BAHHAR provides real-time predictions and expert guidance for every fishing trip.

🎯 KEY FEATURES:

Smart Fishing Predictions
• ML-powered bite probability forecasts (0-100 score)
• Species-specific recommendations (Kingfish, Yellowfin Tuna, Hammour, Amberjack)
• Real-time marine conditions: SST, wave height, wind speed, tidal currents

Interactive Marine Charts
• Custom nautical maps covering all Omani coastal regions
• Protected marine reserve boundaries (Daymaniyat Islands, Ras Al Jinz)
• Categorized fishing hotspots with depth and bathymetry data

Trip Planning Wizard
• Optimized route planning based on vessel type and fuel capacity
• Tidal window recommendations
• Distance and fuel consumption estimates

Catch Logging & History
• Comprehensive catch records with GPS coordinates
• Photo documentation
• Personal analytics and trends

Legal Compliance
• Marine reserve geofencing alerts
• MOAF regulation integration
• Seasonal restriction notifications

🌊 REGIONS COVERED:
• Musandam Peninsula (Khasab, Bukha)
• Al Batinah Coast (Sohar, Barka)
• Muscat (Mutrah, Marina Bandar Al Rowdha)
• Ash Sharqiyah (Sur, Ras Al Hadd)
• Al Wusta (Duqm)
• Dhofar (Salalah, Mirbat)

🔒 PRIVACY & SECURITY:
• Your data stays private and secure
• No third-party data sharing
• Offline mode with cached charts
• Firebase-powered sync

📱 REQUIREMENTS:
• Android 6.0 (Marshmallow) or higher
• GPS location services
• Internet connection for real-time updates

🇴🇲 BUILT FOR OMAN:
BAHHAR is engineered from the ground up for Oman's distinctive marine ecosystems, from the fjords of Musandam to the seasonal monsoon waters of Dhofar. Experience the future of fishing intelligence tailored to Omani waters.

سلطنة عُمان • Sultanate of Oman

For support: support@bahharai.com
Website: https://bahharai.com
```

**Category**: Sports

**Tags/Keywords**:
- fishing
- marine
- oman
- nautical
- ocean
- weather
- tides
- GPS
- navigation
- angling

### Step 5: Content Rating Questionnaire

Complete Google Play's content rating questionnaire:
- Violence: No
- Sexual content: No
- Profanity: No
- Controlled substances: No
- Gambling: No
- Location: Yes (for fishing location tracking)

Expected rating: **PEGI 3 / Everyone**

---

## 8. Publishing Process

### Step 1: Create Google Play Developer Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with Google account
3. Pay $25 one-time registration fee
4. Complete account details

### Step 2: Create New App

1. Click **"Create app"**
2. Select language: English (United States)
3. App name: **BAHHAR**
4. Default language: English (US)
5. App or game: App
6. Free or paid: Free
7. Accept declarations and guidelines

### Step 3: Set Up App Details

Navigate through all sections in the left sidebar:

#### Dashboard
- Complete all required tasks (marked with red !)

#### App content
- Privacy policy URL (required)
- App access (all features available, or explain restrictions)
- Ads (declare if app contains ads - currently: No)
- Content ratings (complete questionnaire)
- Target audience (select age ranges: 13+)
- News app (No)
- COVID-19 contact tracing (No)
- Data safety (complete questionnaire)

#### Store presence
- Main store listing
  - Add app name, short description, full description
  - Upload app icon (512 x 512 px)
  - Upload feature graphic (1024 x 500 px)
  - Upload phone screenshots (min 2, max 8)
  - Upload tablet screenshots (optional)
- Store settings
  - App category: Sports
  - Contact details (email, phone, website)

### Step 4: Create Internal Testing Track

1. Go to **"Testing"** → **"Internal testing"**
2. Click **"Create new release"**
3. Upload AAB file: `app-release.aab`
4. Add release name: `1.0.0 (1)` - Initial Release
5. Add release notes:
   ```
   Initial release of BAHHAR - Oman's smart fishing companion
   
   Features:
   • AI-powered fishing predictions
   • Interactive marine charts
   • Trip planning wizard
   • Catch logging
   • Marine reserve compliance
   ```
6. Click **"Save"** → **"Review release"** → **"Start rollout to Internal testing"**

### Step 5: Add Testers

1. Go to **"Internal testing"** → **"Testers"** tab
2. Create email list of testers
3. Share testing link with testers
4. Collect feedback and fix issues

### Step 6: Promote to Closed Testing (Beta)

1. After internal testing, go to **"Closed testing"**
2. Click **"Create new release"**
3. **"Promote release"** from Internal testing
4. Add more testers (can use Google Groups for larger testing)
5. Collect feedback for 1-2 weeks

### Step 7: Submit for Production Review

1. Ensure all **App content** sections are complete
2. Go to **"Production"** → **"Releases"**
3. Click **"Create new release"**
4. **"Promote release"** from Closed testing
5. Set rollout percentage:
   - Start with 5-10% for staged rollout
   - Monitor crash reports and reviews
   - Increase to 25% → 50% → 100% over several days
6. Click **"Review release"**
7. Fix any errors or warnings
8. Click **"Start rollout to Production"**

### Step 8: Google Review Process

- Review time: typically 2-7 days (can be longer for first release)
- Google will test app for:
  - Policy compliance
  - Content rating accuracy
  - Malware and security issues
  - App functionality

**Common rejection reasons:**
- Incomplete privacy policy
- Missing data safety disclosures
- Broken core functionality
- Misleading screenshots or description

---

## 9. Post-Publication

### Monitor App Performance

**Key metrics to track:**
- Install count and retention
- Crash-free rate (target: > 99%)
- ANR (Application Not Responding) rate (target: < 0.5%)
- User reviews and ratings
- Uninstall rate

**Tools:**
- Google Play Console → Statistics
- Firebase Crashlytics
- Firebase Analytics

### Release Updates

**For bug fixes:**
```bash
# Increment build number
# version: 1.0.0+2

flutter build appbundle --release
```

Upload to **Production** → **Create new release**

**For feature updates:**
```bash
# Increment version number
# version: 1.1.0+3

flutter build appbundle --release
```

### Respond to User Reviews

- Reply to negative reviews professionally
- Thank users for positive feedback
- Address reported bugs quickly
- Use feedback for feature prioritization

### Marketing & Promotion

**Launch checklist:**
- [ ] Create social media accounts (Facebook, Instagram, Twitter)
- [ ] Design marketing materials using feature graphic
- [ ] Reach out to Omani fishing communities
- [ ] Contact fishing equipment stores for partnerships
- [ ] Create tutorial videos for YouTube
- [ ] Write blog posts about Omani fishing techniques
- [ ] Submit to app review websites
- [ ] Consider Google Ads campaigns

---

## Troubleshooting Common Issues

### Build Errors

**Gradle sync failed:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Keystore not found:**
- Verify `key.properties` path is correct
- Use absolute path if relative path fails

**Google Maps not rendering:**
- Verify API key in `AndroidManifest.xml`
- Check API restrictions in Cloud Console
- Ensure SHA-1 fingerprint is added

### Firebase Issues

**Firebase not initializing:**
- Verify `google-services.json` is in `android/app/`
- Run `flutterfire configure` again
- Check package name matches across all configs

**Auth errors:**
- Verify all auth methods enabled in Firebase Console
- Add SHA-1 certificates for Google Sign-In
- Enable billing for phone authentication

### Publishing Issues

**App rejected for privacy policy:**
- Host privacy policy on accessible URL
- Must clearly state data collection practices
- Required sections: what data, why, how stored

**Missing permissions explanation:**
- Add `uses-permission` explanations in Play Console
- Justify why each permission is needed

---

## Security Checklist

Before publishing:

- [ ] Remove all hardcoded API keys from code
- [ ] Use environment variables or `key.properties`
- [ ] Enable ProGuard/R8 code obfuscation
- [ ] Restrict API keys in Cloud Console
- [ ] Deploy Firebase security rules
- [ ] Test with release build, not debug
- [ ] Scan with Google Play Protect
- [ ] Review all third-party dependencies for vulnerabilities
- [ ] Implement certificate pinning for sensitive API calls
- [ ] Enable Firebase App Check

---

## Resources

**Official Documentation:**
- [Flutter Deployment](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Maps Platform](https://developers.google.com/maps/documentation)

**Tools:**
- [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/)
- [App Icon Generator](https://appicon.co/)
- [Privacy Policy Generator](https://www.privacypolicygenerator.info/)

**Support:**
- GitHub Issues: https://github.com/Sonalhegde/BAHHAR/issues
- Email: support@bahharai.com

---

## Version History

| Version | Build | Date | Changes |
|---------|-------|------|---------|
| 1.0.0 | 1 | 2026-09-15 | Initial release |

---

**Last Updated:** September 15, 2026  
**Document Version:** 1.0  
**Maintained by:** BAHHAR Development Team
