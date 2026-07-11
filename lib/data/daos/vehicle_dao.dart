import 'package:sqflite/sqflite.dart';

import '../../domain/entities/vehicle.dart';
import '../models/vehicle_row.dart';

/// Raw SQL for the `vehicles` table. Takes a [DatabaseExecutor] so it works on
/// both a database and a transaction.
class VehicleDao {
  const VehicleDao(this._db);

  final DatabaseExecutor _db;

  Future<List<Vehicle>> getAll() async {
    final rows = await _db.query(VehicleRow.table, orderBy: 'id');
    return rows.map(VehicleRow.fromMap).toList();
  }

  Future<Vehicle?> getById(int id) async {
    final rows = await _db.query(
      VehicleRow.table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : VehicleRow.fromMap(rows.first);
  }

  Future<int> insert(Vehicle vehicle) {
    return _db.insert(VehicleRow.table, VehicleRow.toMap(vehicle));
  }

  Future<int> update(Vehicle vehicle) {
    return _db.update(
      VehicleRow.table,
      VehicleRow.toMap(vehicle),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> delete(int id) {
    return _db.delete(VehicleRow.table, where: 'id = ?', whereArgs: [id]);
  }
}
