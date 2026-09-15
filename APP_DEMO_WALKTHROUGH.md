# BAHHAR App Demo Walkthrough

**Version:** 1.0.0  
**Date:** September 15, 2026  
**Status:** Demo Mode (Simulated Data)

---

## 🎬 App Flow Overview

```
┌─────────────────────────────────────────────────────────────┐
│  SPLASH SCREEN (Entry Point)                                │
│  • BAHHAR logo with sail emblem                             │
│  • Bilingual branding (English/Arabic)                      │
│  • Language toggle (EN ⇄ AR)                                │
│  • "Enter Command" button                                   │
│  • Marine background with headland silhouettes              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  AUTHENTICATION SCREEN (Multi-Method)                       │
│  • Phone OTP (+968 Oman)                                    │
│  • Google Sign-In                                           │
│  • Apple Sign-In                                            │
│  • Email/Password (disabled by design)                      │
│  • Guest Mode (one-tap demo access)                         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  HOME DASHBOARD (Main Hub)                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Port Selector: [Mutrah ▼]                             │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │ 🎯 FISHING SCORE GAUGE                                │  │
│  │     ┌─────────────┐                                   │  │
│  │     │     73      │  ← ML Prediction                  │  │
│  │     │  FAVORABLE  │                                   │  │
│  │     └─────────────┘                                   │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │ 🌊 LIVE MARINE CONDITIONS                             │  │
│  │  Wave: 0.9m  |  Wind: 12kts  |  SST: 27.5°C          │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │ 🗺️ TOP HOTSPOTS                                       │  │
│  │  1. Daymaniyat Drop-Off     [85/100] 🟢              │  │
│  │  2. Mutrah Rocky Bank        [72/100] 🟢              │  │
│  │  3. Al Bustan Reef           [68/100] 🟡              │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  [🗺️ Map] [🧭 Trip] [📝 Catch] [👤 Profile]              │
└─────────────────────────────────────────────────────────────┘
                    ↓         ↓         ↓         ↓
┌──────────────┐ ┌──────────┐ ┌────────────┐ ┌──────────────┐
│ FISHING MAP  │ │ TRIP     │ │ CATCH LOG  │ │ USER PROFILE │
│              │ │ PLANNER  │ │            │ │              │
│ • Custom     │ │ • 4-step │ │ • Species  │ │ • Settings   │
│   nautical   │ │   wizard │ │ • Weight   │ │ • Language   │
│   styling    │ │ • Fuel   │ │ • GPS      │ │ • Licenses   │
│ • Protected  │ │   calc   │ │ • Photos   │ │ • Legal info │
│   reserves   │ │ • Route  │ │ • History  │ │ • Bilingual  │
│ • Hotspot    │ │   plan   │ │ • Stats    │ │   toggle     │
│   markers    │ │          │ │            │ │              │
└──────────────┘ └──────────┘ └────────────┘ └──────────────┘
```

---

## 📱 Screen-by-Screen Breakdown

### 1. Splash Screen (First Launch)

**Visual Elements:**
```
┌────────────────────────────────────────┐
│ [EN ⇄ AR]            Oman ▼           │
│                                         │
│                                         │
│              ⛵                          │
│           BAHHAR                        │
│           بَحّار                        │
│                                         │
│     سلطنة عُمان • Sultanate of Oman    │
│                                         │
│                                         │
│      [  Enter Command  →  ]            │
│                                         │
│   Navigate • Explore • Stay Safe       │
│                                         │
│    ~ Subtle wave pattern background ~  │
└────────────────────────────────────────┘
```

**Features:**
- Marine-themed gradient background
- Animated BAHHAR sail emblem
- Language toggle (top-left)
- Location indicator (top-right)
- Smooth fade-in animation
- Primary action button

---

### 2. Authentication Screen

