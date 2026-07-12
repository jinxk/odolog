import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/expense.dart';
import 'package:odolog/domain/usecases/log_expense.dart';

import '../../helpers/fake_expense_repository.dart';

void main() {
  ValidationFailure validationOf(Either<Failure, Expense> result) {
    return result.getLeft().toNullable()! as ValidationFailure;
  }

  Expense expense({
    double amount = 500,
    DateTime? date,
    double? odometer,
    String category = 'Tyre',
  }) => Expense(
    id: 0,
    vehicleId: 1,
    amount: amount,
    date: date ?? DateTime.now(),
    odometer: odometer,
    category: category,
  );

  test('a zero amount is rejected', () async {
    final result = await LogExpense(
      FakeExpenseRepository(),
    ).execute(expense(amount: 0));

    expect(validationOf(result).field, 'amount');
  });

  test('an expense dated in the future is rejected', () async {
    final result = await LogExpense(
      FakeExpenseRepository(),
    ).execute(expense(date: DateTime.now().add(const Duration(days: 1))));

    expect(validationOf(result).field, 'date');
  });

  test('a negative odometer is rejected', () async {
    final result = await LogExpense(
      FakeExpenseRepository(),
    ).execute(expense(odometer: -1));

    expect(validationOf(result).field, 'odometer');
  });

  test('a blank category is rejected', () async {
    final result = await LogExpense(
      FakeExpenseRepository(),
    ).execute(expense(category: '  '));

    expect(validationOf(result).field, 'category');
  });

  test('a category containing a quote mark is rejected', () async {
    final result = await LogExpense(
      FakeExpenseRepository(),
    ).execute(expense(category: 'a "quoted" tag'));

    expect(validationOf(result).field, 'category');
  });

  test('a valid expense is stored and given an id', () async {
    final repo = FakeExpenseRepository();
    final result = await LogExpense(repo).execute(expense());

    final stored = result.getRight().toNullable()!;
    expect(stored.id, 1);
    expect(repo.expenses, hasLength(1));
  });
}
