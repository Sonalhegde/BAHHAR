import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/polymorphic/soft_button.dart';

/// 4-step Smart Trip wizard. Every step writes into tripPlanProvider (the
/// TripRequest object); the final step hands off to TripService.planTrip via
/// the trip-recommendation route.
class SmartTripWizardScreen extends ConsumerStatefulWidget {
  const SmartTripWizardScreen({super.key});

  @override
  ConsumerState<SmartTripWizardScreen> createState() =>
      _SmartTripWizardScreenState();
}

class _SmartTripWizardScreenState extends ConsumerState<SmartTripWizardScreen> {
  int _currentStep = 0;

  final _speciesOptions = [
    'Kingfish (Kanaad)',
    'Yellowfin Tuna (Thamad)',
    'Amberjack (Hamam)',
    'Spotted Grouper (Hamoor)',
    'Mahi Mahi (Anfaloos)',
  ];

  // Starting points with real marina/ port coordinates.
  final _startingPoints = const [
    ('Marina Bandar Al Rowdha (Muscat)', 23.5786, 58.6083),
    ('Muscat Hills Marina (Seeb)', 23.6805, 58.4700),
    ('Sur Port (Ash Sharqiyah)', 22.5619, 59.5297),
    ('Marina Bander Al Rowdha South', 23.5236, 58.6519),
  ];

  final _boatOptions = [
    'Traditional Wood Dhow',
    'Fiberglass Skiff 24-28ft',
    'Offshore Cruiser 32ft+',
    'Kayak / Shore Casting',
  ];

  final _departureSlots = const [
    ('04:30 AM (Pre-dawn)', 4),
    ('05:00 AM (Dawn Slack)', 5),
    ('02:30 PM (Afternoon Tide)', 14),
    ('05:30 PM (Dusk)', 17),
  ];

  // Date selection: today or the next three days.
  late final List<DateTime> _dateOptions = List.generate(
    4,
    (i) => DateTime.now().add(Duration(days: i)),
  );
  int _selectedDateIndex = 0;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(tripPlanProvider);

    return MarineBackground(
      child: Column(
        children: [
          // Glass App Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    } else {
                      context.pop();
                    }
                  },
                ),
                Text('Smart Trip Planner',
                    style: AppTextStyles.subhead
                        .copyWith(color: Colors.white)),
              ],
            ),
          ),

          // Glass Step Progress Bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(4, (idx) {
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
                                color: AppColors.cyanAccent
                                    .withValues(alpha: 0.6),
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
              child: _buildStepContent(plan),
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
                    label: _currentStep == 3
                        ? 'Generate Calibrated Route'
                        : 'Next Step',
                    onPressed: () {
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        // TripRequest is complete; hand off to the planner.
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

  Widget _buildStepContent(TripRequest plan) {
    switch (_currentStep) {
      case 0:
        return _stepShell(
          stepLabel: 'STEP 1 OF 4',
          title: 'Select Target Species',
          subtitle:
              'Route bathymetry and launch timing calibrate to the species thermal and feeding envelope.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _optionList(
              _speciesOptions,
              selected: plan.targetSpecies,
              onSelected: (s) => ref
                  .read(tripPlanProvider.notifier)
                  .updateSpecies(s),
            ),
          ),
        );

      case 1:
        return _stepShell(
          stepLabel: 'STEP 2 OF 4',
          title: 'Starting Point',
          subtitle:
              'Departure marina or port — used for distance, fuel and bearing calculations.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _optionList(
              _startingPoints.map((p) => p.$1).toList(),
              selected: plan.departurePort,
              onSelected: (portLabel) {
                final match =
                    _startingPoints.firstWhere((p) => p.$1 == portLabel);
                ref.read(tripPlanProvider.notifier).updateStartingPoint(
                      match.$1,
                      match.$2,
                      match.$3,
                    );
              },
            ),
          ),
        );

      case 2:
        return _stepShell(
          stepLabel: 'STEP 3 OF 4',
          title: 'Vessel & Cruising Range',
          subtitle:
              'Ensures fuel burn estimates and seaworthiness match your boat profile.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._optionList(
                _boatOptions,
                selected: plan.vesselType,
                onSelected: (b) => ref
                    .read(tripPlanProvider.notifier)
                    .updateVesselType(b),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MAX CRUISE RADIUS',
                      style: AppTextStyles.sectionHeader),
                  Text('${plan.maxRadiusNmi} nmi',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.cyanAccent)),
                ],
              ),
              Slider(
                value: plan.maxRadiusNmi.toDouble(),
                min: 5,
                max: 50,
                divisions: 9,
                activeColor: AppColors.cyanAccent,
                inactiveColor: Colors.white.withValues(alpha: 0.15),
                onChanged: (v) => ref
                    .read(tripPlanProvider.notifier)
                    .updateMaxRadius(v.round()),
              ),
            ],
          ),
        );

      case 3:
      default:
        return _stepShell(
          stepLabel: 'STEP 4 OF 4',
          title: 'Trip Date & Departure',
          subtitle:
              'Tidal phases and surface wind calm periods will calibrate to this launch window.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._dateOptions.asMap().entries.map((entry) {
                final dt = entry.value;
                final isSelected = entry.key == _selectedDateIndex;
                final label = entry.key == 0
                    ? 'Today — ${_fmtDate(dt)}'
                    : _fmtDate(dt);
                return _optionTile(
                  label,
                  icon: Icons.calendar_today_outlined,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedDateIndex = entry.key);
                    _syncDepartureTime(plan.departureSlotLabel);
                  },
                );
              }),
              const SizedBox(height: 8),
              ..._departureSlots.map((slot) {
                final isSelected =
                    plan.departureSlotLabel == slot.$1;
                return _optionTile(
                  slot.$1,
                  icon: Icons.access_time_rounded,
                  isSelected: isSelected,
                  onTap: () {
                    final date = _dateOptions[_selectedDateIndex];
                    final when = DateTime(date.year, date.month, date.day,
                        slot.$2, 0);
                    ref
                        .read(tripPlanProvider.notifier)
                        .updateDeparture(when, slot.$1);
                  },
                );
              }),
            ],
          ),
        );
    }
  }

  /// Keeps departureTime aligned with the selected date when the date changes.
  void _syncDepartureTime(String slotLabel) {
    final slot = _departureSlots.firstWhere(
      (s) => s.$1 == slotLabel,
      orElse: () => _departureSlots.first,
    );
    final date = _dateOptions[_selectedDateIndex];
    final when =
        DateTime(date.year, date.month, date.day, slot.$2, 0);
    ref
        .read(tripPlanProvider.notifier)
        .updateDeparture(when, slot.$1);
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _stepShell({
    required String stepLabel,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(stepLabel, style: AppTextStyles.sectionHeader),
        const SizedBox(height: 4),
        Text(title,
            style: AppTextStyles.screenTitle
                .copyWith(color: Colors.white)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        child,
      ],
    );
  }

  List<Widget> _optionList(
    List<String> options, {
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return options
        .map((o) => _optionTile(o,
            isSelected: selected == o, onTap: () => onSelected(o)))
        .toList();
  }

  Widget _optionTile(
    String label, {
    IconData icon = Icons.radio_button_off_rounded,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        level: isSelected ? GlassLevel.prominent : GlassLevel.standard,
        borderRadius: GlassTokens.radiusMedium,
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : icon,
              size: 20,
              color: isSelected
                  ? AppColors.cyanAccent
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
