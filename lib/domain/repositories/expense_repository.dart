import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  /// Entries for a vehicle, in no particular order; callers sort as needed.
  Future<Result<List<Expense>>> getForVehicle(int vehicleId);
  Future<Result<Expense>> add(Expense expense);
  Future<Result<Unit>> delete(int id);
}
