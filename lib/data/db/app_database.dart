import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

/// Opens the SQLite database and owns the schema. Tables and indexes match
/// docs/architecture.md exactly. Foreign keys are enabled per connection
/// because sqflite leaves them off by default.
class AppDatabase {
  const AppDatabase._();

  static const databaseName = 'odolog.db';
  static const schemaVersion = 1;

  /// Opens the database, running configuration, creation, and upgrades. Pass a
  /// [path] in tests (for example `inMemoryDatabasePath`); production leaves it
  /// null and the file lands in the platform databases directory.
  static Future<Database> open({String? path}) async {
    final dbPath = path ?? join(await getDatabasesPath(), databaseName);
    return openDatabase(
      dbPath,
      version: schemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final statement in _schema) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) {
    return Migrations.runUpgrade(db, oldVersion, newVersion);
  }

  static const List<String> _schema = [
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
    'CREATE INDEX idx_entries_vehicle_odo ON refuel_entries (vehicle_id, odometer)',
    'CREATE INDEX idx_entries_vehicle_time ON refuel_entries (vehicle_id, filled_at)',
  ];
}
