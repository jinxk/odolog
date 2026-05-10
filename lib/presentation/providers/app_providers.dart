import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/typedefs.dart';
import '../../domain/calculators/aggregate_calculator.dart';
import '../../domain/calculators/mileage_calculator.dart';
import '../../domain/entities/fuel_variant.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_vehicle_history.dart';
import '../../domain/value_objects/vehicle_stats.dart';
import '../../domain/value_objects/window_mileage.dart';
import 'usecases.dart';

part 'app_providers.g.dart';

/// Unwraps a use case [Result], throwing the failure so it lands in the
/// surrounding AsyncValue.error for the UI to map.
T _unwrap<T>(Result<T> result) =>
    result.match((failure) => throw failure, (value) => value);

/// The id of the vehicle the dashboard and stats read from. Session scoped and
/// kept alive so switching screens does not lose the selection. Null means fall
/// back to the first vehicle.
@Riverpod(keepAlive: true)
class ActiveVehicleId extends _$ActiveVehicleId {
  @override
  int? build() => null;

  void select(int? id) => state = id;
}

@riverpod
Future<List<Vehicle>> vehicleList(Ref ref) async {
  final result = await ref.watch(listVehiclesProvider).execute();
  return _unwrap(result);
}

/// The vehicle currently in focus: the selected one when set and still present,
/// otherwise the first vehicle, or null when there are none.
@riverpod
Future<Vehicle?> currentVehicle(Ref ref) async {
  final vehicles = await ref.watch(vehicleListProvider.future);
  if (vehicles.isEmpty) return null;
  final selectedId = ref.watch(activeVehicleIdProvider);
  for (final vehicle in vehicles) {
    if (vehicle.id == selectedId) return vehicle;
  }
  return vehicles.first;
}

@riverpod
Future<VehicleStats> vehicleStats(Ref ref, int vehicleId) async {
  final result = await ref.watch(getVehicleStatsProvider).execute(vehicleId);
  return _unwrap(result);
}

@riverpod
Future<List<HistoryItem>> history(Ref ref, int vehicleId) async {
  final result = await ref.watch(getVehicleHistoryProvider).execute(vehicleId);
  return _unwrap(result);
}

/// Per calendar month rollups for the stats screen and the this month card,
/// keyed by the first day of each month in chronological order.
@riverpod
Future<Map<DateTime, VehicleStats>> vehicleMonthly(
  Ref ref,
  int vehicleId,
) async {
  final items = await ref.watch(historyProvider(vehicleId).future);
  final entries = [for (final item in items) item.entry];
  return const AggregateCalculator().monthly(entries);
}

/// The closed full tank windows for a vehicle, one point per window, for the
/// mileage trend on the home and stats screens.
@riverpod
Future<List<WindowMileage>> vehicleWindows(Ref ref, int vehicleId) async {
  final items = await ref.watch(historyProvider(vehicleId).future);
  final entries = [for (final item in items) item.entry];
  return const MileageCalculator().windows(entries);
}

@riverpod
Future<List<FuelVariant>> catalog(Ref ref, FuelCategory category) async {
  final result = await ref
      .watch(loadFuelCatalogProvider)
      .execute(category: category);
  return _unwrap(result);
}

/// Keeps the scheduled document reminders in step with the vehicles. Watched
/// once by the app so it stays alive; it fires immediately on start and again
/// whenever the vehicle list changes (a saved edit invalidates that list), so
/// a newly entered or cleared expiry date reschedules without any extra call
/// site. The sync itself is best effort and a no-op off Android.
@Riverpod(keepAlive: true)
class DocumentReminderSync extends _$DocumentReminderSync {
  @override
  void build() {
    ref.listen(vehicleListProvider, (previous, next) {
      final vehicles = next.value;
      if (vehicles == null) return;
      ref.read(syncDocumentRemindersProvider).execute(vehicles);
    }, fireImmediately: true);
  }
}
