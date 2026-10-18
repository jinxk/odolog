import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/data/daos/expense_dao.dart';
import 'package:odolog/data/daos/odometer_reading_dao.dart';
import 'package:odolog/data/daos/refuel_dao.dart';
import 'package:odolog/data/daos/service_log_dao.dart';
import 'package:odolog/data/daos/vehicle_dao.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:odolog/data/db/sqflite_unit_of_work.dart';
import 'package:odolog/data/repositories/expense_repository_impl.dart';
import 'package:odolog/data/repositories/odometer_reading_repository_impl.dart';
import 'package:odolog/data/repositories/refuel_repository_impl.dart';
import 'package:odolog/data/repositories/service_log_repository_impl.dart';
import 'package:odolog/data/repositories/vehicle_repository_impl.dart';
import 'package:odolog/domain/entities/expense.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/add_vehicle.dart';
import 'package:odolog/domain/usecases/import_data.dart';
import 'package:odolog/domain/usecases/list_vehicles.dart';
import 'package:odolog/domain/usecases/log_expense.dart';
import 'package:odolog/domain/usecases/log_odometer_reading.dart';
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
    final readingRepo = OdometerReadingRepositoryImpl(OdometerReadingDao(db));
    return ImportData(
      AddVehicle(vehicleRepo),
      LogRefuel(RefuelRepositoryImpl(refuels), readingRepo),
      LogService(ServiceLogRepositoryImpl(ServiceLogDao(db))),
      LogExpense(ExpenseRepositoryImpl(ExpenseDao(db))),
      LogOdometerReading(readingRepo, RefuelRepositoryImpl(refuels)),
      ListVehicles(vehicleRepo),
      codec,
      SqfliteUnitOfWork(db),
      refuelRepository: RefuelRepositoryImpl(refuels),
      readingRepository: readingRepo,
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
        odometerReadings: const [],
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
        odometerReadings: const [],
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

  test(
    'a backup whose refuel id is already on the device is refused with the plain message and writes nothing',
    () async {
      await vehicles.insert(vehicle);
      await refuels.insert(
        entry(id: 1, odometer: 500, quantity: 20, pricePaid: 2000),
      );
      final codec = FakeDataBundleCodec(
        decodeResult: right((
          vehicles: [
            const Vehicle(
              id: 2,
              name: 'City',
              type: VehicleType.car,
              fuelCategory: FuelCategory.petrol,
            ),
          ],
          entries: [
            entry(
              id: 3,
              vehicleId: 2,
              odometer: 1000,
              quantity: 20,
              pricePaid: 2000,
            ),
            entry(
              id: 1,
              vehicleId: 2,
              odometer: 900,
              quantity: 20,
              pricePaid: 2000,
            ),
          ],
          serviceLog: const [],
          odometerReadings: const [],
          expenses: const [],
        )),
      );

      final result = await importer(codec).execute('...');

      final failure = result.getLeft().toNullable()! as DuplicateIdFailure;
      expect(
        failure.message,
        'Some items in this file are already on this phone, so nothing was '
        'imported. Import only adds new items, it does not replace what is '
        'here.',
      );
      expect(await vehicles.getAll(), hasLength(1));
      expect(await refuels.getForVehicle(2), isEmpty);
      expect(await refuels.getForVehicle(1), hasLength(1));
    },
  );

  test(
    'the same backup imported twice is refused the second time and changes nothing',
    () async {
      final expenses = ExpenseDao(db);
      final codec = FakeDataBundleCodec(
        decodeResult: right((
          vehicles: [vehicle],
          entries: [
            entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
          ],
          serviceLog: const [],
          odometerReadings: const [],
          expenses: [
            Expense(
              id: 1,
              vehicleId: vehicle.id,
              amount: 500,
              date: DateTime.utc(2020),
              category: 'Tyre',
            ),
          ],
        )),
      );

      final first = await importer(codec).execute('...');
      expect(first.isRight(), isTrue);

      final second = await importer(codec).execute('...');

      final failure = second.getLeft().toNullable()! as DatabaseFailure;
      expect(
        failure.message,
        'Some items in this file are already on this phone, so nothing was '
        'imported. Import only adds new items, it does not replace what is '
        'here.',
      );
      expect(await vehicles.getAll(), hasLength(1));
      expect(await refuels.getForVehicle(vehicle.id), hasLength(1));
      expect(await expenses.getForVehicle(vehicle.id), hasLength(1));
    },
  );

  const duplicateMessage =
      'Some items in this file are already on this phone, so nothing was '
      'imported. Import only adds new items, it does not replace what is '
      'here.';

  test('fills and readings imported twice for a vehicle already on the phone '
      'are refused with the plain message', () async {
    await vehicles.insert(vehicle);
    final readings = OdometerReadingDao(db);
    final codec = FakeDataBundleCodec(
      decodeResult: right((
        vehicles: const <Vehicle>[],
        entries: [
          entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
          entry(id: 2, odometer: 1400, quantity: 22, pricePaid: 2200),
        ],
        serviceLog: const [],
        odometerReadings: [
          OdometerReading(
            id: 1,
            vehicleId: vehicle.id,
            odometer: 1500,
            recordedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
        expenses: const [],
      )),
    );

    final first = await importer(codec).execute('...');
    expect(first.isRight(), isTrue, reason: '$first');

    final second = await importer(codec).execute('...');

    final failure = second.getLeft().toNullable()! as DuplicateIdFailure;
    expect(failure.message, duplicateMessage);
    expect(await refuels.getForVehicle(vehicle.id), hasLength(2));
    expect(await readings.getForVehicle(vehicle.id), hasLength(1));
  });

  test('a rollover backup imported twice for a vehicle already on the phone '
      'is refused with the plain message', () async {
    await vehicles.insert(vehicle);
    final readings = OdometerReadingDao(db);
    DateTime daysAgo(int days) => DateTime.now().subtract(Duration(days: days));
    final codec = FakeDataBundleCodec(
      decodeResult: right((
        vehicles: const <Vehicle>[],
        entries: [
          entry(
            id: 3,
            odometer: 100,
            quantity: 20,
            pricePaid: 2000,
            odometerOverride: true,
            filledAt: daysAgo(10),
          ),
          entry(
            id: 4,
            odometer: 400,
            quantity: 20,
            pricePaid: 2000,
            filledAt: daysAgo(5),
          ),
          entry(
            id: 1,
            odometer: 9000,
            quantity: 20,
            pricePaid: 2000,
            filledAt: daysAgo(30),
          ),
          entry(
            id: 2,
            odometer: 9500,
            quantity: 20,
            pricePaid: 2000,
            filledAt: daysAgo(20),
          ),
        ],
        serviceLog: const [],
        odometerReadings: [
          OdometerReading(
            id: 1,
            vehicleId: vehicle.id,
            odometer: 450,
            recordedAt: daysAgo(2),
          ),
        ],
        expenses: const [],
      )),
    );

    final first = await importer(codec).execute('...');
    expect(first.isRight(), isTrue, reason: '$first');

    final second = await importer(codec).execute('...');

    final failure = second.getLeft().toNullable()! as DuplicateIdFailure;
    expect(failure.message, duplicateMessage);
    expect(await refuels.getForVehicle(vehicle.id), hasLength(4));
    expect(await readings.getForVehicle(vehicle.id), hasLength(1));
  });

  test('a bundle with a bad odometer reading writes nothing at all', () async {
    final readings = OdometerReadingDao(db);
    final codec = FakeDataBundleCodec(
      decodeResult: right((
        vehicles: [vehicle],
        entries: [entry(id: 0, odometer: 1000, quantity: 20, pricePaid: 2000)],
        serviceLog: const [],
        odometerReadings: [
          OdometerReading(
            id: 0,
            vehicleId: vehicle.id,
            odometer: 1400,
            recordedAt: DateTime.now(),
          ),
          // Behind the reading before it, so the sequence check refuses it.
          OdometerReading(
            id: 0,
            vehicleId: vehicle.id,
            odometer: 1200,
            recordedAt: DateTime.now(),
          ),
        ],
        expenses: const [],
      )),
    );

    final result = await importer(codec).execute('...');

    final failure = result.getLeft().toNullable()! as ValidationFailure;
    expect(failure.field, 'odometer');
    expect(failure.reason, startsWith('odometerReadings[1]:'));
    expect(await vehicles.getAll(), isEmpty);
    expect(await refuels.getForVehicle(vehicle.id), isEmpty);
    expect(await readings.getForVehicle(vehicle.id), isEmpty);
  });

  test('a rollover backup refused in both replays reports the first error and '
      'writes nothing', () async {
    final readings = OdometerReadingDao(db);
    DateTime daysAgo(int days) => DateTime.now().subtract(Duration(days: days));
    final codec = FakeDataBundleCodec(
      decodeResult: right((
        vehicles: [vehicle],
        entries: [
          entry(
            id: 4,
            odometer: 50,
            quantity: 20,
            pricePaid: 2000,
            odometerOverride: true,
            filledAt: daysAgo(10),
          ),
          entry(
            id: 5,
            odometer: 400,
            quantity: 20,
            pricePaid: 2000,
            filledAt: daysAgo(3),
          ),
          entry(
            id: 1,
            odometer: 1000,
            quantity: 20,
            pricePaid: 2000,
            filledAt: daysAgo(40),
          ),
          entry(
            id: 2,
            odometer: 3000,
            quantity: 20,
            pricePaid: 2000,
            filledAt: daysAgo(20),
          ),
          entry(
            id: 3,
            odometer: 3500,
            quantity: 20,
            pricePaid: 2000,
            odometerOverride: true,
            filledAt: daysAgo(30),
          ),
        ],
        serviceLog: const [],
        // Below the fill at 3 days ago, so the run by run replay refuses it.
        odometerReadings: [
          OdometerReading(
            id: 1,
            vehicleId: vehicle.id,
            odometer: 300,
            recordedAt: daysAgo(2),
          ),
        ],
        expenses: const [],
      )),
    );

    final result = await importer(codec).execute('...');

    final failure = result.getLeft().toNullable()! as ValidationFailure;
    expect(failure.field, 'odometer');
    expect(
      failure.reason,
      'refuels[3]: Odometer must be greater than the previous reading.',
    );
    expect(await vehicles.getAll(), isEmpty);
    expect(await refuels.getForVehicle(vehicle.id), isEmpty);
    expect(await readings.getForVehicle(vehicle.id), isEmpty);
  });
}
