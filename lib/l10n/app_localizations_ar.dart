// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'بحّار';

  @override
  String get fishingOpportunity => 'فرصة الصيد';

  @override
  String get targetSpecies => 'الأنواع المستهدفة';

  @override
  String get bestTime => 'أفضل وقت';

  @override
  String get seaTemperature => 'درجة حرارة البحر';

  @override
  String get waveHeight => 'ارتفاع الموج';

  @override
  String get wind => 'الرياح';
}
