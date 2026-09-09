import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/polymorphic/soft_button.dart';

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
    return MarineBackground(
      child: Column(
        children: [
          // Glass App Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    } else {
                      context.pop();
                    }
                  },
                ),
                Text('Smart Trip Planner', style: AppTextStyles.subhead.copyWith(color: Colors.white)),
              ],
            ),
          ),

          // Glass Step Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(3, (idx) {
                final isActive = idx == _currentStep;
                final isPassed = idx < _currentStep;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isPassed || isActive
                          ? AppColors.cyanAccent
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.cyanAccent.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Action Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: SoftButton(
                      label: 'Previous',
                      style: SoftButtonStyle.glass,
                      onPressed: () => setState(() => _currentStep--),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SoftButton(
                    label: _currentStep == 2 ? 'Generate Calibrated Route' : 'Next Step',
                    onPressed: () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
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
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STEP 1 OF 3', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 4),
            Text('Select Target Species', style: AppTextStyles.screenTitle.copyWith(color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              'Route bathymetry and launch timing calibrate to the species thermal and feeding envelope.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ..._speciesOptions.map((s) {
              final isSelected = _selectedSpecies == s;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  level: isSelected ? GlassLevel.prominent : GlassLevel.standard,
                  borderRadius: GlassTokens.radiusMedium,
                  padding: const EdgeInsets.all(16),
                  onTap: () => setState(() => _selectedSpecies = s),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        s,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
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
            Text('STEP 2 OF 3', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 4),
            Text('Vessel & Cruising Range', style: AppTextStyles.screenTitle.copyWith(color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              'Ensures fuel burn estimates and seaworthiness match your boat profile.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ..._boatOptions.map((b) {
              final isSelected = _boatType == b;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  level: isSelected ? GlassLevel.prominent : GlassLevel.standard,
                  borderRadius: GlassTokens.radiusMedium,
                  padding: const EdgeInsets.all(16),
                  onTap: () => setState(() => _boatType = b),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        b,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MAX CRUISE RADIUS', style: AppTextStyles.sectionHeader),
                Text('$_maxDistanceNmi nmi', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.cyanAccent)),
              ],
            ),
            Slider(
              value: _maxDistanceNmi.toDouble(),
              min: 5,
              max: 50,
              divisions: 9,
              activeColor: AppColors.cyanAccent,
              inactiveColor: Colors.white.withValues(alpha: 0.15),
              onChanged: (v) => setState(() => _maxDistanceNmi = v.round()),
            ),
          ],
        );

      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STEP 3 OF 3', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 4),
            Text('Departure Time', style: AppTextStyles.screenTitle.copyWith(color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              'Tidal phases and surface wind calm periods will calibrate to this launch window.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ...['04:30 AM (Pre-dawn)', '05:00 AM (Dawn Slack)', '02:30 PM (Afternoon Tide)', '05:30 PM (Dusk)'].map((t) {
              final isSelected = _departureTime == t;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  level: isSelected ? GlassLevel.prominent : GlassLevel.standard,
                  borderRadius: GlassTokens.radiusMedium,
                  padding: const EdgeInsets.all(16),
                  onTap: () => setState(() => _departureTime = t),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 20,
                        color: isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        t,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
    }
  }
}
