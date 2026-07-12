import 'package:sqflite/sqflite.dart';

import '../../domain/entities/expense.dart';
import '../models/expense_row.dart';

/// Raw SQL for the `expenses` table.
class ExpenseDao {
  const ExpenseDao(this._db);

  final DatabaseExecutor _db;

  /// Most recent first; a tie on the date falls back to id so the order is
  /// still deterministic.
  Future<List<Expense>> getForVehicle(int vehicleId) async {
    final rows = await _db.query(
      ExpenseRow.table,
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(ExpenseRow.fromMap).toList();
  }

  Future<int> insert(Expense expense) {
    return _db.insert(ExpenseRow.table, ExpenseRow.toMap(expense));
  }

  Future<int> delete(int id) {
    return _db.delete(ExpenseRow.table, where: 'id = ?', whereArgs: [id]);
  }
}
