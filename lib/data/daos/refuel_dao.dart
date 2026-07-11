import 'package:sqflite/sqflite.dart';

import '../../domain/entities/refuel_entry.dart';
import '../models/refuel_row.dart';

/// Raw SQL for the `refuel_entries` table. Takes a [DatabaseExecutor] so it
/// works on both a database and a transaction.
class RefuelDao {
  const RefuelDao(this._db);

  final DatabaseExecutor _db;

  /// Entries for a vehicle ordered by odometer, then by filled_at. The window
  /// walk relies on this sequence, and the composite index backs it.
  Future<List<RefuelEntry>> getForVehicle(int vehicleId) async {
    final rows = await _db.query(
      RefuelRow.table,
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'odometer, filled_at',
    );
    return rows.map(RefuelRow.fromMap).toList();
  }

  Future<RefuelEntry?> getById(int id) async {
    final rows = await _db.query(
      RefuelRow.table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : RefuelRow.fromMap(rows.first);
  }

  Future<int> insert(RefuelEntry entry) {
    return _db.insert(RefuelRow.table, RefuelRow.toMap(entry));
  }

  Future<int> update(RefuelEntry entry) {
    return _db.update(
      RefuelRow.table,
      RefuelRow.toMap(entry),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> delete(int id) {
    return _db.delete(RefuelRow.table, where: 'id = ?', whereArgs: [id]);
  }
}
