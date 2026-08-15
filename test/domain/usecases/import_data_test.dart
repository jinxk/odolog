import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/expense.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/add_vehicle.dart';
import 'package:odolog/domain/usecases/import_data.dart';
import 'package:odolog/domain/usecases/list_vehicles.dart';
import 'package:odolog/domain/usecases/log_expense.dart';
import 'package:odolog/domain/usecases/log_odometer_reading.dart';
import 'package:odolog/domain/usecases/log_refuel.dart';
import 'package:odolog/domain/usecases/log_service.dart';

import '../../helpers/entry_builder.dart';
import '../../helpers/fake_data_bundle_codec.dart';
import '../../helpers/fake_expense_repository.dart';
import '../../helpers/fake_odometer_reading_repository.dart';
import '../../helpers/fake_refuel_repository.dart';
import '../../helpers/fake_service_log_repository.dart';
import '../../helpers/fake_unit_of_work.dart';
import '../../helpers/fake_vehicle_repository.dart';

void main() {
  // Id 1 to match the vehicleId the entry builder stamps on a refuel, the way
  // an exported bundle carries the ids its rows point at.
  const vehicle = Vehicle(
    id: 1,
    name: 'Swift',
    type: VehicleType.car,
    fuelCategory: FuelCategory.petrol,
  );

  ImportData importer({
    FakeVehicleRepository? vehicleRepo,
    FakeRefuelRepository? refuelRepo,
    FakeOdometerReadingRepository? readingRepo,
    FakeUnitOfWork? unitOfWork,
    required FakeDataBundleCodec codec,
  }) {
    final vehicles = vehicleRepo ?? FakeVehicleRepository();
    final refuels = refuelRepo ?? FakeRefuelRepository();
    final readings = readingRepo ?? FakeOdometerReadingRepository();
    return ImportData(
      AddVehicle(vehicles),
      LogRefuel(refuels, readings),
      LogService(FakeServiceLogRepository()),
      LogExpense(FakeExpenseRepository()),
      LogOdometerReading(readings, refuels),
      ListVehicles(vehicles),
      codec,
      unitOfWork ?? FakeUnitOfWork(),
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
          odometerReadings: const [],
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
        odometerReadings: const [],
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
        odometerReadings: const [],
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

  test('a rejected row aborts the unit of work so nothing commits', () async {
    final unitOfWork = FakeUnitOfWork();
    final codec = FakeDataBundleCodec(
      decodeResult: right((
        vehicles: [vehicle],
        entries: [entry(id: 0, odometer: 1000, quantity: 0, pricePaid: 2000)],
        serviceLog: const [],
        odometerReadings: const [],
        expenses: const [],
      )),
    );

    final result = await importer(
      codec: codec,
      unitOfWork: unitOfWork,
    ).execute('...');

    expect(result.isLeft(), isTrue);
    expect(unitOfWork.ran, isTrue);
    expect(unitOfWork.rolledBack, isTrue);
  });

  test('a clean bundle leaves the unit of work committed', () async {
    final unitOfWork = FakeUnitOfWork();
    final codec = FakeDataBundleCodec(
      decodeResult: right((
        vehicles: [vehicle],
        entries: const [],
        serviceLog: const [],
        odometerReadings: const [],
        expenses: const [],
      )),
    );

    final result = await importer(
      codec: codec,
      unitOfWork: unitOfWork,
    ).execute('...');

    expect(result.isRight(), isTrue);
    expect(unitOfWork.ran, isTrue);
    expect(unitOfWork.rolledBack, isFalse);
  });

  test(
    'a refuel naming a vehicle nobody has is refused before any write',
    () async {
      final vehicleRepo = FakeVehicleRepository();
      final unitOfWork = FakeUnitOfWork();
      final codec = FakeDataBundleCodec(
        decodeResult: right((
          vehicles: [vehicle],
          entries: [
            entry(id: 0, odometer: 1000, quantity: 20, pricePaid: 2000),
            entry(
              id: 0,
              odometer: 2000,
              quantity: 20,
              pricePaid: 2000,
              vehicleId: 7,
            ),
          ],
          serviceLog: const [],
          odometerReadings: const [],
          expenses: const [],
        )),
      );

      final result = await importer(
        vehicleRepo: vehicleRepo,
        codec: codec,
        unitOfWork: unitOfWork,
      ).execute('...');

      final failure = result.getLeft().toNullable()! as ValidationFailure;
      expect(failure.field, 'vehicleId');
      expect(
        failure.reason,
        'refuels[1]: Vehicle 7 is not in this backup or on '
        'this device.',
      );
      expect(unitOfWork.ran, isFalse);
      expect(vehicleRepo.vehicles, isEmpty);
    },
  );

  test(
    'an expense naming a vehicle already on the device is accepted',
    () async {
      final vehicleRepo = FakeVehicleRepository([vehicle]);
      final codec = FakeDataBundleCodec(
        decodeResult: right((
          vehicles: const <Vehicle>[],
          entries: const [],
          serviceLog: const [],
          odometerReadings: const [],
          expenses: [
            Expense(
              id: 0,
              vehicleId: vehicle.id,
              amount: 500,
              date: DateTime.now().subtract(const Duration(days: 1)),
              category: 'Parking',
            ),
          ],
        )),
      );

      final result = await importer(
        vehicleRepo: vehicleRepo,
        codec: codec,
      ).execute('...');

      expect(result.isRight(), isTrue);
    },
  );

  test(
    'a database failure from a write is located like a validation one',
    () async {
      final codec = FakeDataBundleCodec(
        decodeResult: right((
          vehicles: [vehicle],
          entries: const [],
          serviceLog: const [],
          odometerReadings: const [],
          expenses: const [],
        )),
      );

      final result = await importer(
        vehicleRepo: FakeVehicleRepository(
          const [],
          const DatabaseFailure('disk is full'),
        ),
        codec: codec,
      ).execute('...');

      final failure = result.getLeft().toNullable()! as DatabaseFailure;
      expect(failure.message, 'vehicles[0]: disk is full');
    },
  );
}
