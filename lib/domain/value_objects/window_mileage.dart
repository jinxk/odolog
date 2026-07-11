import 'package:equatable/equatable.dart';

class WindowMileage extends Equatable {
  const WindowMileage({
    required this.openingEntryId,
    required this.closingEntryId,
    required this.distance,
    required this.fuelConsumed,
    required this.mileage,
    required this.costInWindow,
    required this.costPerKm,
  });

  final int openingEntryId;
  final int closingEntryId;
  final double distance;
  final double fuelConsumed;
  final double mileage;
  final double costInWindow;
  final double costPerKm;

  @override
  List<Object?> get props => [
    openingEntryId,
    closingEntryId,
    distance,
    fuelConsumed,
    mileage,
    costInWindow,
    costPerKm,
  ];
}