**Visual Layout:**
```
┌────────────────────────────────────────┐
│          Welcome to BAHHAR              │
│     Your Smart Fishing Companion        │
│                                         │
│  ┌────────────────────────────────┐    │
│  │  📱 +968 |_______________|     │    │
│  │     [Send OTP Code]            │    │
│  └────────────────────────────────┘    │
│                                         │
│  ┌────────────────────────────────┐    │
│  │  [G] Continue with Google      │    │
│  └────────────────────────────────┘    │
│                                         │
│  ┌────────────────────────────────┐    │
│  │  [] Continue with Apple        │    │
│  └────────────────────────────────┘    │
│                                         │
│          ─── OR ───                     │
│                                         │
│  ┌────────────────────────────────┐    │
│  │  [👤 Explore as Guest]         │    │
│  └────────────────────────────────┘    │
└────────────────────────────────────────┘
```

**Authentication Methods:**
- **Phone OTP**: Primary method for Omani users
- **Google Sign-In**: One-tap OAuth
- **Apple Sign-In**: iOS-first authentication
- **Guest Mode**: Instant demo access (no signup)

---

### 3. Home Dashboard

**Layout Structure:**
```
┌────────────────────────────────────────┐
│  🏠 BAHHAR          Mutrah ▼      [☰]  │
├────────────────────────────────────────┤
│                                         │
│     ┌─────────────────────┐            │
│     │       73/100        │            │
│     │    ●●●●●●●○○○      │            │
│     │    FAVORABLE        │            │
│     │                     │            │
│     │  Next Peak: 06:30   │            │
│     └─────────────────────┘            │
│                                         │
│  🌊 Marine Conditions                  │
│  ┌─────┬──────┬──────┬──────┐         │
│  │Wave │ Wind │ SST  │ Tide │         │
│  │0.9m │ 12kt │27.5°C│Rising│         │
│  └─────┴──────┴──────┴──────┘         │
│                                         │
│  🎯 Top Hotspots Near You              │
│  ┌───────────────────────────────┐    │
│  │ 🟢 Daymaniyat Drop-Off   85   │    │
│  │    38m • 15.2nmi • Kingfish   │    │
│  ├───────────────────────────────┤    │
│  │ 🟢 Mutrah Rocky Bank     72   │    │
│  │    28m • 3.5nmi • Hammour     │    │
│  ├───────────────────────────────┤    │
│  │ 🟡 Al Bustan Reef        68   │    │
│  │    18m • 8.1nmi • Grouper     │    │
│  └───────────────────────────────┘    │
│                                         │
│         [View Full Map →]              │
│                                         │
├────────────────────────────────────────┤
│  [🗺️]    [🧭]    [📝]    [👤]        │
│   Map    Trip   Catch  Profile        │
└────────────────────────────────────────┘
```

**Key Features:**
- **Port Selector**: Switch between major Omani ports
- **Fishing Score Gauge**: 0-100 ML prediction
- **Live Conditions**: Real-time marine data
- **Hotspot Cards**: Ranked fishing locations
- **Bottom Navigation**: 4 main sections

---

### 4. Interactive Fishing Map

**Map View:**
```
┌────────────────────────────────────────┐
│  [←] Fishing Map    [Filter ▼] [⚙️]   │
├────────────────────────────────────────┤
│                                         │
│         ~  Sea Area  ~                 │
│    🔴85                                 │
│  Daymaniyat ┌─────────┐               │
│  Reserve    │Protected│               │
│             └─────────┘               │
│                                         │
│      🟢72                               │
│   Mutrah Bank                          │
│                                         │
│  ≈ ≈ ≈ ≈ ≈ ≈ ≈                        │
│   Coastline                            │
│                                         │
│  Legend:                                │
│  🔴 Excellent (70-100)                 │
│  🟡 Good (40-69)                       │
│  ⚪ Poor (0-39)                        │
│  ▢ Protected Area                      │
│                                         │
│  [📍 Current Location]                 │
└────────────────────────────────────────┘
```

**Features:**
- Custom nautical map styling
- Color-coded hotspot markers
- Protected marine reserve boundaries (purple)
- Real-time GPS tracking
- Layer toggles (bathymetry, currents)
- Distance ruler tool

---

### 5. Smart Trip Planner (4-Step Wizard)

**Step 1: Target Species**
```
┌────────────────────────────────────────┐
│  Trip Planner • Step 1 of 4            │
│                                         │
│  Select Target Species                  │
│                                         │
│  [  🐟 Kingfish (كنعد)         ✓  ]   │
│  [  🐟 Yellowfin Tuna (ثمد)       ]   │
│  [  🐟 Hammour (هامور)            ]   │
│  [  🐟 Amberjack                   ]   │
│  [  🐟 Sailfish                    ]   │
│  [  🐟 Mahi Mahi                   ]   │
│                                         │
│          [← Back]    [Next →]          │
└────────────────────────────────────────┘
```

