import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/entities/expense.dart';
import 'package:odolog/domain/repositories/expense_repository.dart';

/// In-memory [ExpenseRepository] for use case tests. Expenses with id 0 are
/// treated as unsaved and get an assigned id on add, mimicking SQLite.
class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository([List<Expense> seed = const []]) {
    _expenses.addAll(seed);
    for (final expense in seed) {
      if (expense.id >= _nextId) _nextId = expense.id + 1;
    }
  }

  final List<Expense> _expenses = [];
  int _nextId = 1;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  @override
  Future<Result<Expense>> add(Expense expense) async {
    final stored = expense.id == 0 ? expense.copyWith(id: _nextId++) : expense;
    _expenses.add(stored);
    return right(stored);
  }

  @override
  Future<Result<Unit>> delete(int id) async {
    _expenses.removeWhere((e) => e.id == id);
    return right(unit);
  }

  @override
  Future<Result<List<Expense>>> getForVehicle(int vehicleId) async {
    return right(_expenses.where((e) => e.vehicleId == vehicleId).toList());
  }
}
