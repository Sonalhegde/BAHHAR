import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/catches_provider.dart';
import '../../../core/providers/marine_provider.dart';
import '../../../core/models/catch_model.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/polymorphic/soft_button.dart';
import '../../../shared/polymorphic/glass_input.dart';

/// Log-a-catch form: real photo capture via image_picker, GPS autofill via
/// geolocator, Storage upload + Firestore save through catchesProvider.
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
  bool _saving = false;
  String? _saveError;

  // Photo state
  File? _photoFile;
  final ImagePicker _picker = ImagePicker();

  // GPS state
  double? _latitude;
  double? _longitude;
  String _locationName = 'Fahal Island Shelf';
  String? _locationStatus;

  final _species = [
    'Kingfish (Kanaad)',
    'Yellowfin Tuna (Thamad)',
    'Hamoor (Grouper)',
    'Amberjack (Hamam)',
    'Sailfish (Faris)',
    'Emperor (Shaari)',
    'Queenfish (Dhabsa)',
  ];

  static const _speciesArabic = {
    'Kingfish (Kanaad)': 'كنعد',
    'Yellowfin Tuna (Thamad)': 'ثمد',
    'Hamoor (Grouper)': 'هامور',
    'Amberjack (Hamam)': 'حمام',
    'Sailfish (Faras)': 'فرس',
    'Emperor (Shaari)': 'شعري',
    'Queenfish (Dhabsa)': 'ضبسة',
  };

  final _gearTypes = [
    'Trolling Lure',
    'Deep Drop Jig',
    'Live Bait Line',
    'Bottom Bait Rig',
    'Popper / Topwater',
  ];

  @override
  void initState() {
    super.initState();
    _autofillLocation();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (picked != null) {
        setState(() {
          _photoFile = File(picked.path);
          _saveError = null;
        });
      }
    } catch (e) {
      setState(() => _saveError = 'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e');
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Fills the location fields from device GPS (with permission handling).
  Future<void> _autofillLocation() async {
    setState(() => _locationStatus = 'Locating…');
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationStatus =
            'GPS permission denied — using default location');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.best));
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationName =
            'GPS ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _locationStatus = null;
      });
    } catch (e) {
      setState(() => _locationStatus = 'GPS unavailable — using default location');
    }
  }

  Future<void> _saveCatch() async {
    if (_saving) return;
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      setState(() => _saveError = 'Enter the catch weight in kg.');
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    final marine = ref.read(marineConditionsProvider).valueOrNull;

    final newCatch = CatchModel(
      id: 'catch_${DateTime.now().millisecondsSinceEpoch}',
      speciesName: _selectedSpecies,
      speciesNameAr: _speciesArabic[_selectedSpecies] ?? '',
      weightKg: weight,
      lengthCm: double.tryParse(_lengthController.text),
      locationName: _locationName,
      latitude: _latitude ?? 23.635,
      longitude: _longitude ?? 58.552,
      caughtAt: DateTime.now(),
      notes: _notesController.text,
      seaTempC: marine?.seaTemperatureC,
      waveHeightM: marine?.waveHeightM,
      baitOrLure: _gearUsed,
      released: _released,
    );

    try {
      await ref.read(catchesProvider.notifier).addCatch(
            newCatch,
            photoPath: _photoFile?.path,
          );
      if (!mounted) return;
      // Success feedback before returning to Catch History.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catch successfully logged'),
          backgroundColor: AppColors.signalGood,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Failed to save catch: $e';
      });
    }
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
                Text('Log New Catch',
                    style: AppTextStyles.subhead
                        .copyWith(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo capture — camera or gallery
                  GestureDetector(
                    onTap: _showPhotoSourceSheet,
                    child: GlassContainer(
                      level: GlassLevel.standard,
                      borderRadius: GlassTokens.radiusMedium,
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: _photoFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _photoFile!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                children: [
                                  const Icon(Icons.camera_alt_outlined,
                                      size: 36,
                                      color: AppColors.cyanAccent),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to capture or choose photo of catch',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('SPECIES', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _selectedSpecies,
                    items: _species,
                    onChanged: (v) =>
                        setState(() => _selectedSpecies = v ?? _selectedSpecies),
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

                  // Location — GPS autofilled
                  const Text('LOCATION (GPS)', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 6),
                  GlassContainer(
                    level: GlassLevel.standard,
                    borderRadius: GlassTokens.radiusMedium,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    onTap: _autofillLocation,
                    child: Row(
                      children: [
                        const Icon(Icons.my_location_rounded,
                            size: 18, color: AppColors.cyanAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_locationName,
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: Colors.white)),
                              if (_locationStatus != null)
                                Text(_locationStatus!,
                                    style: AppTextStyles.caption.copyWith(
                                        fontSize: 10,
                                        color: AppColors.signalCaution)),
                            ],
                          ),
                        ),
                        Text('Refresh',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.cyanAccent)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('FISHING GEAR / METHOD',
                      style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _gearUsed,
                    items: _gearTypes,
                    onChanged: (v) =>
                        setState(() => _gearUsed = v ?? _gearUsed),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Catch & Released',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white)),
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

                  if (_saveError != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.signalAlertBg,
                        borderRadius:
                            BorderRadius.circular(GlassTokens.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 16, color: AppColors.signalAlert),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_saveError!,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.signalAlert,
                                    fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  SoftButton(
                    label: _saving ? 'Saving…' : 'Save Catch Record',
                    icon: Icons.check_circle_rounded,
                    isLoading: _saving,
                    onPressed: _saving ? null : _saveCatch,
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1D31).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF0A1D31),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.cyanAccent),
          items: items
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s,
                      style: const TextStyle(color: Colors.white))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