**Step 2: Vessel Details**
```
┌────────────────────────────────────────┐
│  Trip Planner • Step 2 of 4            │
│                                         │
│  Vessel Type                            │
│  ○ Fiberglass Skiff (24-28ft)          │
│  ● Traditional Dhow                     │
│  ○ Offshore Cruiser (32ft+)            │
│                                         │
│  Max Range (nautical miles)            │
│  [────●────────────────────] 25 nmi    │
│   5                             50      │
│                                         │
│  Fuel Capacity (Liters)                │
│  [____________] 150L                    │
│                                         │
│          [← Back]    [Next →]          │
└────────────────────────────────────────┘
```

**Step 3: Timing**
```
┌────────────────────────────────────────┐
│  Trip Planner • Step 3 of 4            │
│                                         │
│  Departure Date                         │
│  [📅 Tomorrow, Sep 16, 2026]           │
│                                         │
│  Preferred Launch Window                │
│  ○ Pre-dawn (04:30)                    │
│  ● Dawn (05:30-06:00)                  │
│  ○ Afternoon Slack (14:30)             │
│                                         │
│  ⚠️ Tide: Rising at 06:15              │
│  🌙 Solunar: Major period 05:45-07:45  │
│                                         │
│          [← Back]    [Next →]          │
└────────────────────────────────────────┘
```

**Step 4: Review & Plan**
```
┌────────────────────────────────────────┐
│  Trip Planner • Step 4 of 4            │
│                                         │
│  📍 Recommended Route                   │
│                                         │
│  Mutrah Marina → Daymaniyat Drop-Off   │
│  Distance: 15.2 nmi                    │
│  Transit Time: 1h 15min                │
│  Fuel Estimate: 45L                    │
│                                         │
│  🎯 Prime Fishing Window                │
│  06:30 - 10:30 (4 hours)               │
│                                         │
│  🎣 Recommended Tackle                  │
│  • Trolling lures (silver/blue)        │
│  • Depth: 25-40m                       │
│  • Jigging optional                    │
│                                         │
│  [← Back]  [💾 Save Trip] [🚀 Start]  │
└────────────────────────────────────────┘
```

---

### 6. Catch Log & History

**Add Catch Form:**
```
┌────────────────────────────────────────┐
│  [←] Log New Catch                     │
├────────────────────────────────────────┤
│                                         │
│  Species *                              │
│  [Kingfish (كنعد)        ▼]           │
│                                         │
│  Weight (kg) *          Length (cm)    │
│  [____5.75____]         [____85____]   │
│                                         │
│  📍 Location                            │
│  Daymaniyat Drop-Off                   │
│  23.8617°N, 58.0933°E                  │
│  [📍 Use Current Location]             │
│                                         │
│  📷 Photo (Optional)                    │
│  [───────────────────────]             │
│  [   + Add Photo from Gallery   ]      │
│                                         │
│  🎣 Gear Method                         │
│  [Trolling              ▼]             │
│                                         │
│  Bait/Lure                              │
│  [Silver spoon lure_____________]      │
│                                         │
│  Marine Conditions                      │
│  SST: 27.5°C  |  Wave: 0.9m            │
│  Wind: 12kts  |  Tide: Rising          │
│                                         │
│  ☑️ Catch & Release                    │
│                                         │
│  Notes (Optional)                       │
│  [_____________________________]       │
│                                         │
│      [Cancel]    [💾 Save Catch]       │
└────────────────────────────────────────┘
```

