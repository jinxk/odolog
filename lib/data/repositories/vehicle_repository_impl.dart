import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../daos/vehicle_dao.dart';

/// [VehicleRepository] over sqflite. sqflite errors become [DatabaseFailure];
/// a missing id becomes [NotFoundFailure].
class VehicleRepositoryImpl implements VehicleRepository {
  const VehicleRepositoryImpl(this._dao);

  final VehicleDao _dao;

  @override
  Future<Result<List<Vehicle>>> getAll() async {
    try {
      return right(await _dao.getAll());
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<Vehicle>> getById(int id) async {
    try {
      final vehicle = await _dao.getById(id);
      return vehicle == null
          ? left(NotFoundFailure('Vehicle $id does not exist.'))
          : right(vehicle);
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<Vehicle>> add(Vehicle vehicle) async {
    try {
      final id = await _dao.insert(vehicle);
      return right(vehicle.copyWith(id: id));
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<Vehicle>> update(Vehicle vehicle) async {
    try {
      final count = await _dao.update(vehicle);
      return count == 0
          ? left(NotFoundFailure('Vehicle ${vehicle.id} does not exist.'))
          : right(vehicle);
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<Unit>> delete(int id) async {
    try {
      await _dao.delete(id);
      return right(unit);
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }
}
