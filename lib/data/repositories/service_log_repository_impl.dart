import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../../domain/entities/service_log_entry.dart';
import '../../domain/repositories/service_log_repository.dart';
import '../daos/service_log_dao.dart';

/// [ServiceLogRepository] over sqflite. sqflite errors become
/// [DatabaseFailure].
class ServiceLogRepositoryImpl implements ServiceLogRepository {
  const ServiceLogRepositoryImpl(this._dao);

  final ServiceLogDao _dao;

  @override
  Future<Result<List<ServiceLogEntry>>> getForVehicle(int vehicleId) async {
    try {
      return right(await _dao.getForVehicle(vehicleId));
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<ServiceLogEntry>> add(ServiceLogEntry entry) async {
    try {
      final id = await _dao.insert(entry);
      return right(entry.copyWith(id: id));
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