**Catch History:**
```
┌────────────────────────────────────────┐
│  📝 My Catch Log                       │
│                                         │
│  This Month: 12 catches | 45.3kg       │
│                                         │
│  ┌───────────────────────────────┐    │
│  │ 🐟 Kingfish • 5.75kg          │    │
│  │ Today 06:45 • Daymaniyat      │    │
│  │ [Photo thumbnail]             │    │
│  └───────────────────────────────┘    │
│                                         │
│  ┌───────────────────────────────┐    │
│  │ 🐟 Hammour • 3.2kg            │    │
│  │ Yesterday 07:15 • Mutrah Bank │    │
│  │ Released ✓                    │    │
│  └───────────────────────────────┘    │
│                                         │
│  ┌───────────────────────────────┐    │
│  │ 🐟 Yellowfin Tuna • 12.8kg    │    │
│  │ Sep 13 • Al Bustan Reef       │    │
│  │ [Photo thumbnail]             │    │
│  └───────────────────────────────┘    │
│                                         │
│  [View Analytics →]                    │
└────────────────────────────────────────┘
```

---

### 7. User Profile & Settings

**Profile Screen:**
```
┌────────────────────────────────────────┐
│  👤 Profile                    [⚙️]    │
├────────────────────────────────────────┤
│                                         │
│      ┌─────────────┐                   │
│      │   [Photo]   │                   │
│      │  Capt. Ali  │                   │
│      └─────────────┘                   │
│                                         │
│  📧 ali.fisherman@gmail.com            │
│  📱 +968 9123 4567                     │
│                                         │
│  🏠 Home Port: Mutrah Marina           │
│  🌍 Region: Muscat Governorate         │
│                                         │
│  ─────────────────────────────         │
│                                         │
│  🚤 My Vessel                          │
│  Traditional Dhow • 26ft               │
│  Fuel Capacity: 150L                   │
│                                         │
│  📊 Statistics                          │
│  Total Catches: 45                     │
│  Total Weight: 156.8kg                 │
│  Favorite Species: Kingfish            │
│  Member Since: Aug 2026                │
│                                         │
│  ─────────────────────────────         │
│                                         │
│  [🌐 EN ⇄ AR] Language                │
│  [📜 Fishing License]                  │
│  [⚖️ Legal & Compliance]               │
│  [📞 Support]                          │
│  [🚪 Sign Out]                         │
│                                         │
└────────────────────────────────────────┘
```

---

## 🎨 Design System Highlights

### Color Palette (v2 Premium White)
```
┌────────────────────────────────────┐
│  Pure White         #FFFFFF        │  Primary Background
│  Subtle Background  #F7F7F5        │  Card Surfaces
│  Hairline Border    #E7E7E4        │  Dividers
│  Primary Text       #1A1A1A        │  Headings
│  Secondary Text     #6B6B6B        │  Captions
│  Accent Navy        #12263A        │  Brand Accent
│  Signal Good        #2E7D5B        │  High Score
│  Signal Caution     #B8862E        │  Medium Score
│  Signal Alert       #B23A2E        │  Low Score/Warning
│  Legal Restricted   #6B5B95        │  Protected Areas
└────────────────────────────────────┘
```

### Typography
- **Headers**: 22-24pt Semibold
- **Body**: 15pt Regular/Medium
- **Metrics**: 26-32pt Bold (tabular figures)
- **Captions**: 12pt Regular

### Visual Elements
- ✅ Hairline 1px borders (no drop shadows)
- ✅ 8pt spacing scale throughout
- ✅ Glass morphism on overlays
- ✅ Smooth transitions (250ms)
- ✅ High contrast for bright sun readability

---

## 🌊 Marine Background

Every screen features a subtle **marine background**:
- Soft gradient from cream to light blue
- Subtle wave patterns
- Headland silhouettes on horizon
- Optimized for outdoor visibility
- Never interferes with content readability

---

## 🔔 Notifications Example

**Marine Advisory Notification:**
```
┌────────────────────────────────────────┐
│  🔔 Notifications              [Clear] │
├────────────────────────────────────────┤
│  ┌───────────────────────────────┐    │
│  │ ⚠️ High Swell Warning         │    │
│  │ Wave height expected 2.5-3m   │    │
│  │ Tomorrow 10:00 - 18:00        │    │
│  │ 2 hours ago                   │    │
│  └───────────────────────────────┘    │
│                                         │
│  ┌───────────────────────────────┐    │
│  │ 🎣 Favorable Conditions       │    │
│  │ Kingfish bite probability 82% │    │
│  │ Daymaniyat Drop-Off           │    │
│  │ 5 hours ago                   │    │
│  └───────────────────────────────┘    │
│                                         │
│  ┌───────────────────────────────┐    │
│  │ 📜 Regulation Update          │    │
│  │ New fishing season dates      │    │
│  │ Ministry of Agriculture       │    │
│  │ Yesterday                     │    │
│  └───────────────────────────────┘    │
└────────────────────────────────────────┘
```

