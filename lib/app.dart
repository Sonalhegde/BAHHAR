import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class BahharApp extends ConsumerWidget {
  const BahharApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Bahhar AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.marineDarkTheme,
      darkTheme: AppTheme.marineDarkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
    );
  }
}
