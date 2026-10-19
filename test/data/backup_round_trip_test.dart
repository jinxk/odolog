import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/data/daos/expense_dao.dart';
import 'package:odolog/data/daos/odometer_reading_dao.dart';
import 'package:odolog/data/daos/refuel_dao.dart';
import 'package:odolog/data/daos/service_log_dao.dart';
import 'package:odolog/data/daos/vehicle_dao.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:odolog/data/db/sqflite_unit_of_work.dart';
import 'package:odolog/data/json/data_bundle_json_codec.dart';
import 'package:odolog/data/repositories/expense_repository_impl.dart';
import 'package:odolog/data/repositories/odometer_reading_repository_impl.dart';
import 'package:odolog/data/repositories/refuel_repository_impl.dart';
import 'package:odolog/data/repositories/service_log_repository_impl.dart';
import 'package:odolog/data/repositories/vehicle_repository_impl.dart';
import 'package:odolog/domain/entities/expense.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/add_vehicle.dart';
import 'package:odolog/domain/usecases/export_data.dart';
import 'package:odolog/domain/usecases/get_vehicle_stats.dart';
import 'package:odolog/domain/usecases/import_data.dart';
import 'package:odolog/domain/usecases/list_vehicles.dart';
import 'package:odolog/domain/usecases/log_expense.dart';
import 'package:odolog/domain/usecases/log_odometer_reading.dart';
import 'package:odolog/domain/usecases/log_refuel.dart';
import 'package:odolog/domain/usecases/log_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/entry_builder.dart';

