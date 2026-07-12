import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The v2 schema, exactly as it shipped before the service log, expenses, and
/// service interval columns existed. Inlined here so the test builds a
/// genuine old database rather than the current schema.
const _v2Schema = [
  '''
  CREATE TABLE vehicles (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    name              TEXT    NOT NULL,
    type              TEXT    NOT NULL,
    fuel_category     TEXT    NOT NULL,
    registration      TEXT,
    tank_capacity     REAL,
    claimed_mileage   REAL,
    insurance_expiry  INTEGER,
    puc_expiry        INTEGER,
    rc_expiry         INTEGER,
    fitness_expiry    INTEGER
  )
  ''',
  '''
  CREATE TABLE refuel_entries (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id        INTEGER NOT NULL,
    filled_at         INTEGER NOT NULL,
    odometer          REAL    NOT NULL,
    quantity          REAL    NOT NULL,
    price_paid        REAL    NOT NULL,
    full_tank         INTEGER NOT NULL DEFAULT 1,
    variant_id        TEXT,
    variant_other     TEXT,
    station_name      TEXT,
    notes             TEXT,
    odometer_override INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles (id) ON DELETE CASCADE
  )
  ''',
];

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late Directory tempDir;
  late String dbPath;

  setUp(() {
    // A real file, not an in-memory database: the migration is exercised by
    // closing a v2 file and reopening it at v3, which an in-memory handle
    // would not preserve across open calls.
    tempDir = Directory.systemTemp.createTempSync('odolog_migration_test');
    dbPath = '${tempDir.path}/odolog.db';
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('v2 to v3 adds the service tables and interval columns, keeping data '
      'intact', () async {
    // Build a version 2 database with one vehicle and one refuel.
    final v2 = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          final batch = db.batch();
          for (final statement in _v2Schema) {
            batch.execute(statement);
          }
          await batch.commit(noResult: true);
        },
      ),
    );
    final vehicleId = await v2.insert('vehicles', {
      'name': 'Swift',
      'type': 'car',
      'fuel_category': 'petrol',
      'registration': 'MH12AB1234',
      'tank_capacity': 35.0,
      'claimed_mileage': 21.5,
    });
    await v2.insert('refuel_entries', {
      'vehicle_id': vehicleId,
      'filled_at': DateTime(2026, 1, 15).millisecondsSinceEpoch,
      'odometer': 10000.0,
      'quantity': 30.0,
      'price_paid': 3000.0,
      'full_tank': 1,
      'odometer_override': 0,
    });
    await v2.close();

    // Reopen through the app, which runs the v2 to v3 upgrade.
    final db = await AppDatabase.open(path: dbPath);
    addTearDown(db.close);

    // The new vehicle columns exist.
    final vehicleColumns = await db.rawQuery('PRAGMA table_info(vehicles)');
    final vehicleColumnNames = vehicleColumns.map((row) => row['name']).toSet();
    expect(
      vehicleColumnNames,
      containsAll(<String>[
        'engine_oil_interval_km',
        'general_service_interval_days',
      ]),
    );

    // The new tables exist.
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tableNames = tables.map((row) => row['name']).toSet();
    expect(tableNames, containsAll(<String>['service_log', 'expenses']));

    // The original vehicle data survived, and the new columns read back
    // null.
    final vehicle = (await db.query('vehicles')).single;
    expect(vehicle['name'], 'Swift');
    expect(vehicle['claimed_mileage'], 21.5);
    expect(vehicle['engine_oil_interval_km'], isNull);
    expect(vehicle['general_service_interval_days'], isNull);

    // The refuel row is untouched.
    final refuel = (await db.query('refuel_entries')).single;
    expect(refuel['odometer'], 10000.0);
    expect(refuel['quantity'], 30.0);

    // The new tables accept a row each, with the foreign key intact.
    final serviceId = await db.insert('service_log', {
      'vehicle_id': vehicleId,
      'template': 'engineOil',
      'performed_at': DateTime(2026, 1, 10).millisecondsSinceEpoch,
      'odometer': 9800.0,
    });
    expect(serviceId, greaterThan(0));
    final expenseId = await db.insert('expenses', {
      'vehicle_id': vehicleId,
      'amount': 800.0,
      'date': DateTime(2026, 1, 20).millisecondsSinceEpoch,
      'category': 'Tyre',
    });
    expect(expenseId, greaterThan(0));
  });
}
