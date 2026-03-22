import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../../domain/entities/refuel_entry.dart';
import '../../domain/repositories/refuel_repository.dart';
import '../daos/refuel_dao.dart';

/// [RefuelRepository] over sqflite. sqflite errors become [DatabaseFailure];
/// a missing id becomes [NotFoundFailure].
class RefuelRepositoryImpl implements RefuelRepository {
  const RefuelRepositoryImpl(this._dao);

  final RefuelDao _dao;

  @override
  Future<Result<List<RefuelEntry>>> getForVehicle(int vehicleId) async {
    try {
      return right(await _dao.getForVehicle(vehicleId));
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<RefuelEntry>> getById(int id) async {
    try {
      final entry = await _dao.getById(id);
      return entry == null
          ? left(NotFoundFailure('Entry $id does not exist.'))
          : right(entry);
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<RefuelEntry>> add(RefuelEntry entry) async {
    try {
      final id = await _dao.insert(entry);
      return right(entry.copyWith(id: id));
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<RefuelEntry>> update(RefuelEntry entry) async {
    try {
      final count = await _dao.update(entry);
      return count == 0
          ? left(NotFoundFailure('Entry ${entry.id} does not exist.'))
          : right(entry);
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