/// Export from one real database and import into a second empty one, through
/// the real JSON codec, DAOs and unit of work.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const vehicle = Vehicle(
    id: 1,
    name: 'Swift',
    type: VehicleType.car,
    fuelCategory: FuelCategory.petrol,
  );
  const second = Vehicle(
    id: 2,
    name: 'Activa',
    type: VehicleType.scooter,
    fuelCategory: FuelCategory.petrol,
  );

  DateTime daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

  /// Saves [history] in order through the use cases on one real database,
  /// exports it, imports the file into a second empty one and checks that the
  /// rows and the stats came back the same.
  Future<void> expectRoundTrip(List<Object> history, {Vehicle? second}) async {
    final a = await AppDatabase.open(path: inMemoryDatabasePath);
    final vehicleRepoA = VehicleRepositoryImpl(VehicleDao(a));
    final refuelRepoA = RefuelRepositoryImpl(RefuelDao(a));
    final readingRepoA = OdometerReadingRepositoryImpl(OdometerReadingDao(a));
    final serviceRepoA = ServiceLogRepositoryImpl(ServiceLogDao(a));
    final expenseRepoA = ExpenseRepositoryImpl(ExpenseDao(a));
    final logRefuel = LogRefuel(refuelRepoA, readingRepoA);
    final logReading = LogOdometerReading(readingRepoA, refuelRepoA);

    final vehicles = [vehicle, ?second];
    for (final v in vehicles) {
      expect((await AddVehicle(vehicleRepoA).execute(v)).isRight(), isTrue);
    }
    for (final item in history) {
      final saved = item is RefuelEntry
          ? await logRefuel.execute(item)
          : await logReading.execute(item as OdometerReading);
      expect(saved.isRight(), isTrue, reason: '$item: $saved');
    }

    final stats = GetVehicleStats(
      vehicleRepoA,
      refuelRepoA,
      expenseRepoA,
      serviceRepoA,
      readingRepoA,
    );
    final vehiclesBefore = await VehicleDao(a).getAll();
    final refuelsBefore = {
      for (final v in vehicles) v.id: await RefuelDao(a).getForVehicle(v.id),
    };
    final readingsBefore = {
      for (final v in vehicles)
        v.id: await OdometerReadingDao(a).getForVehicle(v.id),
    };
    final statsBefore = {
      for (final v in vehicles)
        v.id: (await stats.execute(v.id)).getRight().toNullable()!,
    };

    const codec = DataBundleJsonCodec();
    final exported = await ExportData(
      vehicleRepoA,
      refuelRepoA,
      serviceRepoA,
      expenseRepoA,
      readingRepoA,
      codec,
    ).execute();
    expect(exported.isRight(), isTrue, reason: '$exported');
    final content = exported.getRight().toNullable()!;
    await a.close();

    final b = await AppDatabase.open(path: inMemoryDatabasePath);
    addTearDown(b.close);
    expect(await VehicleDao(b).getAll(), isEmpty);
    final vehicleRepoB = VehicleRepositoryImpl(VehicleDao(b));
    final refuelRepoB = RefuelRepositoryImpl(RefuelDao(b));
    final readingRepoB = OdometerReadingRepositoryImpl(OdometerReadingDao(b));
    final serviceRepoB = ServiceLogRepositoryImpl(ServiceLogDao(b));
    final expenseRepoB = ExpenseRepositoryImpl(ExpenseDao(b));

    final result = await ImportData(
      AddVehicle(vehicleRepoB),
      LogRefuel(refuelRepoB, readingRepoB),
      LogService(serviceRepoB),
      LogExpense(expenseRepoB),
      LogOdometerReading(readingRepoB, refuelRepoB),
      ListVehicles(vehicleRepoB),
      codec,
      SqfliteUnitOfWork(b),
      refuelRepoB,
      readingRepoB,
    ).execute(content);

    expect(result.isRight(), isTrue, reason: '$result');
    expect(await VehicleDao(b).getAll(), vehiclesBefore);
    final statsB = GetVehicleStats(
      vehicleRepoB,
      refuelRepoB,
      expenseRepoB,
      serviceRepoB,
      readingRepoB,
    );
    for (final v in vehicles) {
      expect(await RefuelDao(b).getForVehicle(v.id), refuelsBefore[v.id]);
      expect(
        await OdometerReadingDao(b).getForVehicle(v.id),
        readingsBefore[v.id],
      );
      expect(
        (await statsB.execute(v.id)).getRight().toNullable(),
        statsBefore[v.id],
      );
    }
  }

  test('a backup holding an odometer rollover restores every row and the same '
      'stats into an empty store', () async {
    final a = await AppDatabase.open(path: inMemoryDatabasePath);
    final vehicleRepoA = VehicleRepositoryImpl(VehicleDao(a));
    final refuelRepoA = RefuelRepositoryImpl(RefuelDao(a));
    final readingRepoA = OdometerReadingRepositoryImpl(OdometerReadingDao(a));
    final serviceRepoA = ServiceLogRepositoryImpl(ServiceLogDao(a));
    final expenseRepoA = ExpenseRepositoryImpl(ExpenseDao(a));
    final logRefuel = LogRefuel(refuelRepoA, readingRepoA);

    final seeded = [
      await AddVehicle(vehicleRepoA).execute(vehicle),
      await logRefuel.execute(
        entry(
          id: 0,
          odometer: 1000,
          quantity: 20,
          pricePaid: 2000,
          filledAt: daysAgo(40),
        ),
      ),
      await logRefuel.execute(
        entry(
          id: 0,
          odometer: 1400,
          quantity: 22,
          pricePaid: 2200,
          filledAt: daysAgo(30),
        ),
      ),
      await LogOdometerReading(readingRepoA, refuelRepoA).execute(
        OdometerReading(
          id: 0,
          vehicleId: vehicle.id,
          odometer: 1500,
          recordedAt: daysAgo(25),
        ),
      ),
      await logRefuel.execute(
        entry(
          id: 0,
          odometer: 50,
          quantity: 18,
          pricePaid: 1800,
          odometerOverride: true,
          filledAt: daysAgo(20),
        ),
      ),
      await logRefuel.execute(
        entry(
          id: 0,
          odometer: 400,
          quantity: 21,
          pricePaid: 2100,
          filledAt: daysAgo(10),
        ),
      ),
      await LogService(serviceRepoA).execute(
        ServiceLogEntry(
          id: 0,
          vehicleId: vehicle.id,
          template: ServiceTemplate.engineOil,
          performedAt: daysAgo(15),
          odometer: 100,
          cost: 450,
        ),
      ),
      await LogExpense(expenseRepoA).execute(
        Expense(
          id: 0,
          vehicleId: vehicle.id,
          amount: 800,
          date: daysAgo(5),
          category: 'Parking',
        ),
      ),
    ];
    for (final result in seeded) {
      expect(result.isRight(), isTrue, reason: '$result');
    }

    final stats = GetVehicleStats(
      vehicleRepoA,
      refuelRepoA,
      expenseRepoA,
      serviceRepoA,
      readingRepoA,
    );
    final vehiclesBefore = await VehicleDao(a).getAll();
    final refuelsBefore = await RefuelDao(a).getForVehicle(vehicle.id);
    final readingsBefore = await OdometerReadingDao(
      a,
    ).getForVehicle(vehicle.id);
    final servicesBefore = await ServiceLogDao(a).getForVehicle(vehicle.id);
    final expensesBefore = await ExpenseDao(a).getForVehicle(vehicle.id);
    final statsBefore = (await stats.execute(
      vehicle.id,
    )).getRight().toNullable()!;

    const codec = DataBundleJsonCodec();
    final exported = await ExportData(
      vehicleRepoA,
      refuelRepoA,
      serviceRepoA,
      expenseRepoA,
      readingRepoA,
      codec,
    ).execute();
    expect(exported.isRight(), isTrue, reason: '$exported');
    final content = exported.getRight().toNullable()!;
    await a.close();

    final b = await AppDatabase.open(path: inMemoryDatabasePath);
    addTearDown(b.close);
    expect(await VehicleDao(b).getAll(), isEmpty);
    final vehicleRepoB = VehicleRepositoryImpl(VehicleDao(b));
    final refuelRepoB = RefuelRepositoryImpl(RefuelDao(b));
    final readingRepoB = OdometerReadingRepositoryImpl(OdometerReadingDao(b));
    final serviceRepoB = ServiceLogRepositoryImpl(ServiceLogDao(b));
    final expenseRepoB = ExpenseRepositoryImpl(ExpenseDao(b));

    final result = await ImportData(
      AddVehicle(vehicleRepoB),
      LogRefuel(refuelRepoB, readingRepoB),
      LogService(serviceRepoB),
      LogExpense(expenseRepoB),
      LogOdometerReading(readingRepoB, refuelRepoB),
      ListVehicles(vehicleRepoB),
      codec,
      SqfliteUnitOfWork(b),
      refuelRepoB,
      readingRepoB,
    ).execute(content);

    expect(result.isRight(), isTrue, reason: '$result');
    expect(await VehicleDao(b).getAll(), vehiclesBefore);
    expect(await RefuelDao(b).getForVehicle(vehicle.id), refuelsBefore);
    expect(
      await OdometerReadingDao(b).getForVehicle(vehicle.id),
      readingsBefore,
    );
    expect(await ServiceLogDao(b).getForVehicle(vehicle.id), servicesBefore);
    expect(await ExpenseDao(b).getForVehicle(vehicle.id), expensesBefore);
    final statsAfter = await GetVehicleStats(
      vehicleRepoB,
      refuelRepoB,
      expenseRepoB,
      serviceRepoB,
      readingRepoB,
    ).execute(vehicle.id);
    expect(statsAfter.getRight().toNullable(), statsBefore);
  });

  test('a backup holding a rollover and a backdated override fill above a '
      'later fill restores every row and the same stats into an empty '
      'store', () async {
    final a = await AppDatabase.open(path: inMemoryDatabasePath);
    final vehicleRepoA = VehicleRepositoryImpl(VehicleDao(a));
    final refuelRepoA = RefuelRepositoryImpl(RefuelDao(a));
    final readingRepoA = OdometerReadingRepositoryImpl(OdometerReadingDao(a));
    final serviceRepoA = ServiceLogRepositoryImpl(ServiceLogDao(a));
    final expenseRepoA = ExpenseRepositoryImpl(ExpenseDao(a));
    final logRefuel = LogRefuel(refuelRepoA, readingRepoA);

    final seeded = [
      await AddVehicle(vehicleRepoA).execute(vehicle),
      await logRefuel.execute(
        entry(
          id: 0,
          odometer: 1000,
          quantity: 20,
          pricePaid: 2000,
          filledAt: daysAgo(40),
        ),
      ),
      await logRefuel.execute(
        entry(
          id: 0,
          odometer: 3000,
          quantity: 22,
          pricePaid: 2200,
          filledAt: daysAgo(20),
        ),
      ),
      await logRefuel.execute(
        entry(
          id: 0,
          odometer: 3500,
          quantity: 19,
          pricePaid: 1900,
          odometerOverride: true,
          filledAt: daysAgo(30),
        ),
      ),
      await logRefuel.execute(
        entry(
          id: 0,
          odometer: 50,
          quantity: 18,
          pricePaid: 1800,
          odometerOverride: true,
          filledAt: daysAgo(10),
        ),
      ),
      await LogOdometerReading(readingRepoA, refuelRepoA).execute(
        OdometerReading(
          id: 0,
          vehicleId: vehicle.id,
          odometer: 200,
          recordedAt: daysAgo(6),
        ),
      ),
      await logRefuel.execute(
        entry(
          id: 0,
          odometer: 400,
          quantity: 21,
          pricePaid: 2100,
          filledAt: daysAgo(3),
        ),
      ),
      await LogService(serviceRepoA).execute(
        ServiceLogEntry(
          id: 0,
          vehicleId: vehicle.id,
          template: ServiceTemplate.engineOil,
          performedAt: daysAgo(15),
          odometer: 100,
          cost: 450,
        ),
      ),
      await LogExpense(expenseRepoA).execute(
        Expense(
          id: 0,
          vehicleId: vehicle.id,
          amount: 800,
          date: daysAgo(5),
          category: 'Parking',
        ),
      ),
    ];
    for (final result in seeded) {
      expect(result.isRight(), isTrue, reason: '$result');
    }

    final stats = GetVehicleStats(
      vehicleRepoA,
      refuelRepoA,
      expenseRepoA,
      serviceRepoA,
      readingRepoA,
    );
    final vehiclesBefore = await VehicleDao(a).getAll();
    final refuelsBefore = await RefuelDao(a).getForVehicle(vehicle.id);
    final readingsBefore = await OdometerReadingDao(
      a,
    ).getForVehicle(vehicle.id);
    final servicesBefore = await ServiceLogDao(a).getForVehicle(vehicle.id);
    final expensesBefore = await ExpenseDao(a).getForVehicle(vehicle.id);
    final statsBefore = (await stats.execute(
      vehicle.id,
    )).getRight().toNullable()!;

    const codec = DataBundleJsonCodec();
    final exported = await ExportData(
      vehicleRepoA,
      refuelRepoA,
      serviceRepoA,
      expenseRepoA,
      readingRepoA,
      codec,
    ).execute();
    expect(exported.isRight(), isTrue, reason: '$exported');
    final content = exported.getRight().toNullable()!;
    await a.close();

    final b = await AppDatabase.open(path: inMemoryDatabasePath);
    addTearDown(b.close);
    expect(await VehicleDao(b).getAll(), isEmpty);
    final vehicleRepoB = VehicleRepositoryImpl(VehicleDao(b));
    final refuelRepoB = RefuelRepositoryImpl(RefuelDao(b));
    final readingRepoB = OdometerReadingRepositoryImpl(OdometerReadingDao(b));
    final serviceRepoB = ServiceLogRepositoryImpl(ServiceLogDao(b));
    final expenseRepoB = ExpenseRepositoryImpl(ExpenseDao(b));

    final result = await ImportData(
      AddVehicle(vehicleRepoB),
      LogRefuel(refuelRepoB, readingRepoB),
      LogService(serviceRepoB),
      LogExpense(expenseRepoB),
      LogOdometerReading(readingRepoB, refuelRepoB),
      ListVehicles(vehicleRepoB),
      codec,
      SqfliteUnitOfWork(b),
      refuelRepoB,
      readingRepoB,
    ).execute(content);

    expect(result.isRight(), isTrue, reason: '$result');
    expect(await VehicleDao(b).getAll(), vehiclesBefore);
    expect(await RefuelDao(b).getForVehicle(vehicle.id), refuelsBefore);
    expect(
      await OdometerReadingDao(b).getForVehicle(vehicle.id),
      readingsBefore,
    );
    expect(await ServiceLogDao(b).getForVehicle(vehicle.id), servicesBefore);
    expect(await ExpenseDao(b).getForVehicle(vehicle.id), expensesBefore);
    final statsAfter = await GetVehicleStats(
      vehicleRepoB,
      refuelRepoB,
      expenseRepoB,
      serviceRepoB,
      readingRepoB,
    ).execute(vehicle.id);
    expect(statsAfter.getRight().toNullable(), statsBefore);
  });

  test('a backup holding an override fill dated before a later manual reading '
      'restores every row and the same stats into an empty store', () async {
    await expectRoundTrip([
      entry(
        id: 0,
        odometer: 1000,
        quantity: 20,
        pricePaid: 2000,
        filledAt: daysAgo(40),
      ),
      entry(
        id: 0,
        odometer: 3000,
        quantity: 20,
        pricePaid: 2000,
        filledAt: daysAgo(20),
      ),
      OdometerReading(
        id: 0,
        vehicleId: vehicle.id,
        odometer: 2000,
        recordedAt: daysAgo(25),
      ),
      entry(
        id: 0,
        odometer: 3500,
        quantity: 20,
        pricePaid: 2000,
        odometerOverride: true,
        filledAt: daysAgo(30),
      ),
    ]);
  });

  test('a backup holding a rollover and an override fill dated before a later '
      'manual reading restores every row and the same stats into an empty '
      'store', () async {
    await expectRoundTrip([
      entry(
        id: 0,
        odometer: 1000,
        quantity: 20,
        pricePaid: 2000,
        filledAt: daysAgo(40),
      ),
      entry(
        id: 0,
        odometer: 3000,
        quantity: 20,
        pricePaid: 2000,
        filledAt: daysAgo(20),
      ),
      OdometerReading(
        id: 0,
        vehicleId: vehicle.id,
        odometer: 2000,
        recordedAt: daysAgo(25),
      ),
      entry(
        id: 0,
        odometer: 3500,
        quantity: 20,
        pricePaid: 2000,
        odometerOverride: true,
        filledAt: daysAgo(30),
      ),
      entry(
        id: 0,
        odometer: 50,
        quantity: 20,
        pricePaid: 2000,
        odometerOverride: true,
        filledAt: daysAgo(10),
      ),
      entry(
        id: 0,
        odometer: 400,
        quantity: 20,
        pricePaid: 2000,
        filledAt: daysAgo(3),
      ),
    ]);
  });

  test('a backup holding a rollover and an override fill above an earlier '
      'reading restores every row and the same stats into an empty '
      'store', () async {
    await expectRoundTrip([
      entry(
        id: 0,
        odometer: 200,
        quantity: 20,
        pricePaid: 2000,
        filledAt: daysAgo(24),
      ),
      entry(
        id: 0,
        odometer: 2000,
        quantity: 20,
        pricePaid: 2000,
        odometerOverride: true,
        filledAt: daysAgo(31),
      ),
      OdometerReading(
        id: 0,
        vehicleId: vehicle.id,
        odometer: 400,
        recordedAt: daysAgo(37),
      ),
      entry(
        id: 0,
        odometer: 1500,
        quantity: 20,
        pricePaid: 2000,
        odometerOverride: true,
        filledAt: daysAgo(17),
      ),
      OdometerReading(
        id: 0,
        vehicleId: vehicle.id,
        odometer: 2000,
        recordedAt: daysAgo(11),
      ),
    ]);
  });

  RefuelEntry fill(
    double odometer,
    DateTime filledAt, {
    bool override = false,
    int vehicleId = 1,
  }) => entry(
    id: 0,
    odometer: odometer,
    quantity: 20,
    pricePaid: 2000,
    odometerOverride: override,
    filledAt: filledAt,
    vehicleId: vehicleId,
  );

  OdometerReading reading(
    double odometer,
    DateTime recordedAt,
    int vehicleId,
  ) => OdometerReading(
    id: 0,
    vehicleId: vehicleId,
    odometer: odometer,
    recordedAt: recordedAt,
  );

  test('a backup holding an override fill that corrects a fill typed too high '
      'restores every row and the same stats into an empty store', () async {
    await expectRoundTrip([
      fill(1000, daysAgo(50)),
      fill(2000, daysAgo(40)),
      fill(1500, daysAgo(30), override: true),
      fill(1800, daysAgo(20)),
    ]);
  });

  test('a backup holding a rollover fill dated between fills it is out of '
      'order with restores every row and the same stats into an empty '
      'store', () async {
    await expectRoundTrip([
      fill(100, daysAgo(24)),
      fill(3000, daysAgo(20)),
      fill(5000, daysAgo(50), override: true),
      fill(2000, daysAgo(45), override: true),
    ]);
  });

  test('a backup holding a reading that goes in between two override fills '
      'restores every row and the same stats into an empty store', () async {
    await expectRoundTrip([
      fill(1000, daysAgo(40)),
      reading(1500, daysAgo(25), 1),
      fill(5000, daysAgo(50), override: true),
      fill(3000, daysAgo(33), override: true),
    ]);
  });

  test('a backup holding two vehicles that each need a different import order '
      'restores every row and the same stats into an empty store', () async {
    await expectRoundTrip([
      fill(1000, daysAgo(50)),
      fill(2000, daysAgo(40)),
      fill(1500, daysAgo(30), override: true),
      fill(1800, daysAgo(20)),
      fill(500, daysAgo(10), override: true),
      fill(1000, daysAgo(40), vehicleId: 2),
      fill(3000, daysAgo(20), vehicleId: 2),
      reading(2000, daysAgo(25), 2),
      fill(3500, daysAgo(30), override: true, vehicleId: 2),
    ], second: second);
  });

  test('a backup holding a reading and a higher fill saved at the same moment '
      'restores every row and the same stats into an empty store', () async {
    final at = daysAgo(20);
    await expectRoundTrip([
      fill(1000, daysAgo(40)),
      reading(1500, at, 1),
      fill(2000, at),
    ]);
  });
}
