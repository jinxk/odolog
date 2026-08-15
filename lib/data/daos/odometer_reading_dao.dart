import 'package:sqflite/sqflite.dart';

import '../../domain/entities/odometer_reading.dart';
import '../db/transaction_zone.dart';
import '../models/odometer_reading_row.dart';

/// Raw SQL for the `odometer_readings` table. Every statement runs on the
/// transaction in flight when there is one, otherwise on the database it was
/// built with.
class OdometerReadingDao {
  const OdometerReadingDao(this._db);

  final DatabaseExecutor _db;

  DatabaseExecutor get _executor => currentExecutor(_db);

  /// Readings for a vehicle ordered by odometer, then by recorded_at, the same
  /// sequence the refuel query uses.
  Future<List<OdometerReading>> getForVehicle(int vehicleId) async {
    final rows = await _executor.query(
      OdometerReadingRow.table,
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'odometer, recorded_at',
    );
    return rows.map(OdometerReadingRow.fromMap).toList();
  }

  Future<int> insert(OdometerReading reading) {
    return _executor.insert(
      OdometerReadingRow.table,
      OdometerReadingRow.toMap(reading),
    );
  }

  Future<int> delete(int id) {
    return _executor.delete(
      OdometerReadingRow.table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
