import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/providers/preferences_provider.dart';

/// Root application widget for Bahhar AI configured with GoRouter,
/// dynamic light / first-class dark mode, and English + Arabic RTL support.
class BahharApp extends ConsumerStatefulWidget {
  const BahharApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _BahharAppState? state = context.findAncestorStateOfType<_BahharAppState>();
    state?.changeLocale(newLocale);
  }

  @override
  ConsumerState<BahharApp> createState() => _BahharAppState();
}

class _BahharAppState extends ConsumerState<BahharApp> {
  Locale? _currentLocale;

  void changeLocale(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);

    return MaterialApp.router(
      title: 'BAHHAR AI',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: prefs.themeMode,
      locale: _currentLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
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
        return const Locale('en');
      },
    );
  }
}
