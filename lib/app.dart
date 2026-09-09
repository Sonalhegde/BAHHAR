import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_dashboard_screen.dart';
import 'features/map/presentation/fishing_map_screen.dart';
import 'features/smart_trip/presentation/smart_trip_wizard_screen.dart';
import 'features/my_catch/presentation/catch_history_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

/// Root application widget for BAHHAR.
/// Configures localization (English + Arabic, RTL-ready), themes,
/// and the bottom nav shell wrapping Home, Map, Smart Trip, My Catch, and Profile.
class BahharApp extends StatefulWidget {
  const BahharApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _BahharAppState? state = context.findAncestorStateOfType<_BahharAppState>();
    state?.changeLocale(newLocale);
  }

  @override
  State<BahharApp> createState() => _BahharAppState();
}

class _BahharAppState extends State<BahharApp> {
  Locale? _currentLocale;

  void changeLocale(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAHHAR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: _currentLocale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic (Oman)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == deviceLocale.languageCode) {
              return supportedLocale;
            }
          }
        }
        // Fallback to English if device locale is neither en nor ar
        return const Locale('en');
      },
      home: const MainNavigationShell(),
    );
  }
}

/// Bottom navigation shell wrapping Home, Map, Smart Trip, My Catch, and Profile
/// per the wireframe navigation bar.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    FishingMapScreen(),
    SmartTripWizardScreen(),
    CatchHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Smart Trip',
          ),
          NavigationDestination(
            icon: Icon(Icons.phishing_outlined),
            selectedIcon: Icon(Icons.phishing),
            label: 'My Catch',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
