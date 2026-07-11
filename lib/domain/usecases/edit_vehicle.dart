import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

class EditVehicle {
  const EditVehicle(this._repository);

  final VehicleRepository _repository;

  Future<Result<Vehicle>> execute(Vehicle vehicle) {
    if (vehicle.name.trim().isEmpty) {
      return Future.value(
        left(
          const ValidationFailure(field: 'name', reason: 'Name is required.'),
        ),
      );
    }
    return _repository.update(vehicle);
  }
}
