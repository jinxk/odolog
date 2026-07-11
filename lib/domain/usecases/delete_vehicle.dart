import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../repositories/vehicle_repository.dart';

class DeleteVehicle {
  const DeleteVehicle(this._repository);

  final VehicleRepository _repository;

  Future<Result<Unit>> execute(int id) => _repository.delete(id);
}
