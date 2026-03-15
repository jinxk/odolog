import '../../core/typedefs.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

class ListVehicles {
  const ListVehicles(this._repository);

  final VehicleRepository _repository;

  Future<Result<List<Vehicle>>> execute() => _repository.getAll();
}
