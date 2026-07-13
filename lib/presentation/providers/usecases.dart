import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecases/add_vehicle.dart';
import '../../domain/usecases/delete_expense.dart';
import '../../domain/usecases/delete_refuel.dart';
import '../../domain/usecases/delete_service.dart';
import '../../domain/usecases/delete_vehicle.dart';
import '../../domain/usecases/edit_refuel.dart';
import '../../domain/usecases/edit_vehicle.dart';
import '../../domain/usecases/export_data.dart';
import '../../domain/usecases/get_data_bundle_template.dart';
import '../../domain/usecases/get_expenses.dart';
import '../../domain/usecases/get_service_due.dart';
import '../../domain/usecases/get_service_log.dart';
import '../../domain/usecases/get_vehicle_history.dart';
import '../../domain/usecases/get_vehicle_stats.dart';
import '../../domain/usecases/import_data.dart';
import '../../domain/usecases/list_vehicles.dart';
import '../../domain/usecases/load_fuel_catalog.dart';
import '../../domain/usecases/log_expense.dart';
import '../../domain/usecases/log_refuel.dart';
import '../../domain/usecases/log_service.dart';
import '../../domain/usecases/run_auto_backup.dart';
import '../../domain/usecases/sync_document_reminders.dart';
import '../../domain/usecases/sync_service_reminders.dart';
import 'repositories.dart';

part 'usecases.g.dart';

@Riverpod(keepAlive: true)
AddVehicle addVehicle(Ref ref) =>
    AddVehicle(ref.watch(vehicleRepositoryProvider));

@Riverpod(keepAlive: true)
EditVehicle editVehicle(Ref ref) =>
    EditVehicle(ref.watch(vehicleRepositoryProvider));

@Riverpod(keepAlive: true)
DeleteVehicle deleteVehicle(Ref ref) =>
    DeleteVehicle(ref.watch(vehicleRepositoryProvider));

@Riverpod(keepAlive: true)
ListVehicles listVehicles(Ref ref) =>
    ListVehicles(ref.watch(vehicleRepositoryProvider));

@Riverpod(keepAlive: true)
LogRefuel logRefuel(Ref ref) => LogRefuel(ref.watch(refuelRepositoryProvider));

@Riverpod(keepAlive: true)
EditRefuel editRefuel(Ref ref) =>
    EditRefuel(ref.watch(refuelRepositoryProvider));

@Riverpod(keepAlive: true)
DeleteRefuel deleteRefuel(Ref ref) =>
    DeleteRefuel(ref.watch(refuelRepositoryProvider));

@Riverpod(keepAlive: true)
GetVehicleHistory getVehicleHistory(Ref ref) =>
    GetVehicleHistory(ref.watch(refuelRepositoryProvider));

@Riverpod(keepAlive: true)
GetVehicleStats getVehicleStats(Ref ref) => GetVehicleStats(
  ref.watch(vehicleRepositoryProvider),
  ref.watch(refuelRepositoryProvider),
  ref.watch(expenseRepositoryProvider),
  ref.watch(serviceLogRepositoryProvider),
);

@Riverpod(keepAlive: true)
LoadFuelCatalog loadFuelCatalog(Ref ref) =>
    LoadFuelCatalog(ref.watch(catalogRepositoryProvider));

@Riverpod(keepAlive: true)
ExportData exportData(Ref ref) => ExportData(
  ref.watch(vehicleRepositoryProvider),
  ref.watch(refuelRepositoryProvider),
  ref.watch(serviceLogRepositoryProvider),
  ref.watch(expenseRepositoryProvider),
  ref.watch(dataBundleCodecProvider),
);

@Riverpod(keepAlive: true)
ImportData importData(Ref ref) => ImportData(
  ref.watch(vehicleRepositoryProvider),
  ref.watch(refuelRepositoryProvider),
  ref.watch(serviceLogRepositoryProvider),
  ref.watch(expenseRepositoryProvider),
  ref.watch(dataBundleCodecProvider),
);

@Riverpod(keepAlive: true)
GetDataBundleTemplate getDataBundleTemplate(Ref ref) =>
    GetDataBundleTemplate(ref.watch(dataBundleCodecProvider));

@Riverpod(keepAlive: true)
RunAutoBackup runAutoBackup(Ref ref) => RunAutoBackup(
  ref.watch(exportDataProvider),
  ref.watch(autoBackupWriterProvider),
);

@Riverpod(keepAlive: true)
SyncDocumentReminders syncDocumentReminders(Ref ref) =>
    SyncDocumentReminders(ref.watch(reminderSchedulerProvider));

@Riverpod(keepAlive: true)
SyncServiceReminders syncServiceReminders(Ref ref) => SyncServiceReminders(
  ref.watch(reminderSchedulerProvider),
  ref.watch(refuelRepositoryProvider),
  ref.watch(serviceLogRepositoryProvider),
);

@Riverpod(keepAlive: true)
LogService logService(Ref ref) =>
    LogService(ref.watch(serviceLogRepositoryProvider));

@Riverpod(keepAlive: true)
DeleteService deleteService(Ref ref) =>
    DeleteService(ref.watch(serviceLogRepositoryProvider));

@Riverpod(keepAlive: true)
GetServiceLog getServiceLog(Ref ref) =>
    GetServiceLog(ref.watch(serviceLogRepositoryProvider));

@Riverpod(keepAlive: true)
GetServiceDue getServiceDue(Ref ref) => GetServiceDue(
  ref.watch(refuelRepositoryProvider),
  ref.watch(serviceLogRepositoryProvider),
);

@Riverpod(keepAlive: true)
LogExpense logExpense(Ref ref) =>
    LogExpense(ref.watch(expenseRepositoryProvider));

@Riverpod(keepAlive: true)
DeleteExpense deleteExpense(Ref ref) =>
    DeleteExpense(ref.watch(expenseRepositoryProvider));

@Riverpod(keepAlive: true)
GetExpenses getExpenses(Ref ref) =>
    GetExpenses(ref.watch(expenseRepositoryProvider));
