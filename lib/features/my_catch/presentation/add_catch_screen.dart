import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/catches_provider.dart';
import '../../../core/models/catch_model.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/polymorphic/soft_button.dart';
import '../../../shared/polymorphic/glass_input.dart';

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
    return MarineBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
                Text('Log New Catch', style: AppTextStyles.subhead.copyWith(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Upload Dropzone in Glass
                  GestureDetector(
                    onTap: () {},
                    child: GlassContainer(
                      level: GlassLevel.standard,
                      borderRadius: GlassTokens.radiusMedium,
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.cyanAccent),
                            const SizedBox(height: 8),
                            Text('Tap to capture photo of catch', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('SPECIES', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1D31).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSpecies,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0A1D31),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanAccent),
                        items: _species.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSpecies = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: GlassInput(
                          controller: _weightController,
                          labelText: 'WEIGHT (KG)',
                          hintText: 'e.g. 7.5',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassInput(
                          controller: _lengthController,
                          labelText: 'LENGTH (CM)',
                          hintText: 'e.g. 88',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text('FISHING GEAR / METHOD', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1D31).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _gearUsed,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0A1D31),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanAccent),
                        items: _gearTypes.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _gearUsed = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Catch & Released', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                      Switch(
                        value: _released,
                        activeColor: AppColors.cyanAccent,
                        onChanged: (v) => setState(() => _released = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GlassInput(
                    controller: _notesController,
                    labelText: 'OBSERVATIONS & CONDITIONS',
                    hintText: 'Water clarity, sea birds, surface action...',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 28),
                  SoftButton(
                    label: 'Save Catch Record',
                    icon: Icons.check_circle_rounded,
                    onPressed: _saveCatch,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
