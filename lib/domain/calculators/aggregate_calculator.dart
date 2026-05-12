import '../entities/expense.dart';
import '../entities/refuel_entry.dart';
import '../entities/service_log_entry.dart';
import '../value_objects/vehicle_stats.dart';
import '../value_objects/window_mileage.dart';
import 'mileage_calculator.dart';

/// Lifetime and per-month rollups over a vehicle's entries. Averages are
/// distance weighted over closed full-tank windows, so a long window counts
/// for more than a short one. Pure Dart, like the mileage calculator.
class AggregateCalculator {
  const AggregateCalculator();

  /// [expenses] and [serviceLog] are optional: passing them folds their cost
  /// into [VehicleStats.nonFuelSpend] for the honest total cost of ownership
  /// figure. Leaving them out (the per month rollup does) yields a lifetime
  /// figure that is fuel only, same as before this existed.
  VehicleStats lifetime(
    List<RefuelEntry> entries, {
    double? tankCapacity,
    List<Expense> expenses = const [],
    List<ServiceLogEntry> serviceLog = const [],
  }) {
    const mileage = MileageCalculator();
    final closed = mileage.windows(entries);
    return VehicleStats(
      totalSpend: _sumSpend(entries),
      totalQuantity: _sumQuantity(entries),
      totalDistance: entries.isEmpty
          ? 0
          : _scopeDistance(entries, 0, entries.length - 1),
      averageMileage: _weightedMileage(closed),
      averageCostPerKm: _weightedCostPerKm(closed),
      latestWindow: mileage.latestWindow(entries),
      lastFillRange: mileage.lastFillRange(entries),
      projectedRange: mileage.projectedRange(entries, tankCapacity),
      nonFuelSpend: _sumNonFuelSpend(expenses, serviceLog),
    );
  }

  double _sumNonFuelSpend(
    List<Expense> expenses,
    List<ServiceLogEntry> serviceLog,
  ) {
    final expenseTotal = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final serviceTotal = serviceLog.fold(0.0, (sum, e) => sum + (e.cost ?? 0));
    return expenseTotal + serviceTotal;
  }

  /// One rollup per calendar month of `filledAt`, keyed by the first day of the
  /// month and inserted in chronological order.
  Map<DateTime, VehicleStats> monthly(List<RefuelEntry> entries) {
    final result = <DateTime, VehicleStats>{};
    if (entries.isEmpty) return result;

    const mileage = MileageCalculator();
    final closed = mileage.windows(entries);
    final entriesById = {for (final entry in entries) entry.id: entry};

    final indicesByMonth = <DateTime, List<int>>{};
    for (var i = 0; i < entries.length; i++) {
      final month = _monthKey(entries[i].filledAt);
      (indicesByMonth[month] ??= <int>[]).add(i);
    }

    final months = indicesByMonth.keys.toList()..sort();
    for (final month in months) {
      final indices = indicesByMonth[month]!;
      final scope = [for (final i in indices) entries[i]];
      final windowsInMonth = closed
          .where(
            (w) => _monthKey(entriesById[w.closingEntryId]!.filledAt) == month,
          )
          .toList();
      result[month] = VehicleStats(
        totalSpend: _sumSpend(scope),
        totalQuantity: _sumQuantity(scope),
        totalDistance: _scopeDistance(entries, indices.first, indices.last),
        averageMileage: _weightedMileage(windowsInMonth),
        averageCostPerKm: _weightedCostPerKm(windowsInMonth),
      );
    }
    return result;
  }

  // Distance across a scope counts the drive into the scope's first fill: it is
  // measured from the entry just before the scope began, or from the first
  // entry in scope when nothing precedes it.
  double _scopeDistance(List<RefuelEntry> entries, int lo, int hi) {
    final baseline = lo > 0 ? entries[lo - 1] : entries[lo];
    return entries[hi].odometer - baseline.odometer;
  }

  double _sumSpend(List<RefuelEntry> entries) =>
      entries.fold(0, (sum, e) => sum + e.pricePaid);

  double _sumQuantity(List<RefuelEntry> entries) =>
      entries.fold(0, (sum, e) => sum + e.quantity);

  double? _weightedMileage(List<WindowMileage> windows) {
    if (windows.isEmpty) return null;
    final distance = windows.fold(0.0, (sum, w) => sum + w.distance);
    final fuel = windows.fold(0.0, (sum, w) => sum + w.fuelConsumed);
    return distance / fuel;
  }

  double? _weightedCostPerKm(List<WindowMileage> windows) {
    if (windows.isEmpty) return null;
    final cost = windows.fold(0.0, (sum, w) => sum + w.costInWindow);
    final distance = windows.fold(0.0, (sum, w) => sum + w.distance);
    return cost / distance;
  }

  DateTime _monthKey(DateTime filledAt) =>
      DateTime(filledAt.year, filledAt.month);
}
