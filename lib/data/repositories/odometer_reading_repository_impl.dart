import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../../domain/entities/odometer_reading.dart';
import '../../domain/repositories/odometer_reading_repository.dart';
import '../daos/odometer_reading_dao.dart';

/// [OdometerReadingRepository] over sqflite. sqflite errors become
/// [DatabaseFailure].
class OdometerReadingRepositoryImpl implements OdometerReadingRepository {
  const OdometerReadingRepositoryImpl(this._dao);

  final OdometerReadingDao _dao;

  @override
  Future<Result<List<OdometerReading>>> getForVehicle(int vehicleId) async {
    try {
      return right(await _dao.getForVehicle(vehicleId));
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<OdometerReading>> add(OdometerReading reading) async {
    try {
      final id = await _dao.insert(reading);
      return right(reading.copyWith(id: id));
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
