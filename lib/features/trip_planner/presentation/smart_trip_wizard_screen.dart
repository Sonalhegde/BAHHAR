import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../shared/widgets/custom_buttons.dart';

class SmartTripWizardScreen extends ConsumerStatefulWidget {
  const SmartTripWizardScreen({super.key});

  @override
  ConsumerState<SmartTripWizardScreen> createState() => _SmartTripWizardScreenState();
}

class _SmartTripWizardScreenState extends ConsumerState<SmartTripWizardScreen> {
  int _currentStep = 0;
  String _selectedSpecies = 'Kingfish (Kanaad)';
  String _boatType = 'Fiberglass Skiff 24-28ft';
  int _maxDistanceNmi = 15;
  String _departureTime = '05:00 AM (Dawn)';

  final _speciesOptions = [
    'Kingfish (Kanaad)',
    'Yellowfin Tuna (Thamad)',
    'Amberjack (Hamam)',
    'Spotted Grouper (Hamoor)',
    'Mahi Mahi (Anfaloos)',
  ];

  final _boatOptions = [
    'Traditional Wood Dhow',
    'Fiberglass Skiff 24-28ft',
    'Offshore Cruiser 32ft+',
    'Kayak / Shore Casting',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePure,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePure,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Smart Trip Planner', style: AppTextStyles.subhead),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderHairline, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Minimal step indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
              ),
              child: Row(
                children: List.generate(3, (idx) {
                  final isActive = idx == _currentStep;
                  final isPassed = idx < _currentStep;
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      color: isPassed || isActive ? AppColors.accentNavy : AppColors.borderHairline,
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStepContent(),
              ),
            ),

            // Bottom action footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfacePure,
                border: Border(top: BorderSide(color: AppColors.borderHairline)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: SecondaryButton(
                        label: 'Previous',
                        onPressed: () => setState(() => _currentStep--),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: _currentStep == 2 ? 'Generate Plan' : 'Next Step',
                      onPressed: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          // Complete wizard
                          context.push('/trip-recommendation');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STEP 1 OF 3', style: AppTextStyles.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Select Target Species', style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text('Bahhar uses species-specific thermal and depth profiles to calculate optimal routes.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ..._speciesOptions.map((s) {
              final isSelected = _selectedSpecies == s;
              return GestureDetector(
                onTap: () => setState(() => _selectedSpecies = s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surfaceSubtle : AppColors.surfacePure,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.accentNavy : AppColors.borderHairline,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isSelected ? AppColors.accentNavy : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 14),
                      Text(s, style: AppTextStyles.bodyMedium.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STEP 2 OF 3', style: AppTextStyles.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Vessel & Distance Range', style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text('Ensures fuel burn estimates and safety warnings match your hull capabilities.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Text('VESSEL CLASSIFICATION', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 10),
            ..._boatOptions.map((b) {
              final isSelected = _boatType == b;
              return GestureDetector(
                onTap: () => setState(() => _boatType = b),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surfaceSubtle : AppColors.surfacePure,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.accentNavy : AppColors.borderHairline,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isSelected ? AppColors.accentNavy : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 14),
                      Text(b, style: AppTextStyles.bodyMedium.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MAX CRUISE DISTANCE', style: AppTextStyles.sectionHeader),
                Text('$_maxDistanceNmi nmi', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            Slider(
              value: _maxDistanceNmi.toDouble(),
              min: 5,
              max: 50,
              divisions: 9,
              activeColor: AppColors.accentNavy,
              inactiveColor: AppColors.borderHairline,
              onChanged: (v) => setState(() => _maxDistanceNmi = v.round()),
            ),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STEP 3 OF 3', style: AppTextStyles.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Departure Time', style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text('Tidal phase calculations will calibrate around this planned launch window.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ...['04:30 AM (Pre-dawn)', '05:00 AM (Dawn)', '02:30 PM (Afternoon tide)', '05:30 PM (Dusk)'].map((t) {
              final isSelected = _departureTime == t;
              return GestureDetector(
                onTap: () => setState(() => _departureTime = t),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surfaceSubtle : AppColors.surfacePure,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.accentNavy : AppColors.borderHairline,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.access_time_rounded : Icons.access_time,
                        size: 20,
                        color: isSelected ? AppColors.accentNavy : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 14),
                      Text(t, style: AppTextStyles.bodyMedium.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
    }
  }
}\n