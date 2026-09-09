import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/catches_provider.dart';
import '../../../core/models/catch_model.dart';
import '../../../shared/widgets/custom_buttons.dart';

class AddCatchScreen extends ConsumerStatefulWidget {
  const AddCatchScreen({super.key});

  @override
  ConsumerState<AddCatchScreen> createState() => _AddCatchScreenState();
}

class _AddCatchScreenState extends ConsumerState<AddCatchScreen> {
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedSpecies = 'Kingfish (Kanaad)';
  String _gearUsed = 'Trolling Lure';
  bool _released = false;

  final _species = [
    'Kingfish (Kanaad)',
    'Yellowfin Tuna (Thamad)',
    'Hamoor (Grouper)',
    'Amberjack (Hamam)',
    'Sailfish (Faras)',
    'Emperor (Shaari)',
    'Queenfish (Dhabsa)',
  ];

  final _gearTypes = [
    'Trolling Lure',
    'Deep Drop Jig',
    'Live Bait Line',
    'Bottom Bait Rig',
    'Popper / Topwater',
  ];

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveCatch() {
    final weight = double.tryParse(_weightController.text) ?? 4.5;
    final length = double.tryParse(_lengthController.text) ?? 65.0;

    final newCatch = CatchModel(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_default',
      species: _selectedSpecies,
      speciesArabic: 'كنعد',
      weightKg: weight,
      lengthCm: length,
      timestamp: DateTime.now(),
      latitude: 23.635,
      longitude: 58.552,
      locationName: 'Fahal Island Shelf',
      lureOrBait: _gearUsed,
      released: _released,
      notes: _notesController.text,
    );

    ref.read(catchesListProvider.notifier).addCatch(newCatch);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catch successfully logged')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePure,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePure,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Log New Catch', style: AppTextStyles.subhead),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderHairline, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Upload Placeholder
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    Text('Tap to add photo of catch', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('SPECIES', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfacePure,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSpecies,
                  isExpanded: true,
                  items: _species.map((s) => DropdownMenuItem(value: s, child: Text(s, style: AppTextStyles.bodyMedium))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSpecies = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WEIGHT (KG)', style: AppTextStyles.sectionHeader),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 6.2'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LENGTH (CM)', style: AppTextStyles.sectionHeader),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lengthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 78'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text('FISHING GEAR / METHOD', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfacePure,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _gearUsed,
                  isExpanded: true,
                  items: _gearTypes.map((g) => DropdownMenuItem(value: g, child: Text(g, style: AppTextStyles.bodyMedium))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _gearUsed = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Catch & Released', style: AppTextStyles.bodyMedium),
                Switch(
                  value: _released,
                  activeColor: AppColors.accentNavy,
                  onChanged: (v) => setState(() => _released = v),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text('NOTES & OBSERVATIONS', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Water clarity, sea bird activity, bait schools...',
              ),
            ),

            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Save Catch Record',
              onPressed: _saveCatch,
            ),
          ],
        ),
      ),
    );
  }
}\n