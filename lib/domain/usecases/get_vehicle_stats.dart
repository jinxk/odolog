import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../calculators/aggregate_calculator.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../value_objects/vehicle_stats.dart';

class GetVehicleStats {
  const GetVehicleStats(this._vehicleRepository, this._refuelRepository);

  final VehicleRepository _vehicleRepository;
  final RefuelRepository _refuelRepository;

  Future<Result<VehicleStats>> execute(int vehicleId) async {
    final vehicleResult = await _vehicleRepository.getById(vehicleId);
    return vehicleResult.match(
      (failure) => Future<Result<VehicleStats>>.value(left(failure)),
      (vehicle) async {
        final entriesResult = await _refuelRepository.getForVehicle(vehicleId);
        return entriesResult.map(
          (entries) => const AggregateCalculator().lifetime(
            entries,
            tankCapacity: vehicle.tankCapacity,
          ),
        );
      },
    );
  }
}
