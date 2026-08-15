import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The v3 schema, exactly as it shipped before the odometer readings table
/// existed. Inlined here so the test builds a genuine old database rather than
/// the current schema.
const _v3Schema = [
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
    fitness_expiry    INTEGER,
    engine_oil_interval_km        REAL,
    general_service_interval_days INTEGER
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
  '''
  CREATE TABLE service_log (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id    INTEGER NOT NULL,
    template      TEXT    NOT NULL,
    performed_at  INTEGER NOT NULL,
    odometer      REAL    NOT NULL,
    cost          REAL,
    note          TEXT,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles (id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE expenses (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id    INTEGER NOT NULL,
    amount        REAL    NOT NULL,
    date          INTEGER NOT NULL,
    odometer      REAL,
    category      TEXT    NOT NULL,
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
    // closing a v3 file and reopening it at v4, which an in-memory handle
    // would not preserve across open calls.
    tempDir = Directory.systemTemp.createTempSync('odolog_migration_test');
    dbPath = '${tempDir.path}/odolog.db';
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test(
    'v3 to v4 adds the odometer readings table, keeping data intact',
    () async {
      final filledAt = DateTime.now().subtract(const Duration(days: 30));
      // Build a version 3 database with one vehicle and one refuel.
      final v3 = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 3,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, version) async {
            final batch = db.batch();
            for (final statement in _v3Schema) {
              batch.execute(statement);
            }
            await batch.commit(noResult: true);
          },
        ),
      );
      final vehicleId = await v3.insert('vehicles', {
        'name': 'Swift',
        'type': 'car',
        'fuel_category': 'petrol',
        'registration': 'MH12AB1234',
        'tank_capacity': 35.0,
        'claimed_mileage': 21.5,
      });
      await v3.insert('refuel_entries', {
        'vehicle_id': vehicleId,
        'filled_at': filledAt.millisecondsSinceEpoch,
        'odometer': 10000.0,
        'quantity': 30.0,
        'price_paid': 3000.0,
        'full_tank': 1,
        'odometer_override': 0,
      });
      await v3.close();

      // Reopen through the app, which runs the v3 to v4 upgrade.
      final db = await AppDatabase.open(path: dbPath);
      addTearDown(db.close);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      expect(
        tables.map((row) => row['name']).toSet(),
        contains('odometer_readings'),
      );

      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index'",
      );
      expect(
        indexes.map((row) => row['name']).toSet(),
        contains('idx_odometer_readings_vehicle'),
      );

      // The original rows survived.
      final vehicle = (await db.query('vehicles')).single;
      expect(vehicle['name'], 'Swift');
      expect(vehicle['claimed_mileage'], 21.5);
      final refuel = (await db.query('refuel_entries')).single;
      expect(refuel['odometer'], 10000.0);
      expect(refuel['quantity'], 30.0);

      // The new table takes a row, with the foreign key intact.
      final readingId = await db.insert('odometer_readings', {
        'vehicle_id': vehicleId,
        'odometer': 10400.0,
        'recorded_at': DateTime.now().millisecondsSinceEpoch,
        'note': 'Before the service booking',
      });
      expect(readingId, greaterThan(0));
    },
  );
}
