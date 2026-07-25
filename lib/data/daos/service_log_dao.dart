import 'package:sqflite/sqflite.dart';

import '../../domain/entities/service_log_entry.dart';
import '../db/transaction_zone.dart';
import '../models/service_log_row.dart';

/// Raw SQL for the `service_log` table.
class ServiceLogDao {
  const ServiceLogDao(this._db);

  final DatabaseExecutor _db;

  DatabaseExecutor get _executor => currentExecutor(_db);

  /// Most recently performed first; a tie on the date falls back to id so the
  /// order is still deterministic.
  Future<List<ServiceLogEntry>> getForVehicle(int vehicleId) async {
    final rows = await _executor.query(
      ServiceLogRow.table,
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'performed_at DESC, id DESC',
    );
    return rows.map(ServiceLogRow.fromMap).toList();
  }

  Future<int> insert(ServiceLogEntry entry) {
    return _executor.insert(ServiceLogRow.table, ServiceLogRow.toMap(entry));
  }

  Future<int> delete(int id) {
    return _executor.delete(
      ServiceLogRow.table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
