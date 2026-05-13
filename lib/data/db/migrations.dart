import 'package:sqflite/sqflite.dart';

/// One forward-only step that upgrades the schema to a given version.
typedef Migration = Future<void> Function(DatabaseExecutor db);

/// Forward-only migration scaffolding. Version 1 is the baseline that
/// [AppDatabase] builds in `onCreate`, so it has no step here. A future
/// version N registers one entry keyed by N that migrates a version N-1
/// database additively, and ships with a test that opens the old version,
/// runs the upgrade, and asserts the data survived.
class Migrations {
  const Migrations._();

  static final Map<int, Migration> _steps = {
    // v2 adds the claimed mileage figure and the four document expiry dates to
    // vehicles. Each column is nullable with no default, so every existing row
    // keeps its data and reads back null for the new fields. Additive only, so
    // no data is rewritten or lost.
    2: (db) async {
      await db.execute('ALTER TABLE vehicles ADD COLUMN claimed_mileage REAL');
      await db.execute(
        'ALTER TABLE vehicles ADD COLUMN insurance_expiry INTEGER',
      );
      await db.execute('ALTER TABLE vehicles ADD COLUMN puc_expiry INTEGER');
      await db.execute('ALTER TABLE vehicles ADD COLUMN rc_expiry INTEGER');
      await db.execute(
        'ALTER TABLE vehicles ADD COLUMN fitness_expiry INTEGER',
      );
    },
    // v3 adds the service log and non-fuel expense tables, plus the two
    // per-vehicle service interval columns. Additive only: existing tables and
    // rows are untouched, and the new columns are nullable with no default so
    // every existing vehicle reads its intervals back null and falls back to
    // ServiceDueCalculator's defaults.
    3: (db) async {
      await db.execute(
        'ALTER TABLE vehicles ADD COLUMN engine_oil_interval_km REAL',
      );
      await db.execute(
        'ALTER TABLE vehicles ADD COLUMN general_service_interval_days INTEGER',
      );
      await db.execute('''
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
      ''');
      await db.execute(
        'CREATE INDEX idx_service_log_vehicle ON service_log (vehicle_id)',
      );
      await db.execute('''
        CREATE TABLE expenses (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          vehicle_id    INTEGER NOT NULL,
          amount        REAL    NOT NULL,
          date          INTEGER NOT NULL,
          odometer      REAL,
          category      TEXT    NOT NULL,
          FOREIGN KEY (vehicle_id) REFERENCES vehicles (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_expenses_vehicle ON expenses (vehicle_id)',
      );
    },
  };

  /// Applies every registered step for versions in (oldVersion, newVersion],
  /// in ascending order. Versions without a step are skipped.
  static Future<void> runUpgrade(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      final step = _steps[version];
      if (step != null) {
        await step(db);
      }
    }
  }
}
