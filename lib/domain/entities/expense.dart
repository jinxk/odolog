import 'package:equatable/equatable.dart';

/// A non-fuel cost against a vehicle: a tyre change, a repair, an insurance
/// premium, and so on. Kept deliberately narrow: an amount, a date, an
/// optional odometer reading, and one free-text category. A service log entry
/// with a cost is never mirrored here, so summing expenses and service costs
/// together never double counts a visit; see [ServiceLogEntry.cost].
class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.vehicleId,
    required this.amount,
    required this.date,
    this.odometer,
    required this.category,
  });

  final int id;
  final int vehicleId;
  final double amount;
  final DateTime date;

  /// Odometer reading at the time of the expense, in km. Optional: many
  /// expenses (insurance, a parking fine) have no meaningful reading.
  final double? odometer;

  /// Free text, not an enum: the UI offers suggestion chips (Service, Tyre,
  /// Repair, Insurance, Other) but any short phrase is accepted.
  final String category;

  Expense copyWith({
    int? id,
    int? vehicleId,
    double? amount,
    DateTime? date,
    double? odometer,
    String? category,
  }) {
    return Expense(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      odometer: odometer ?? this.odometer,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [id, vehicleId, amount, date, odometer, category];
}
