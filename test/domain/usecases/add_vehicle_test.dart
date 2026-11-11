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

  test('no tank capacity or a positive one is accepted', () async {
    final repo = FakeVehicleRepository();

    expect((await AddVehicle(repo).execute(vehicle())).isRight(), isTrue);
    expect(
      (await AddVehicle(repo).execute(vehicle(tankCapacity: 35))).isRight(),
      isTrue,
    );
    expect(repo.vehicles.map((v) => v.tankCapacity), [null, 35]);
  });
}
