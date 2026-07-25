import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/data/daos/expense_dao.dart';
import 'package:odolog/data/daos/refuel_dao.dart';
import 'package:odolog/data/daos/service_log_dao.dart';
import 'package:odolog/data/daos/vehicle_dao.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:odolog/data/db/sqflite_unit_of_work.dart';
import 'package:odolog/data/repositories/expense_repository_impl.dart';
import 'package:odolog/data/repositories/refuel_repository_impl.dart';
import 'package:odolog/data/repositories/service_log_repository_impl.dart';
import 'package:odolog/data/repositories/vehicle_repository_impl.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/add_vehicle.dart';
import 'package:odolog/domain/usecases/import_data.dart';
import 'package:odolog/domain/usecases/list_vehicles.dart';
import 'package:odolog/domain/usecases/log_expense.dart';
import 'package:odolog/domain/usecases/log_refuel.dart';
import 'package:odolog/domain/usecases/log_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/entry_builder.dart';
import '../helpers/fake_data_bundle_codec.dart';

/// The import against the real data layer: real DAOs, real repositories, and a
/// real sqflite transaction, so a bundle that fails partway is measured by what
/// is left in the tables rather than by what a fake recorded.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late VehicleDao vehicles;
  late RefuelDao refuels;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath);
    vehicles = VehicleDao(db);
    refuels = RefuelDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  const vehicle = Vehicle(
    id: 1,
    name: 'Swift',
    type: VehicleType.car,
    fuelCategory: FuelCategory.petrol,
  );

  ImportData importer(FakeDataBundleCodec codec) {
    final vehicleRepo = VehicleRepositoryImpl(vehicles);
    return ImportData(
      AddVehicle(vehicleRepo),
      LogRefuel(RefuelRepositoryImpl(refuels)),
      LogService(ServiceLogRepositoryImpl(ServiceLogDao(db))),
      LogExpense(ExpenseRepositoryImpl(ExpenseDao(db))),
      ListVehicles(vehicleRepo),
      codec,
      SqfliteUnitOfWork(db),
    );
  }

  test('a clean bundle lands in the tables', () async {
    final codec = FakeDataBundleCodec(
      decodeResult: right((
        vehicles: [vehicle],
        entries: [
          entry(id: 0, odometer: 1000, quantity: 20, pricePaid: 2000),
          entry(id: 0, odometer: 1400, quantity: 22, pricePaid: 2200),
        ],
        serviceLog: const [],
        expenses: const [],
      )),
    );

    final result = await importer(codec).execute('...');

    expect(result.isRight(), isTrue);
    expect(await vehicles.getAll(), hasLength(1));
    expect(await refuels.getForVehicle(vehicle.id), hasLength(2));
  });

  test('a bundle whose third refuel fails writes nothing at all', () async {
    final codec = FakeDataBundleCodec(
      decodeResult: right((
        vehicles: [vehicle],
        entries: [
          entry(id: 0, odometer: 1000, quantity: 20, pricePaid: 2000),
          entry(id: 0, odometer: 1400, quantity: 22, pricePaid: 2200),
          entry(id: 0, odometer: 1800, quantity: 0, pricePaid: 2100),
        ],
        serviceLog: const [],
        expenses: const [],
      )),
    );

    final result = await importer(codec).execute('...');

    final failure = result.getLeft().toNullable()! as ValidationFailure;
    expect(failure.field, 'quantity');
    expect(failure.reason, startsWith('refuels[2]:'));
    expect(await vehicles.getAll(), isEmpty);
    expect(await refuels.getForVehicle(vehicle.id), isEmpty);
  });
}
