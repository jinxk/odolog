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
    this.nonFuelSpend = 0,
  });

  /// Fuel spend only: the sum of every refuel's price paid.
  final double totalSpend;
  final double totalDistance;
  final double totalQuantity;
  final double? averageMileage;
  final double? averageCostPerKm;
  final WindowMileage? latestWindow;
  final double? lastFillRange;
  final double? projectedRange;

  /// Everything that is not fuel: expenses plus the cost recorded against a
  /// logged service. Zero, never null, so it always sums cleanly with
  /// [totalSpend]; a scope that has not fetched this data (the per month
  /// rollup) leaves it at the default zero rather than mixing it in.
  final double nonFuelSpend;

  /// Fuel spend plus every non-fuel cost: the honest total cost of ownership
  /// figure, as opposed to [totalSpend] which is fuel only.
  double get totalCostOfOwnership => totalSpend + nonFuelSpend;

  /// [totalCostOfOwnership] per km of [totalDistance], or null before any
  /// distance has been driven. Unlike [averageCostPerKm], which is weighted
  /// over closed full tank windows, this divides straight through the
  /// lifetime totals, since non-fuel costs do not belong to any window.
  double? get costPerKmOfOwnership =>
      totalDistance > 0 ? totalCostOfOwnership / totalDistance : null;

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
    nonFuelSpend,
  ];
}
