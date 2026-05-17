import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/import_data.dart';

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

  test(
    'a decode failure is returned without touching any repository',
    () async {
      final vehicleRepo = FakeVehicleRepository();
      final codec = FakeDataBundleCodec(
        decodeResult: left(
          const ValidationFailure(field: 'schema', reason: 'not a backup file'),
        ),
      );

      final result = await ImportData(
        vehicleRepo,
        FakeRefuelRepository(),
        FakeServiceLogRepository(),
        FakeExpenseRepository(),
        codec,
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

      final result = await ImportData(
        vehicleRepo,
        FakeRefuelRepository(),
        FakeServiceLogRepository(),
        FakeExpenseRepository(),
        codec,
      ).execute('"odolog","3"...');

      expect(vehicleRepo.vehicles, hasLength(1));
      expect(vehicleRepo.vehicles.single.name, 'Swift');
      final bundle = result.getRight().toNullable()!;
      expect(bundle.vehicles, hasLength(1));
    },
  );
}
