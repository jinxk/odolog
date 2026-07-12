import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/repositories/service_log_repository.dart';
import 'package:odolog/domain/usecases/export_data.dart';

import '../../helpers/entry_builder.dart';
import '../../helpers/fake_data_bundle_codec.dart';
import '../../helpers/fake_expense_repository.dart';
import '../../helpers/fake_refuel_repository.dart';
import '../../helpers/fake_service_log_repository.dart';
import '../../helpers/fake_vehicle_repository.dart';

/// Always fails, to prove a mid-assembly failure short circuits before the
/// codec is ever reached.
class _FailingServiceLogRepository implements ServiceLogRepository {
  @override
  Future<Result<ServiceLogEntry>> add(ServiceLogEntry entry) async =>
      left(const DatabaseFailure('unavailable'));

  @override
  Future<Result<Unit>> delete(int id) async =>
      left(const DatabaseFailure('unavailable'));

  @override
  Future<Result<List<ServiceLogEntry>>> getForVehicle(int vehicleId) async =>
      left(const DatabaseFailure('unavailable'));
}

void main() {
  const vehicle = Vehicle(
    id: 1,
    name: 'Swift',
    type: VehicleType.car,
    fuelCategory: FuelCategory.petrol,
  );

  test(
    'assembles every vehicle and its entries, then hands them to the codec',
    () async {
      final refuel = entry(
        id: 1,
        odometer: 1000,
        quantity: 20,
        pricePaid: 2000,
      );
      final codec = FakeDataBundleCodec();
      final result = await ExportData(
        FakeVehicleRepository([vehicle]),
        FakeRefuelRepository([refuel]),
        FakeServiceLogRepository(),
        FakeExpenseRepository(),
        codec,
      ).execute();

      expect(result.getRight().toNullable(), 'encoded');
      expect(codec.lastEncoded!.vehicles, [vehicle]);
      expect(codec.lastEncoded!.entries, [refuel]);
    },
  );

  test(
    'a repository failure short circuits before reaching the codec',
    () async {
      final codec = FakeDataBundleCodec();
      final result = await ExportData(
        FakeVehicleRepository([vehicle]),
        FakeRefuelRepository(),
        _FailingServiceLogRepository(),
        FakeExpenseRepository(),
        codec,
      ).execute();

      expect(result.isLeft(), isTrue);
      expect(codec.lastEncoded, isNull);
    },
  );
}
