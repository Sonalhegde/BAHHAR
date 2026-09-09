import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/fuel_calculator_service.dart';
import '../../../shared/widgets/trip_stepper.dart';
import '../../../shared/widgets/custom_buttons.dart';

class SmartTripWizardScreen extends ConsumerStatefulWidget {
  const SmartTripWizardScreen({super.key});

  @override
  ConsumerState<SmartTripWizardScreen> createState() => _SmartTripWizardScreenState();
}

class _SmartTripWizardScreenState extends ConsumerState<SmartTripWizardScreen> {
  int _currentStep = 0;

  final List<String> _speciesList = ['Kingfish', 'Yellowfin Tuna', 'Hammour', 'Queenfish', 'Mahi-Mahi'];
  final List<(String, double, double)> _ports = [
    ('Marina Bandar Al Rowdha (Muscat)', 23.5786, 58.6083),
    ('Seeb Fishing Port', 23.6833, 58.1833),
    ('Muttrah Port', 23.6267, 58.5633),
    ('Sur Fishing Port', 22.5667, 59.5289),
    ('Sohar Port', 24.3667, 56.7333),
    ('Khasab Port (Musandam)', 26.1989, 56.2486),
  ];

  @override
  Widget build(BuildContext context) {
    final tripPlan = ref.watch(tripPlanProvider);
    final notifier = ref.read(tripPlanProvider.notifier);

    final steps = [
      TripStepData(
        title: 'Target Species',
        subtitle: tripPlan.targetSpecies,
        content: Wrap(
          spacing: 8,
          children: _speciesList.map((s) {
            final isSel = tripPlan.targetSpecies == s;
            return ChoiceChip(
              label: Text(s),
              selected: isSel,
              selectedColor: AppColors.deepSea,
              labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
              onSelected: (_) => notifier.updateSpecies(s),
            );
          }).toList(),
        ),
      ),
      TripStepData(
        title: 'Starting Departure Port',
        subtitle: tripPlan.departurePort,
        content: Column(
          children: _ports.map((p) {
            return RadioListTile<String>(
              title: Text(p.$1, style: const TextStyle(fontSize: 14)),
              value: p.$1,
              groupValue: tripPlan.departurePort,
              activeColor: AppColors.oceanBlue,
              onChanged: (val) {
                if (val != null) notifier.updatePort(p.$1, p.$2, p.$3);
              },
            );
          }).toList(),
        ),
      ),
      TripStepData(
        title: 'Departure Date & Time',
        subtitle: 'Tomorrow at 05:30 AM (Optimal Tide)',
        content: const Padding(
          padding: EdgeInsetsDirectional.all(8.0),
          child: Text('Engine calculated best departure time: 05:30 AM to hit sunrise slack tide.'),
        ),
      ),
      TripStepData(
        title: 'Trip Duration',
        subtitle: '${tripPlan.durationHours} Hours',
        content: Slider(
          value: tripPlan.durationHours.toDouble(),
          min: 3,
          max: 12,
          divisions: 9,
          label: '${tripPlan.durationHours} Hours',
          activeColor: AppColors.oceanBlue,
          onChanged: (val) => notifier.updateDuration(val.round()),
        ),
      ),
      TripStepData(
        title: 'Boat & Outboard Profile',
        subtitle: tripPlan.selectedBoat.name,
        content: Column(
          children: FuelCalculatorService.availableBoats.map((b) {
            return RadioListTile<String>(
              title: Text(b.name, style: const TextStyle(fontSize: 14)),
              subtitle: Text('${b.horsepower} HP • ${b.litersPerNauticalMile} L/nm'),
              value: b.id,
              groupValue: tripPlan.selectedBoat.id,
              activeColor: AppColors.oceanBlue,
              onChanged: (_) => notifier.updateBoat(b),
            );
          }).toList(),
        ),
      ),
      TripStepData(
        title: 'Max Fuel Budget',
        subtitle: '${tripPlan.maxBudgetOmr.toStringAsFixed(0)} OMR',
        content: Slider(
          value: tripPlan.maxBudgetOmr,
          min: 15,
          max: 100,
          divisions: 17,
          label: '${tripPlan.maxBudgetOmr.round()} OMR',
          activeColor: AppColors.sandGold,
          onChanged: notifier.updateBudget,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Trip Planner'),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16.0),
        children: [
          TripStepper(
            currentStep: _currentStep,
            steps: steps,
            onStepTapped: (idx) => setState(() => _currentStep = idx),
          ),
          const SizedBox(height: 16),
          BahharPrimaryButton(
            label: 'Find Best Trip Recommendations',
            icon: Icons.search,
            onPressed: () => context.push('/smart-trip-results'),
          ),
        ],
      ),
    );
  }
}
