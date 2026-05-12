import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../repositories/expense_repository.dart';

class DeleteExpense {
  const DeleteExpense(this._repository);

  final ExpenseRepository _repository;

  Future<Result<Unit>> execute(int id) => _repository.delete(id);
}
