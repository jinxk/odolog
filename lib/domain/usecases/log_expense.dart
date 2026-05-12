import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import '../validators/text_input_validator.dart';

class LogExpense {
  const LogExpense(this._repository);

  final ExpenseRepository _repository;

  Future<Result<Expense>> execute(Expense expense) async {
    if (expense.amount <= 0) {
      return left(
        const ValidationFailure(
          field: 'amount',
          reason: 'Amount must be greater than zero.',
        ),
      );
    }
    if (expense.date.isAfter(DateTime.now())) {
      return left(
        const ValidationFailure(
          field: 'date',
          reason: 'Date cannot be in the future.',
        ),
      );
    }
    final odometer = expense.odometer;
    if (odometer != null && odometer < 0) {
      return left(
        const ValidationFailure(
          field: 'odometer',
          reason: 'Odometer cannot be negative.',
        ),
      );
    }
    if (expense.category.trim().isEmpty) {
      return left(
        const ValidationFailure(
          field: 'category',
          reason: 'Category is required.',
        ),
      );
    }
    final issue = TextInputValidator.check(expense.category);
    if (issue != null) {
      return left(ValidationFailure(field: 'category', reason: issue));
    }
    return _repository.add(expense);
  }
}
