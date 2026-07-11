import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/add_vehicle.dart';
import 'package:odolog/domain/usecases/import_data.dart';
import 'package:odolog/domain/usecases/log_expense.dart';
import 'package:odolog/domain/usecases/log_refuel.dart';
import 'package:odolog/domain/usecases/log_service.dart';

import '../../helpers/entry_builder.dart';
import '../../helpers/fake_data_bundle_codec.dart';
import '../../helpers/fake_expense_repository.dart';
import '../../helpers/fake_refuel_repository.dart';
import '../../helpers/fake_service_log_repository.dart';
import '../../helpers/fake_vehicle_repository.dart';

void main() {
  const vehicle = Vehicle(
    id: 0,
    name: 'Swift',
    type: VehicleType.car,
    fuelCategory: FuelCategory.petrol,
  );

  ImportData importer({
    FakeVehicleRepository? vehicleRepo,
    FakeRefuelRepository? refuelRepo,
    required FakeDataBundleCodec codec,
  }) {
    return ImportData(
      AddVehicle(vehicleRepo ?? FakeVehicleRepository()),
      LogRefuel(refuelRepo ?? FakeRefuelRepository()),
      LogService(FakeServiceLogRepository()),
      LogExpense(FakeExpenseRepository()),
      codec,
    );
  }

  test(
    'a decode failure is returned without touching any repository',
    () async {
      final vehicleRepo = FakeVehicleRepository();
      final codec = FakeDataBundleCodec(
        decodeResult: left(
          const ValidationFailure(field: 'schema', reason: 'not a backup file'),
        ),
      );

      final result = await importer(
        vehicleRepo: vehicleRepo,
        codec: codec,
      ).execute('garbage');

      expect(result.isLeft(), isTrue);
      expect(vehicleRepo.vehicles, isEmpty);
    },
  );

  test(
    'a decoded bundle is written into the repositories and handed back',
    () async {
      final vehicleRepo = FakeVehicleRepository();
      final codec = FakeDataBundleCodec(
        decodeResult: right((
          vehicles: [vehicle],
          entries: const [],
          serviceLog: const [],
          expenses: const [],
        )),
      );

      final result = await importer(
        vehicleRepo: vehicleRepo,
        codec: codec,
      ).execute('"odolog","3"...');

      expect(vehicleRepo.vehicles, hasLength(1));
      expect(vehicleRepo.vehicles.single.name, 'Swift');
      final bundle = result.getRight().toNullable()!;
      expect(bundle.vehicles, hasLength(1));
    },
  );

  test('an imported refuel passes the same checks a form entry does', () async {
    final refuelRepo = FakeRefuelRepository();
    final codec = FakeDataBundleCodec(
      decodeResult: right((
        vehicles: [vehicle],
        entries: [entry(id: 0, odometer: 1000, quantity: 0, pricePaid: 2000)],
        serviceLog: const [],
        expenses: const [],
      )),
    );

    final result = await importer(
      refuelRepo: refuelRepo,
      codec: codec,
    ).execute('...');

    final failure = result.getLeft().toNullable()! as ValidationFailure;
    expect(failure.field, 'quantity');
    expect(failure.reason, startsWith('refuels[0]:'));
    expect(refuelRepo.entries, isEmpty);
  });

  test('a bundle holding a backdated fill imports cleanly', () async {
    final refuelRepo = FakeRefuelRepository();
    final codec = FakeDataBundleCodec(
      decodeResult: right((
        vehicles: [vehicle],
        entries: [
          entry(
            id: 0,
            odometer: 1000,
            quantity: 20,
            pricePaid: 2000,
            filledAt: DateTime.utc(2020, 1, 1),
          ),
          entry(
            id: 0,
            odometer: 2000,
            quantity: 20,
            pricePaid: 2000,
            filledAt: DateTime.utc(2020, 1, 20),
          ),
          entry(
            id: 0,
            odometer: 1500,
            quantity: 20,
            pricePaid: 2000,
            filledAt: DateTime.utc(2020, 1, 10),
          ),
        ],
        serviceLog: const [],
        expenses: const [],
      )),
    );

    final result = await importer(
      refuelRepo: refuelRepo,
      codec: codec,
    ).execute('...');

    expect(result.isRight(), isTrue);
    expect(refuelRepo.entries, hasLength(3));
  });
}
