import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/edit_vehicle.dart';

import '../../helpers/fake_vehicle_repository.dart';

void main() {
  const seed = Vehicle(
    id: 1,
    name: 'Activa',
    type: VehicleType.scooter,
    fuelCategory: FuelCategory.petrol,
  );

  ValidationFailure validationOf(Either<Failure, Vehicle> result) {
    return result.getLeft().toNullable()! as ValidationFailure;
  }

  test('a zero tank capacity is rejected', () async {
    final result = await EditVehicle(
      FakeVehicleRepository([seed]),
    ).execute(seed.copyWith(tankCapacity: 0));

    expect(validationOf(result).field, 'tankCapacity');
  });

  test('no tank capacity or a positive one is accepted', () async {
    final repo = FakeVehicleRepository([seed]);

    expect((await EditVehicle(repo).execute(seed)).isRight(), isTrue);
    expect(repo.vehicles.single.tankCapacity, isNull);

    final result = await EditVehicle(
      repo,
    ).execute(seed.copyWith(tankCapacity: 40));

    expect(result.isRight(), isTrue);
    expect(repo.vehicles.single.tankCapacity, 40);
  });
}
