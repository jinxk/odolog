import 'package:sqflite/sqflite.dart';

import '../../domain/entities/vehicle.dart';
import '../db/transaction_zone.dart';
import '../models/vehicle_row.dart';

/// Raw SQL for the `vehicles` table. Every statement runs on the transaction
/// in flight when there is one, otherwise on the database it was built with.
class VehicleDao {
  const VehicleDao(this._db);

  final DatabaseExecutor _db;

  DatabaseExecutor get _executor => currentExecutor(_db);

  Future<List<Vehicle>> getAll() async {
    final rows = await _executor.query(VehicleRow.table, orderBy: 'id');
    return rows.map(VehicleRow.fromMap).toList();
  }

  Future<Vehicle?> getById(int id) async {
    final rows = await _executor.query(
      VehicleRow.table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : VehicleRow.fromMap(rows.first);
  }

  Future<int> insert(Vehicle vehicle) {
    return _executor.insert(VehicleRow.table, VehicleRow.toMap(vehicle));
  }

  Future<int> update(Vehicle vehicle) {
    return _executor.update(
      VehicleRow.table,
      VehicleRow.toMap(vehicle),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> delete(int id) {
    return _executor.delete(VehicleRow.table, where: 'id = ?', whereArgs: [id]);
  }
}
