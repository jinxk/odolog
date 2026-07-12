import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The v1 vehicles table, exactly as it shipped before the document and claimed
/// mileage columns existed. Inlined here so the test builds a genuine old
/// database rather than the current schema.
const _v1Schema = [
  '''
  CREATE TABLE vehicles (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    name           TEXT    NOT NULL,
    type           TEXT    NOT NULL,
    fuel_category  TEXT    NOT NULL,
    registration   TEXT,
    tank_capacity  REAL
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
    // closing a v1 file and reopening it at v2, which an in-memory handle would
    // not preserve across open calls.
    tempDir = Directory.systemTemp.createTempSync('odolog_migration_test');
    dbPath = '${tempDir.path}/odolog.db';
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test(
    'v1 to v2 adds the new columns and keeps existing data intact',
    () async {
      // Build a version 1 database with one vehicle and one refuel.
      final v1 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, version) async {
            final batch = db.batch();
            for (final statement in _v1Schema) {
              batch.execute(statement);
            }
            await batch.commit(noResult: true);
          },
        ),
      );
      final vehicleId = await v1.insert('vehicles', {
        'name': 'Swift',
        'type': 'car',
        'fuel_category': 'petrol',
        'registration': 'MH12AB1234',
        'tank_capacity': 35.0,
      });
      await v1.insert('refuel_entries', {
        'vehicle_id': vehicleId,
        'filled_at': DateTime(2026, 1, 15).millisecondsSinceEpoch,
        'odometer': 10000.0,
        'quantity': 30.0,
        'price_paid': 3000.0,
        'full_tank': 1,
        'odometer_override': 0,
      });
      await v1.close();

      // Reopen through the app, which runs the v1 to v2 upgrade.
      final db = await AppDatabase.open(path: dbPath);
      addTearDown(db.close);

      // The new columns exist.
      final columns = await db.rawQuery('PRAGMA table_info(vehicles)');
      final columnNames = columns.map((row) => row['name']).toSet();
      expect(
        columnNames,
        containsAll(<String>[
          'claimed_mileage',
          'insurance_expiry',
          'puc_expiry',
          'rc_expiry',
          'fitness_expiry',
        ]),
      );

      // The original vehicle data survived, and the new columns read back null.
      final vehicle = (await db.query('vehicles')).single;
      expect(vehicle['name'], 'Swift');
      expect(vehicle['registration'], 'MH12AB1234');
      expect(vehicle['tank_capacity'], 35.0);
      expect(vehicle['claimed_mileage'], isNull);
      expect(vehicle['insurance_expiry'], isNull);
      expect(vehicle['puc_expiry'], isNull);
      expect(vehicle['rc_expiry'], isNull);
      expect(vehicle['fitness_expiry'], isNull);

      // The refuel row is untouched.
      final refuel = (await db.query('refuel_entries')).single;
      expect(refuel['odometer'], 10000.0);
      expect(refuel['quantity'], 30.0);
      expect(refuel['price_paid'], 3000.0);
    },
  );
}
