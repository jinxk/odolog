import '../../core/typedefs.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpenses {
  const GetExpenses(this._repository);

  final ExpenseRepository _repository;

  /// The vehicle's expenses, most recent first.
  Future<Result<List<Expense>>> execute(int vehicleId) async {
    final result = await _repository.getForVehicle(vehicleId);
    return result.map((expenses) {
      final sorted = List<Expense>.of(expenses)
        ..sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    });
  }
}
