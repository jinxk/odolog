import '../../core/typedefs.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

/// Puts a deleted expense back at its original id, for the undo action on the
/// delete snack bar. No validation: the expense was valid when it was saved.
class RestoreExpense {
  const RestoreExpense(this._repository);

  final ExpenseRepository _repository;

  Future<Result<Expense>> execute(Expense expense) => _repository.add(expense);
}
