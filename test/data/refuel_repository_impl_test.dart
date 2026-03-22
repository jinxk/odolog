import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/data/daos/refuel_dao.dart';
import 'package:odolog/data/daos/vehicle_dao.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:odolog/data/repositories/refuel_repository_impl.dart';
import 'package:odolog/data/repositories/vehicle_repository_impl.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late RefuelRepositoryImpl repository;
  late VehicleRepositoryImpl vehicles;
  late int vehicleId;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath);
    repository = RefuelRepositoryImpl(RefuelDao(db));
    vehicles = VehicleRepositoryImpl(VehicleDao(db));
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

  RefuelEntry sample({
    int id = 0,
    int? forVehicle,
    double odometer = 1000,
    DateTime? filledAt,
    bool fullTank = true,
  }) {
    return RefuelEntry(
      id: id,
      vehicleId: forVehicle ?? vehicleId,
      filledAt: filledAt ?? nowInMillis(),
      odometer: odometer,
      quantity: 32.5,
      pricePaid: 3120.75,
      fullTank: fullTank,
    );
  }

  test('add then getById round trips every optional field and flag', () async {
    final entry = RefuelEntry(
      id: 0,
      vehicleId: vehicleId,
      filledAt: nowInMillis(),
      odometer: 12345.6,
      quantity: 28.4,
      pricePaid: 2760.5,
      fullTank: false,
      variantId: 'iocl_xp95',
      variantOther: 'Custom blend',
      stationName: 'Highway Pump',
      notes: 'Topped up before the trip',
      odometerOverride: true,
    );

    final added = (await repository.add(entry)).getRight().toNullable()!;
    expect(added.id, greaterThan(0));

    final fetched = (await repository.getById(
      added.id,
    )).getRight().toNullable()!;
    expect(fetched, added);
    expect(fetched.fullTank, isFalse);
    expect(fetched.odometerOverride, isTrue);
    expect(fetched.variantId, 'iocl_xp95');
    expect(fetched.variantOther, 'Custom blend');
    expect(fetched.stationName, 'Highway Pump');
    expect(fetched.notes, 'Topped up before the trip');
  });

  test('an entry with all optional fields null round trips', () async {
    final added = (await repository.add(sample())).getRight().toNullable()!;
    final fetched = (await repository.getById(
      added.id,
    )).getRight().toNullable()!;
    expect(fetched.variantId, isNull);
    expect(fetched.variantOther, isNull);
    expect(fetched.stationName, isNull);
    expect(fetched.notes, isNull);
    expect(fetched, added);
  });

  test('getForVehicle orders by odometer then filled_at', () async {
    final earlier = DateTime.now().subtract(const Duration(hours: 1));
    final later = DateTime.now();

    await repository.add(sample(odometer: 3000));
    await repository.add(sample(odometer: 1000, filledAt: later));
    await repository.add(sample(odometer: 1000, filledAt: earlier));
    await repository.add(sample(odometer: 2000));

    final ordered = (await repository.getForVehicle(
      vehicleId,
    )).getRight().toNullable()!;

    expect(ordered.map((e) => e.odometer), [1000, 1000, 2000, 3000]);
    // Same odometer breaks ties by the earlier fill time.
    expect(ordered[0].filledAt.isBefore(ordered[1].filledAt), isTrue);
  });

  test('update persists changes', () async {
    final added = (await repository.add(sample())).getRight().toNullable()!;
    final edited = added.copyWith(
      odometer: 1500,
      pricePaid: 4000,
      notes: 'Corrected',
    );

    final updated = (await repository.update(edited)).getRight().toNullable()!;
    expect(updated, edited);

    final fetched = (await repository.getById(
      added.id,
    )).getRight().toNullable()!;
    expect(fetched.odometer, 1500);
    expect(fetched.pricePaid, 4000);
    expect(fetched.notes, 'Corrected');
  });

  test('delete removes the entry', () async {
    final added = (await repository.add(sample())).getRight().toNullable()!;

    final deleted = await repository.delete(added.id);
    expect(deleted.isRight(), isTrue);

    final result = await repository.getById(added.id);
    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('getById and update on a missing id are NotFoundFailure', () async {
    expect(
      (await repository.getById(999)).getLeft().toNullable(),
      isA<NotFoundFailure>(),
    );
    expect(
      (await repository.update(sample(id: 999))).getLeft().toNullable(),
      isA<NotFoundFailure>(),
    );
  });

  test('entries never mix between two vehicles', () async {
    final second = (await vehicles.add(
      const Vehicle(
        id: 0,
        name: 'Second Car',
        type: VehicleType.car,
        fuelCategory: FuelCategory.diesel,
      ),
    )).getRight().toNullable()!;

    await repository.add(sample(odometer: 100));
    await repository.add(sample(odometer: 200));
    await repository.add(sample(forVehicle: second.id, odometer: 500));

    final first = (await repository.getForVehicle(
      vehicleId,
    )).getRight().toNullable()!;
    final other = (await repository.getForVehicle(
      second.id,
    )).getRight().toNullable()!;

    expect(first, hasLength(2));
    expect(first.every((e) => e.vehicleId == vehicleId), isTrue);
    expect(other, hasLength(1));
    expect(other.single.vehicleId, second.id);
  });
}
