import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/typedefs.dart';
import '../../domain/calculators/aggregate_calculator.dart';
import '../../domain/calculators/mileage_calculator.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/fuel_variant.dart';
import '../../domain/entities/odometer_reading.dart';
import '../../domain/entities/service_log_entry.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_vehicle_history.dart';
import '../../domain/value_objects/scheduled_reminder.dart';
import '../../domain/value_objects/service_due_status.dart';
import '../../domain/value_objects/vehicle_stats.dart';
import '../../domain/value_objects/window_mileage.dart';
import 'repositories.dart';
import 'settings_provider.dart';
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

/// The three logs the history tab can show.
enum HistorySegment { fuel, service, expenses }

/// Which history segment is showing. Session scoped and kept alive, like the
/// vehicle selection, so leaving the tab and coming back does not lose the
/// segment; the shell also reads it to decide which add button to float, and
/// the dashboard's service glance sets it before jumping to the tab.
@Riverpod(keepAlive: true)
class HistoryTab extends _$HistoryTab {
  @override
  HistorySegment build() => HistorySegment.fuel;

  void select(HistorySegment segment) => state = segment;
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

/// A vehicle's service history, most recent first.
@riverpod
Future<List<ServiceLogEntry>> serviceLog(Ref ref, int vehicleId) async {
  final result = await ref.watch(getServiceLogProvider).execute(vehicleId);
  return _unwrap(result);
}

/// A vehicle's non-fuel expenses, most recent first.
@riverpod
Future<List<Expense>> expenses(Ref ref, int vehicleId) async {
  final result = await ref.watch(getExpensesProvider).execute(vehicleId);
  return _unwrap(result);
}

/// A vehicle's manual odometer readings, ordered by odometer then date, the
/// same sequence the refuel history uses.
@riverpod
Future<List<OdometerReading>> odometerReadings(Ref ref, int vehicleId) async {
  final result = await ref
      .watch(getOdometerReadingsProvider)
      .execute(vehicleId);
  return _unwrap(result);
}

/// Where a vehicle's two maintenance templates stand right now, for the
/// dashboard glance and the service log screen's header.
@riverpod
Future<List<ServiceDueStatus>> serviceDue(Ref ref, Vehicle vehicle) async {
  final result = await ref.watch(getServiceDueProvider).execute(vehicle);
  return _unwrap(result);
}

/// The reminders that are scheduled right now, for the settings list. It runs
/// the same planning the sync notifiers run, so what the user reads is what
/// was handed to the scheduler. A category that is switched off contributes
/// nothing.
@riverpod
Future<List<ScheduledReminder>> scheduledReminders(Ref ref) async {
  final vehicles = await ref.watch(vehicleListProvider.future);
  final settings = await ref.watch(settingsProvider.future);
  return ref
      .watch(getScheduledRemindersProvider)
      .execute(
        vehicles,
        documents: settings.documentRemindersEnabled,
        services: settings.serviceRemindersEnabled,
      );
}

/// Whether the platform will show the app's notifications. Null when that
/// cannot be answered, which is every platform but Android.
@riverpod
Future<bool?> notificationsEnabled(Ref ref) =>
    ref.watch(reminderSchedulerProvider).notificationsEnabled();

/// Keeps the scheduled document reminders in step with the vehicles. Watched
/// once by the app so it stays alive; it fires immediately on start and again
/// whenever the vehicle list changes (a saved edit invalidates that list), so
/// a newly entered or cleared expiry date reschedules without any extra call
/// site. Flipping the settings switch re-runs it too, which is what cancels
/// the category: an empty vehicle list plans no reminders, and the sync then
/// reconciles the device down to nothing. The sync itself is best effort and
/// a no-op off Android.
@Riverpod(keepAlive: true)
class DocumentReminderSync extends _$DocumentReminderSync {
  @override
  void build() {
    ref.listen(vehicleListProvider, (previous, next) {
      if (next.value != null) unawaited(_run());
    }, fireImmediately: true);
    ref.listen(settingsProvider, (previous, next) {
      final before = previous?.value?.documentRemindersEnabled;
      final after = next.value?.documentRemindersEnabled;
      if (before == null || after == null || before == after) return;
      unawaited(_run());
    });
  }

  Future<void> _run() async {
    final vehicles = ref.read(vehicleListProvider).value;
    if (vehicles == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref
        .read(syncDocumentRemindersProvider)
        .execute(settings.documentRemindersEnabled ? vehicles : const []);
  }
}

/// Keeps the scheduled service due reminders in step with the vehicles, the
/// same pattern [DocumentReminderSync] uses, switch included. Logging a
/// service does not change the vehicle list, so the service log screen also
/// calls `syncServiceRemindersProvider` directly after a save.
@Riverpod(keepAlive: true)
class ServiceReminderSync extends _$ServiceReminderSync {
  @override
  void build() {
    ref.listen(vehicleListProvider, (previous, next) {
      if (next.value != null) unawaited(_run());
    }, fireImmediately: true);
    ref.listen(settingsProvider, (previous, next) {
      final before = previous?.value?.serviceRemindersEnabled;
      final after = next.value?.serviceRemindersEnabled;
      if (before == null || after == null || before == after) return;
      unawaited(_run());
    });
  }

  Future<void> _run() async {
    final vehicles = ref.read(vehicleListProvider).value;
    if (vehicles == null) return;
    final settings = await ref.read(settingsProvider.future);
    await ref
        .read(syncServiceRemindersProvider)
        .execute(settings.serviceRemindersEnabled ? vehicles : const []);
  }
}
