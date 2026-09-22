import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flow_field.dart';
import '../services/flow_field_service.dart';

final flowFieldServiceProvider =
    Provider<FlowFieldService>((ref) => FlowFieldService());

/// The shared wind/current grid behind the map's particle-flow layer.
/// Kept as one provider so the map, the trip wizard and any future chart
/// surface read the same frame of the same model run.
final flowFieldProvider = FutureProvider<FlowField>((ref) async {
  return ref.watch(flowFieldServiceProvider).getFlowField();
});
