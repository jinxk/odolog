import 'package:equatable/equatable.dart';

import 'window_mileage.dart';

class VehicleStats extends Equatable {
  const VehicleStats({
    required this.totalSpend,
    required this.totalDistance,
    required this.totalQuantity,
    this.averageMileage,
    this.averageCostPerKm,
    this.latestWindow,
    this.lastFillRange,
    this.projectedRange,
  });

  final double totalSpend;
  final double totalDistance;
  final double totalQuantity;
  final double? averageMileage;
  final double? averageCostPerKm;
  final WindowMileage? latestWindow;
  final double? lastFillRange;
  final double? projectedRange;

  @override
  List<Object?> get props => [
    totalSpend,
    totalDistance,
    totalQuantity,
    averageMileage,
    averageCostPerKm,
    latestWindow,
    lastFillRange,
    projectedRange,
  ];
}
