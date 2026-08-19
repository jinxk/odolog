import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/add_vehicle.dart';

import '../../helpers/fake_vehicle_repository.dart';

void main() {
  Vehicle vehicle({double? tankCapacity}) => Vehicle(
    id: 0,
    name: 'Activa',
    type: VehicleType.scooter,
    fuelCategory: FuelCategory.petrol,
    tankCapacity: tankCapacity,
  );

  ValidationFailure validationOf(Either<Failure, Vehicle> result) {
    return result.getLeft().toNullable()! as ValidationFailure;
  }

  test('a zero tank capacity is rejected', () async {
    final result = await AddVehicle(
      FakeVehicleRepository(),
    ).execute(vehicle(tankCapacity: 0));

    expect(validationOf(result).field, 'tankCapacity');
  });

  test('a negative tank capacity is rejected', () async {
    final result = await AddVehicle(
      FakeVehicleRepository(),
    ).execute(vehicle(tankCapacity: -5));

    expect(validationOf(result).field, 'tankCapacity');
  });

  test('a null tank capacity is accepted', () async {
    final repo = FakeVehicleRepository();
    final result = await AddVehicle(repo).execute(vehicle());

    expect(result.isRight(), isTrue);
    expect(repo.vehicles.single.tankCapacity, isNull);
  });

  test('a positive tank capacity is accepted', () async {
    final repo = FakeVehicleRepository();
    final result = await AddVehicle(repo).execute(vehicle(tankCapacity: 35));

    expect(result.isRight(), isTrue);
    expect(repo.vehicles.single.tankCapacity, 35);
  });
}
