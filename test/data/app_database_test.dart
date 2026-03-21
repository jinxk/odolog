import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:odolog/data/db/migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Set<String>> namesOfType(String type) async {
    final rows = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = ?',
      [type],
    );
    return rows.map((row) => row['name']! as String).toSet();
  }

  test('onCreate builds both tables', () async {
    final tables = await namesOfType('table');
    expect(tables, containsAll(<String>['vehicles', 'refuel_entries']));
  });

  test('the foreign_keys pragma is on for the connection', () async {
    final result = await db.rawQuery('PRAGMA foreign_keys');
    expect(result.first.values.first, 1);
  });

  test('both refuel indexes exist', () async {
    final indexes = await namesOfType('index');
    expect(
      indexes,
      containsAll(<String>[
        'idx_entries_vehicle_odo',
        'idx_entries_vehicle_time',
      ]),
    );
  });

  test('runUpgrade at the current version is a no-op', () async {
    await Migrations.runUpgrade(
      db,
      AppDatabase.schemaVersion,
      AppDatabase.schemaVersion,
    );
    final tables = await namesOfType('table');
    expect(tables, containsAll(<String>['vehicles', 'refuel_entries']));
  });
}
