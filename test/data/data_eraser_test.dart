import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/data/daos/expense_dao.dart';
import 'package:odolog/data/daos/odometer_reading_dao.dart';
import 'package:odolog/data/daos/refuel_dao.dart';
import 'package:odolog/data/daos/service_log_dao.dart';
import 'package:odolog/data/daos/vehicle_dao.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:odolog/data/db/sqflite_data_eraser.dart';
import 'package:odolog/domain/entities/expense.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/entry_builder.dart';

/// The erase against the real data layer: real DAOs and a real sqflite
/// transaction, so the assertion is what is left in the tables rather than
/// what a fake recorded.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late VehicleDao vehicles;
  late RefuelDao refuels;
  late ServiceLogDao serviceLog;
  late ExpenseDao expenses;
  late OdometerReadingDao readings;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath);
    vehicles = VehicleDao(db);
    refuels = RefuelDao(db);
    serviceLog = ServiceLogDao(db);
    expenses = ExpenseDao(db);
    readings = OdometerReadingDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('erasing clears every table and resets the ids', () async {
    const vehicle = Vehicle(
      id: 0,
      name: 'Swift',
      type: VehicleType.car,
      fuelCategory: FuelCategory.petrol,
    );
    final vehicleId = await vehicles.insert(vehicle);

    await refuels.insert(
      entry(
        id: 0,
        vehicleId: vehicleId,
        odometer: 1000,
        quantity: 20,
        pricePaid: 2000,
      ),
    );
    await serviceLog.insert(
      ServiceLogEntry(
        id: 0,
        vehicleId: vehicleId,
        template: ServiceTemplate.engineOil,
        performedAt: DateTime.now(),
        odometer: 1000,
      ),
    );
    await expenses.insert(
      Expense(
        id: 0,
        vehicleId: vehicleId,
        amount: 500,
        date: DateTime.now(),
        category: 'Repair',
      ),
    );
    await readings.insert(
      OdometerReading(
        id: 0,
        vehicleId: vehicleId,
        odometer: 1200,
        recordedAt: DateTime.now(),
      ),
    );

    final result = await SqfliteDataEraser(db).eraseAll();

    expect(result.isRight(), isTrue);
    expect(await vehicles.getAll(), isEmpty);
    expect(await refuels.getForVehicle(vehicleId), isEmpty);
    expect(await serviceLog.getForVehicle(vehicleId), isEmpty);
    expect(await expenses.getForVehicle(vehicleId), isEmpty);
    expect(await readings.getForVehicle(vehicleId), isEmpty);

    const freshVehicle = Vehicle(
      id: 0,
      name: 'Activa',
      type: VehicleType.scooter,
      fuelCategory: FuelCategory.petrol,
    );
    final freshId = await vehicles.insert(freshVehicle);
    expect(freshId, 1);
  });
}