---

## 🌐 Bilingual Support

**Instant Language Toggle:**
```
English View              Arabic View (RTL)
┌──────────────┐         ┌──────────────┐
│ BAHHAR       │         │       بَحّار  │
│              │         │              │
│ Home Port    │    ⇄    │   المرسى الرئيسي│
│ Mutrah       │         │       مطرح    │
│              │         │              │
│ [View Map →] │         │ [→ عرض الخريطة]│
└──────────────┘         └──────────────┘
```

---

## 📊 Demo Data (Without Firebase)

The app runs in **demo mode** with simulated data:

- ✅ 10 pre-loaded fishing hotspots
- ✅ Simulated marine conditions
- ✅ Sample catch history
- ✅ Demo fishing scores
- ✅ Warning banner: "Demo Mode - Connect Firebase for live data"

---

## 🚀 How to Run the Demo

### Prerequisites
- Flutter 3.24.0+
- Android device/emulator or iOS device/simulator

### Quick Start
```bash
# Navigate to project
cd C:\Users\sonal\bahhar\BAHHAR

# Install dependencies
flutter pub get

# Run in demo mode (no Firebase needed)
flutter run
```

### Expected Behavior
1. **Splash Screen** → Tap "Enter Command"
2. **Auth Screen** → Tap "Explore as Guest"
3. **Home Dashboard** → See simulated fishing data
4. **Navigate** → Use bottom tabs to explore features

---

## 🎯 Key Demo Features to Try

1. **Toggle Language**: EN ⇄ AR in top-right
2. **View Map**: See protected areas and hotspots
3. **Create Trip**: Step through 4-step wizard
4. **Log Catch**: Add a test catch with GPS
5. **Check Profile**: View sample statistics

---

## 📱 What Users Will Experience

### First-Time User Flow
```
Launch App
    ↓
Splash (with branding)
    ↓
Guest Mode or Sign Up
    ↓
Home Dashboard
    ↓
Explore Features:
    • Check fishing scores
    • View marine conditions
    • Plan a trip
    • Log catches
    • Browse hotspots
```

### Returning User Flow
```
Launch App
    ↓
Auto-login (if authenticated)
    ↓
Home Dashboard
    ↓
Recent activity and recommendations
```

---

## 🎬 Animation & Interactions

### Splash Screen
- Logo fade-in (500ms)
- Subtle scale animation
- Background wave parallax

### Home Dashboard
- Gauge fills from 0 → score (800ms)
- Hotspot cards stagger-fade (100ms delay each)
- Smooth tab transitions (250ms)

### Map
- Marker pulse for high-probability spots
- Smooth zoom and pan
- Protected area boundaries fade in

### Forms
- Input field focus animations
- Validation feedback
- Success checkmark animation

---

## 💡 Tips for Demo

1. **Guest Mode**: Perfect for exploring without signup
2. **Language Toggle**: Try Arabic to see RTL layout
3. **Map Interaction**: Tap hotspot markers for details
4. **Trip Planner**: Complete all 4 steps for fuel/route calc
5. **Catch Log**: Add a catch to see form validation

---

## 🐛 Known Demo Limitations

- ❌ No real-time data (using simulated values)
- ❌ Maps show blank tiles (need Google Maps API key)
- ❌ Authentication doesn't connect to Firebase
- ❌ Photos not uploaded to Cloud Storage
- ✅ All UI/UX fully functional
- ✅ Navigation and forms work perfectly

---

## 📞 Need Help?

If you encounter issues running the demo:

1. Check Flutter installation: `flutter doctor`
2. Ensure dependencies installed: `flutter pub get`
3. Clear build cache: `flutter clean`
4. See [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) for troubleshooting

---

**Ready to explore BAHHAR? Run `flutter run` and start navigating!** 🚀

---

**Last Updated**: September 15, 2026  
**Document Version**: 1.0  
**Maintained by**: BAHHAR Development Team
