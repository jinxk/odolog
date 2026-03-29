import '../../domain/entities/refuel_entry.dart';
import '../../domain/entities/vehicle.dart';

/// Route arguments for the add and edit refuel screen. [existing] is null for a
/// new fill and set to the entry being edited otherwise.
class RefuelArgs {
  const RefuelArgs({required this.vehicle, this.existing});

  final Vehicle vehicle;
  final RefuelEntry? existing;
}
