import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecases/add_vehicle.dart';
import '../../domain/usecases/delete_refuel.dart';
import '../../domain/usecases/delete_vehicle.dart';
import '../../domain/usecases/edit_refuel.dart';
import '../../domain/usecases/edit_vehicle.dart';
import '../../domain/usecases/get_vehicle_history.dart';
import '../../domain/usecases/get_vehicle_stats.dart';
import '../../domain/usecases/list_vehicles.dart';
import '../../domain/usecases/load_fuel_catalog.dart';
import '../../domain/usecases/log_refuel.dart';
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
);

@Riverpod(keepAlive: true)
LoadFuelCatalog loadFuelCatalog(Ref ref) =>
    LoadFuelCatalog(ref.watch(catalogRepositoryProvider));
