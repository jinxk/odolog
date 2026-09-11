import 'package:fpdart/fpdart.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../daos/expense_dao.dart';

/// [ExpenseRepository] over sqflite. sqflite errors become [DatabaseFailure].
class ExpenseRepositoryImpl implements ExpenseRepository {
  const ExpenseRepositoryImpl(this._dao);

  final ExpenseDao _dao;

  @override
  Future<Result<List<Expense>>> getForVehicle(int vehicleId) async {
    try {
      return right(await _dao.getForVehicle(vehicleId));
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }

  @override
  Future<Result<Expense>> add(Expense expense) async {
    try {
      final id = await _dao.insert(expense);
      return right(expense.copyWith(id: id));
    } catch (error) {
      if (error is DatabaseException && error.isUniqueConstraintError()) {
        return left(DuplicateIdFailure(error.toString()));
      }
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
