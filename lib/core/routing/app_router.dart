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
import '../../features/hotspot/presentation/hotspot_details_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginRegisterScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginRegisterScreen(),
      ),
      GoRoute(
        path: '/hotspots/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return HotspotDetailsScreen(hotspotId: id);
        },
      ),
      GoRoute(
        path: '/trip-recommendation',
        builder: (context, state) => const TripRecommendationScreen(),
      ),
      GoRoute(
        path: '/my-catch/add',
        builder: (context, state) => const AddCatchScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Main shell with bottom navigation
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
            builder: (context, state) => const HomeDashboardScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const FishingMapScreen(),
          ),
          GoRoute(
            path: '/trip-planner',
            builder: (context, state) => const SmartTripWizardScreen(),
          ),
          GoRoute(
            path: '/catch',
            builder: (context, state) => const CatchHistoryScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
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
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderHairline, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surfacePure,
          elevation: 0,
          indicatorColor: AppColors.accentNavy.withValues(alpha: 0.08),
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (idx) => _onItemTapped(idx, context),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.accentNavy),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map, color: AppColors.accentNavy),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore, color: AppColors.accentNavy),
              label: 'Smart Trip',
            ),
            NavigationDestination(
              icon: Icon(Icons.phishing_outlined),
              selectedIcon: Icon(Icons.phishing, color: AppColors.accentNavy),
              label: 'My Catch',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.accentNavy),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
