import 'package:flutter/material.dart';
import '../../../../app.dart';

/// Language switcher widget stub allowing the user to override device locale
/// between English and Arabic with full RTL support.
class LanguageSwitcherWidget extends StatelessWidget {
  const LanguageSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'en',
          label: Text('English'),
          icon: Icon(Icons.language),
        ),
        ButtonSegment<String>(
          value: 'ar',
          label: Text('العربية'),
          icon: Icon(Icons.translate),
        ),
      ],
      selected: {isArabic ? 'ar' : 'en'},
      onSelectionChanged: (Set<String> newSelection) {
        final selectedLanguage = newSelection.first;
        BahharApp.setLocale(context, Locale(selectedLanguage));
        // TODO: Persist choice locally using shared_preferences / secure_storage
      },
    );
  }
}
