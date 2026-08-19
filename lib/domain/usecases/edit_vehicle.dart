import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';
import '../validators/text_input_validator.dart';

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
    final nameIssue = TextInputValidator.check(vehicle.name);
    if (nameIssue != null) {
      return Future.value(
        left(ValidationFailure(field: 'name', reason: nameIssue)),
      );
    }
    final registration = vehicle.registrationNo;
    if (registration != null) {
      final registrationIssue = TextInputValidator.check(registration);
      if (registrationIssue != null) {
        return Future.value(
          left(
            ValidationFailure(
              field: 'registrationNo',
              reason: registrationIssue,
            ),
          ),
        );
      }
    }
    final tankCapacity = vehicle.tankCapacity;
    if (tankCapacity != null && tankCapacity <= 0) {
      return Future.value(
        left(
          const ValidationFailure(
            field: 'tankCapacity',
            reason: 'Tank capacity must be greater than zero.',
          ),
        ),
      );
    }
    return _repository.update(vehicle);
  }
}
