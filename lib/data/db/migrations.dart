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

  static final Map<int, Migration> _steps = {};

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
