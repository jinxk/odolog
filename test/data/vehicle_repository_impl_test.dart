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
  late VehicleRepositoryImpl repository;
  late RefuelRepositoryImpl refuels;

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath);
    repository = VehicleRepositoryImpl(VehicleDao(db));
    refuels = RefuelRepositoryImpl(RefuelDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  const fullVehicle = Vehicle(
    id: 0,
    name: 'Daily Ride',
    type: VehicleType.motorcycle,
    fuelCategory: FuelCategory.cng,
    registrationNo: 'MH12AB1234',
    tankCapacity: 12.5,
  );

  test('add then getById round trips every field and enum', () async {
    final added = (await repository.add(fullVehicle)).getRight().toNullable()!;
    expect(added.id, greaterThan(0));

    final fetched = (await repository.getById(
      added.id,
    )).getRight().toNullable()!;
    expect(fetched, added);
    expect(fetched.type, VehicleType.motorcycle);
    expect(fetched.fuelCategory, FuelCategory.cng);
    expect(fetched.registrationNo, 'MH12AB1234');
    expect(fetched.tankCapacity, 12.5);
  });

  test('a vehicle with only required fields round trips with nulls', () async {
    const minimal = Vehicle(
      id: 0,
      name: 'Bare',
      type: VehicleType.other,
      fuelCategory: FuelCategory.petrol,
    );

    final added = (await repository.add(minimal)).getRight().toNullable()!;
    final fetched = (await repository.getById(
      added.id,
    )).getRight().toNullable()!;
    expect(fetched.registrationNo, isNull);
    expect(fetched.tankCapacity, isNull);
    expect(fetched, added);
  });

  test('getAll returns every stored vehicle', () async {
    await repository.add(fullVehicle);
    await repository.add(
      fullVehicle.copyWith(name: 'Second', fuelCategory: FuelCategory.diesel),
    );

    final all = (await repository.getAll()).getRight().toNullable()!;
    expect(all, hasLength(2));
    expect(
      all.map((v) => v.name),
      containsAll(<String>['Daily Ride', 'Second']),
    );
  });

  test('update persists changed fields', () async {
    final added = (await repository.add(fullVehicle)).getRight().toNullable()!;
    final edited = added.copyWith(name: 'Renamed', tankCapacity: 40);

    final updated = (await repository.update(edited)).getRight().toNullable()!;
    expect(updated, edited);

    final fetched = (await repository.getById(
      added.id,
    )).getRight().toNullable()!;
    expect(fetched.name, 'Renamed');
    expect(fetched.tankCapacity, 40);
  });

  test('getById on a missing id is a NotFoundFailure', () async {
    final result = await repository.getById(999);
    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('update on a missing id is a NotFoundFailure', () async {
    const ghost = Vehicle(
      id: 999,
      name: 'Ghost',
      type: VehicleType.car,
      fuelCategory: FuelCategory.petrol,
    );
    final result = await repository.update(ghost);
    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('deleting a vehicle cascades its refuel entries', () async {
    final vehicle = (await repository.add(
      fullVehicle,
    )).getRight().toNullable()!;
    final other = (await repository.add(
      fullVehicle.copyWith(name: 'Untouched'),
    )).getRight().toNullable()!;

    RefuelEntry entryFor(int vehicleId, double odometer) => RefuelEntry(
      id: 0,
      vehicleId: vehicleId,
      filledAt: DateTime.now(),
      odometer: odometer,
      quantity: 5,
      pricePaid: 400,
    );

    await refuels.add(entryFor(vehicle.id, 100));
    await refuels.add(entryFor(vehicle.id, 300));
    await refuels.add(entryFor(other.id, 100));

    final deleted = await repository.delete(vehicle.id);
    expect(deleted.isRight(), isTrue);

    final gone = (await refuels.getForVehicle(
      vehicle.id,
    )).getRight().toNullable()!;
    expect(gone, isEmpty);

    final survivor = (await refuels.getForVehicle(
      other.id,
    )).getRight().toNullable()!;
    expect(survivor, hasLength(1));
  });
}
