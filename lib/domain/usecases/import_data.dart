import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/vehicle_repository.dart';
import 'export_data.dart';

/// Writes a validated [DataBundle] back into the repositories. Parsing and
/// validating the incoming CSV or JSON into a bundle happens in the data layer
/// before it reaches this use case.
class ImportData {
  const ImportData(this._vehicleRepository, this._refuelRepository);

  final VehicleRepository _vehicleRepository;
  final RefuelRepository _refuelRepository;

  Future<Result<Unit>> execute(DataBundle bundle) async {
    for (final vehicle in bundle.vehicles) {
      final result = await _vehicleRepository.add(vehicle);
      final failure = result.getLeft().toNullable();
      if (failure != null) return left(failure);
    }
    for (final entry in bundle.entries) {
      final result = await _refuelRepository.add(entry);
      final failure = result.getLeft().toNullable();
      if (failure != null) return left(failure);
    }
    return right(unit);
  }
}
