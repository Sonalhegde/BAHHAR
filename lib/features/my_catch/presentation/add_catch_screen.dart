import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/catches_provider.dart';
import '../../../core/models/catch_model.dart';
import '../../../shared/widgets/custom_buttons.dart';

class AddCatchScreen extends ConsumerStatefulWidget {
  const AddCatchScreen({super.key});

  @override
  ConsumerState<AddCatchScreen> createState() => _AddCatchScreenState();
}

class _AddCatchScreenState extends ConsumerState<AddCatchScreen> {
  String _selectedSpecies = 'Kingfish (Kanaad)';
  final _weightController = TextEditingController(text: '8.5');
  final _lengthController = TextEditingController(text: '76');
  final _notesController = TextEditingController();

  final List<String> _species = [
    'Kingfish (Kanaad)',
    'Yellowfin Tuna (Thamad)',
    'Hammour (Grouper)',
    'Queenfish (Dala'a)',
    'Mahi-Mahi (Dorado)',
    'Barracuda (Ghad)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log New Catch'),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(20.0),
        children: [
          // Photo capture area
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.mistGray,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.oceanBlue),
                  SizedBox(height: 8),
                  Text('Tap to capture or upload catch photo'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedSpecies,
            decoration: InputDecoration(
              labelText: 'Fish Species',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _species.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedSpecies = val);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lengthController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Length (cm)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Bait / Technique Notes',
              hintText: 'e.g. Trolled at 20m depth with Rapala lure',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          BahharPrimaryButton(
            label: 'Save Catch to History',
            icon: Icons.check,
            onPressed: () {
              final newCatch = CatchModel(
                id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                speciesName: _selectedSpecies,
                speciesNameAr: 'كنعد',
                weightKg: double.tryParse(_weightController.text) ?? 5.0,
                lengthCm: double.tryParse(_lengthController.text),
                locationName: 'Muscat Coastal Waters',
                latitude: 23.6143,
                longitude: 58.5453,
                caughtAt: DateTime.now(),
                notes: _notesController.text,
              );
              ref.read(catchesProvider.notifier).addCatch(newCatch);
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}
