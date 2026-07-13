import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/backup/auto_backup_policy.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/repositories/vehicle_repository.dart';
import 'package:odolog/domain/usecases/export_data.dart';
import 'package:odolog/domain/usecases/run_auto_backup.dart';

import '../../helpers/fake_auto_backup_writer.dart';
import '../../helpers/fake_data_bundle_codec.dart';
import '../../helpers/fake_expense_repository.dart';
import '../../helpers/fake_refuel_repository.dart';
import '../../helpers/fake_service_log_repository.dart';
import '../../helpers/fake_vehicle_repository.dart';

/// A vehicle repository whose read fails, to force [ExportData] to short
/// circuit so [RunAutoBackup] never reaches the writer.
class _FailingVehicleRepository implements VehicleRepository {
  @override
  Future<Result<List<Vehicle>>> getAll() async =>
      left(const DatabaseFailure('unavailable'));

  @override
  Future<Result<Vehicle>> add(Vehicle vehicle) async =>
      left(const DatabaseFailure('unavailable'));

  @override
  Future<Result<Vehicle>> update(Vehicle vehicle) async =>
      left(const DatabaseFailure('unavailable'));

  @override
  Future<Result<Unit>> delete(int id) async =>
      left(const DatabaseFailure('unavailable'));

  @override
  Future<Result<Vehicle>> getById(int id) async =>
      left(const DatabaseFailure('unavailable'));
}

void main() {
  const vehicle = Vehicle(
    id: 1,
    name: 'Swift',
    type: VehicleType.car,
    fuelCategory: FuelCategory.petrol,
  );

  ExportData exportOf(VehicleRepository vehicles) => ExportData(
    vehicles,
    FakeRefuelRepository(),
    FakeServiceLogRepository(),
    FakeExpenseRepository(),
    FakeDataBundleCodec(),
  );

  test('writes today\'s backup with the encoded bundle', () async {
    final writer = FakeAutoBackupWriter();
    final now = DateTime.now();

    final result = await RunAutoBackup(
      exportOf(FakeVehicleRepository([vehicle])),
      writer,
    ).execute(now: now);

    expect(result.isRight(), isTrue);
    expect(writer.writes, hasLength(1));
    expect(writer.writes.single.name, AutoBackupPolicy.fileName(now));
    expect(writer.writes.single.content, 'encoded');
  });

  test('prunes daily backups beyond the newest seven', () async {
    final now = DateTime.now();
    // Seven older days already on disk; writing today makes eight.
    final existing = [
      for (var i = 1; i <= 7; i++)
        AutoBackupPolicy.fileName(now.subtract(Duration(days: i))),
    ];
    final writer = FakeAutoBackupWriter(existing: existing);

    await RunAutoBackup(
      exportOf(FakeVehicleRepository([vehicle])),
      writer,
    ).execute(now: now);

    expect(writer.deleted, [
      AutoBackupPolicy.fileName(now.subtract(const Duration(days: 7))),
    ]);
    expect(writer.files, hasLength(7));
  });

  test('a failed export writes nothing', () async {
    final writer = FakeAutoBackupWriter();

    final result = await RunAutoBackup(
      exportOf(_FailingVehicleRepository()),
      writer,
    ).execute(now: DateTime.now());

    expect(result.isLeft(), isTrue);
    expect(writer.writes, isEmpty);
    expect(writer.deleted, isEmpty);
  });
}
