import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../entities/refuel_entry.dart';
import '../entities/vehicle.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/vehicle_repository.dart';

/// The full set of vehicles and their entries. Encoding this bundle to CSV or a
/// JSON backup file is the data layer's job; the use case only assembles it.
typedef DataBundle = ({List<Vehicle> vehicles, List<RefuelEntry> entries});

class ExportData {
  const ExportData(this._vehicleRepository, this._refuelRepository);

  final VehicleRepository _vehicleRepository;
  final RefuelRepository _refuelRepository;

  Future<Result<DataBundle>> execute() async {
    final vehiclesResult = await _vehicleRepository.getAll();
    return vehiclesResult.match(
      (failure) => Future<Result<DataBundle>>.value(left(failure)),
      (vehicles) async {
        final entries = <RefuelEntry>[];
        for (final vehicle in vehicles) {
          final entriesResult = await _refuelRepository.getForVehicle(
            vehicle.id,
          );
          final failure = entriesResult.match<Failure?>((f) => f, (
            vehicleEntries,
          ) {
            entries.addAll(vehicleEntries);
            return null;
          });
          if (failure != null) return left(failure);
        }
        return right((vehicles: vehicles, entries: entries));
      },
    );
  }
}
