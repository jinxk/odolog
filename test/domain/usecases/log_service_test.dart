import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/usecases/log_service.dart';

import '../../helpers/fake_service_log_repository.dart';

void main() {
  ValidationFailure validationOf(Either<Failure, ServiceLogEntry> result) {
    return result.getLeft().toNullable()! as ValidationFailure;
  }

  ServiceLogEntry entry({
    double odometer = 1000,
    DateTime? performedAt,
    double? cost,
    String? note,
  }) => ServiceLogEntry(
    id: 0,
    vehicleId: 1,
    template: ServiceTemplate.engineOil,
    performedAt: performedAt ?? DateTime.now(),
    odometer: odometer,
    cost: cost,
    note: note,
  );

  test('a zero odometer is rejected', () async {
    final result = await LogService(
      FakeServiceLogRepository(),
    ).execute(entry(odometer: 0));

    expect(validationOf(result).field, 'odometer');
  });

  test('a service dated in the future is rejected', () async {
    final result = await LogService(
      FakeServiceLogRepository(),
    ).execute(entry(performedAt: DateTime.now().add(const Duration(days: 1))));

    expect(validationOf(result).field, 'performedAt');
  });

  test('a negative cost is rejected', () async {
    final result = await LogService(
      FakeServiceLogRepository(),
    ).execute(entry(cost: -50));

    expect(validationOf(result).field, 'cost');
  });

  test('a note containing a quote mark is rejected', () async {
    final result = await LogService(
      FakeServiceLogRepository(),
    ).execute(entry(note: 'a "quoted" note'));

    expect(validationOf(result).field, 'note');
  });

  test('a valid service is stored and given an id', () async {
    final repo = FakeServiceLogRepository();
    final result = await LogService(repo).execute(entry());

    final stored = result.getRight().toNullable()!;
    expect(stored.id, 1);
    expect(repo.entries, hasLength(1));
  });
}
