import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_register_screen.dart';
import '../../features/home/presentation/home_dashboard_screen.dart';
import '../../features/map/presentation/fishing_map_screen.dart';
import '../../features/trip_planner/presentation/smart_trip_wizard_screen.dart';
import '../../features/trip_planner/presentation/trip_recommendation_screen.dart';
import '../../features/my_catch/presentation/catch_history_screen.dart';
import '../../features/my_catch/presentation/add_catch_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/licences_screen.dart';
import '../../features/profile/presentation/vessels_screen.dart';
import '../../features/profile/presentation/crew_screen.dart';
import '../../features/profile/presentation/documents_wallet_screen.dart';
import '../../features/profile/presentation/safety_center_screen.dart';
import '../../features/profile/presentation/help_instructions_screen.dart';
import '../../features/profile/presentation/report_issue_screen.dart';
import '../../features/profile/presentation/official_info_screen.dart';
import '../../features/profile/presentation/edit_personal_info_screen.dart';
import '../../features/profile/presentation/profile_settings_screen.dart';
import '../../features/hotspot/presentation/hotspot_details_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../shared/polymorphic/floating_nav_bar.dart';
import '../../shared/animations/app_animations.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const OnboardingScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const LoginRegisterScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const LoginRegisterScreen()),
      ),
      GoRoute(
        path: '/hotspots/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return fadeSlidePage(
            keyName: state.uri.toString(),
            child: HotspotDetailsScreen(hotspotId: id),
          );
        },
      ),
      GoRoute(
        path: '/trip-recommendation',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const TripRecommendationScreen()),
      ),
      GoRoute(
        path: '/my-catch/add',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const AddCatchScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const NotificationsScreen()),
      ),

      // ── Profile sub-screens (outside shell — full screen) ─────────────────
      GoRoute(
        path: '/profile/licences',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const LicencesScreen()),
      ),
      GoRoute(
        path: '/profile/vessels',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const VesselsScreen()),
      ),
      GoRoute(
        path: '/profile/crew',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const CrewScreen()),
      ),
      GoRoute(
        path: '/profile/gear',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const DocumentsWalletScreen()), // gear handled inside documents for now
      ),
      GoRoute(
        path: '/profile/documents',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const DocumentsWalletScreen()),
      ),
      GoRoute(
        path: '/profile/safety',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const SafetyCenterScreen()),
      ),
      GoRoute(
        path: '/profile/help',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const HelpInstructionsScreen()),
      ),
      GoRoute(
        path: '/profile/report',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const ReportIssueScreen()),
      ),
      GoRoute(
        path: '/profile/official-info',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const OfficialInfoScreen()),
      ),
      GoRoute(
        path: '/profile/edit-personal',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const EditPersonalInfoScreen()),
      ),
      GoRoute(
        path: '/profile/settings',
        pageBuilder: (context, state) =>
            fadeSlidePage(keyName: state.uri.toString(), child: const ProfileSettingsScreen()),
      ),

      // ── Main Shell with Bottom Navigation ─────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _BahharShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, __) => '/home',
          ),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                fadeSlidePage(keyName: state.uri.toString(), child: const HomeDashboardScreen()),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) =>
                fadeSlidePage(keyName: state.uri.toString(), child: const FishingMapScreen()),
          ),
          GoRoute(
            path: '/trip-planner',
            pageBuilder: (context, state) =>
                fadeSlidePage(keyName: state.uri.toString(), child: const SmartTripWizardScreen()),
          ),
          GoRoute(
            path: '/catch',
            pageBuilder: (context, state) =>
                fadeSlidePage(keyName: state.uri.toString(), child: const CatchHistoryScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                fadeSlidePage(keyName: state.uri.toString(), child: const ProfileScreen()),
          ),
        ],
      ),
    ],
  );
}

class _BahharShell extends StatelessWidget {
  final Widget child;
  const _BahharShell({required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/trip-planner')) return 2;
    if (location.startsWith('/catch')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/map'); break;
      case 2: context.go('/trip-planner'); break;
      case 3: context.go('/catch'); break;
      case 4: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          FloatingGlassNavBar(
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (idx) => _onItemTapped(idx, context),
            items: const [
              NavDestinationItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Command',
              ),
              NavDestinationItem(
                icon: Icons.map_outlined,
                selectedIcon: Icons.map_rounded,
                label: 'Chart',
              ),
              NavDestinationItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore_rounded,
                label: 'Trip',
              ),
              NavDestinationItem(
                icon: Icons.phishing_outlined,
                selectedIcon: Icons.phishing_rounded,
                label: 'Logbook',
              ),
              NavDestinationItem(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
