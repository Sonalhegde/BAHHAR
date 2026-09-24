import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/preferences_provider.dart';

class BahharApp extends ConsumerWidget {
  const BahharApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    final themeMode = ref.watch(preferencesProvider).themeMode;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: MaterialApp.router(
        title: 'BAHHAR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.coastalLightTheme(isArabic: isArabic),
        darkTheme: AppTheme.coastalDarkTheme(isArabic: isArabic),
        themeMode: themeMode,
        locale: isArabic ? const Locale('ar', 'OM') : const Locale('en', 'OM'),
        supportedLocales: const [
          Locale('en', 'OM'),
          Locale('ar', 'OM'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: AppRouter.router,
      ),
    );
  }
}
