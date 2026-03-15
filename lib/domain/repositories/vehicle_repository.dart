import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../entities/vehicle.dart';

abstract class VehicleRepository {
  Future<Result<List<Vehicle>>> getAll();
  Future<Result<Vehicle>> getById(int id);
  Future<Result<Vehicle>> add(Vehicle vehicle);
  Future<Result<Vehicle>> update(Vehicle vehicle);
  Future<Result<Unit>> delete(int id);
}
