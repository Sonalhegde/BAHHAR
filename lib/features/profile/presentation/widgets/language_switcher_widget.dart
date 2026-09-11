import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/preferences_provider.dart';

/// Language switcher toggling the app between English and Arabic with full
/// RTL support.
class LanguageSwitcherWidget extends ConsumerWidget {
  const LanguageSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);

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
        ref
            .read(isArabicProvider.notifier)
            .setArabic(newSelection.first == 'ar');
      },
    );
  }
}
