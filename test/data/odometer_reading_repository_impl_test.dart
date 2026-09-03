import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/data/daos/odometer_reading_dao.dart';
import 'package:odolog/data/daos/vehicle_dao.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:odolog/data/repositories/odometer_reading_repository_impl.dart';
import 'package:odolog/data/repositories/vehicle_repository_impl.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late OdometerReadingRepositoryImpl repository;
  late int vehicleId;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath);
    repository = OdometerReadingRepositoryImpl(OdometerReadingDao(db));
    final vehicles = VehicleRepositoryImpl(VehicleDao(db));
    final vehicle = (await vehicles.add(
      const Vehicle(
        id: 0,
        name: 'Test Car',
        type: VehicleType.car,
        fuelCategory: FuelCategory.petrol,
      ),
    )).getRight().toNullable()!;
    vehicleId = vehicle.id;
  });

  tearDown(() async {
    await db.close();
  });

  // Storage keeps epoch millis, so tie times to a millisecond-precision now to
  // survive the round trip without losing microseconds.
  DateTime nowInMillis() => DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().millisecondsSinceEpoch,
  );

  test('getForVehicle orders by odometer then recorded_at', () async {
    final earlier = nowInMillis().subtract(const Duration(hours: 1));
    final later = nowInMillis();

    await repository.add(
      OdometerReading(
        id: 0,
        vehicleId: vehicleId,
        odometer: 3000,
        recordedAt: nowInMillis(),
      ),
    );
    await repository.add(
      OdometerReading(
        id: 0,
        vehicleId: vehicleId,
        odometer: 1000,
        recordedAt: later,
      ),
    );
    await repository.add(
      OdometerReading(
        id: 0,
        vehicleId: vehicleId,
        odometer: 1000,
        recordedAt: earlier,
      ),
    );
    await repository.add(
      OdometerReading(
        id: 0,
        vehicleId: vehicleId,
        odometer: 2000,
        recordedAt: nowInMillis(),
      ),
    );

    final ordered = (await repository.getForVehicle(
      vehicleId,
    )).getRight().toNullable()!;

    expect(ordered.map((r) => r.odometer), [1000, 1000, 2000, 3000]);
    // Same odometer breaks ties by the earlier recorded_at.
    expect(ordered[0].recordedAt.isBefore(ordered[1].recordedAt), isTrue);
  });

  test('deleting a reading is idempotent and leaves the rest alone', () async {
    final first = (await repository.add(
      OdometerReading(
        id: 0,
        vehicleId: vehicleId,
        odometer: 1000,
        recordedAt: nowInMillis(),
      ),
    )).getRight().toNullable()!;
    final second = (await repository.add(
      OdometerReading(
        id: 0,
        vehicleId: vehicleId,
        odometer: 2000,
        recordedAt: nowInMillis(),
      ),
    )).getRight().toNullable()!;

    expect((await repository.delete(first.id)).isRight(), isTrue);
    expect((await repository.delete(first.id)).isRight(), isTrue);
    expect((await repository.delete(999)).isRight(), isTrue);

    final remaining = (await repository.getForVehicle(
      vehicleId,
    )).getRight().toNullable()!;
    expect(remaining, [second]);
  });
}
