import '../../domain/entities/expense.dart';

/// Maps an [Expense] to and from an `expenses` table row. An expense with id
/// 0 is unsaved, so its id is omitted and SQLite assigns one.
class ExpenseRow {
  const ExpenseRow._();

  static const table = 'expenses';

  static Map<String, Object?> toMap(Expense expense) {
    return {
      if (expense.id != 0) 'id': expense.id,
      'vehicle_id': expense.vehicleId,
      'amount': expense.amount,
      'date': expense.date.millisecondsSinceEpoch,
      'odometer': expense.odometer,
      'category': expense.category,
    };
  }

  static Expense fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id']! as int,
      vehicleId: map['vehicle_id']! as int,
      amount: (map['amount']! as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']! as int),
      odometer: (map['odometer'] as num?)?.toDouble(),
      category: map['category']! as String,
    );
  }
}
