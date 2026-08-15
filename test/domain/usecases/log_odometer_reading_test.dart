import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/usecases/log_odometer_reading.dart';

import '../../helpers/entry_builder.dart';
import '../../helpers/fake_odometer_reading_repository.dart';
import '../../helpers/fake_refuel_repository.dart';

void main() {
  final now = DateTime.now();
  final lastMonth = now.subtract(const Duration(days: 30));
  final lastWeek = now.subtract(const Duration(days: 7));
  final yesterday = now.subtract(const Duration(days: 1));

  ValidationFailure validationOf(Either<Failure, OdometerReading> result) {
    return result.getLeft().toNullable()! as ValidationFailure;
  }

  OdometerReading reading({
    int id = 0,
    required double odometer,
    DateTime? recordedAt,
    String? note,
  }) => OdometerReading(
    id: id,
    vehicleId: 1,
    odometer: odometer,
    recordedAt: recordedAt ?? now,
    note: note,
  );

  test('a reading beyond the last fill is stored', () async {
    final readings = FakeOdometerReadingRepository();
    final refuels = FakeRefuelRepository([
      entry(
        id: 1,
        odometer: 10000,
        quantity: 30,
        pricePaid: 3000,
        filledAt: lastWeek,
      ),
    ]);

    final result = await LogOdometerReading(
      readings,
      refuels,
    ).execute(reading(odometer: 10400));

    expect(result.isRight(), isTrue);
    expect(readings.readings.single.odometer, 10400);
    expect(readings.readings.single.id, 1);
  });

  test('zero odometer is rejected', () async {
    final result = await LogOdometerReading(
      FakeOdometerReadingRepository(),
      FakeRefuelRepository(),
    ).execute(reading(odometer: 0));

    expect(validationOf(result).field, 'odometer');
  });

  test('a reading dated in the future is rejected', () async {
    final result =
        await LogOdometerReading(
          FakeOdometerReadingRepository(),
          FakeRefuelRepository(),
        ).execute(
          reading(odometer: 500, recordedAt: now.add(const Duration(days: 1))),
        );

    expect(validationOf(result).field, 'recordedAt');
  });

  test('a note containing a quote mark is rejected', () async {
    final result = await LogOdometerReading(
      FakeOdometerReadingRepository(),
      FakeRefuelRepository(),
    ).execute(reading(odometer: 500, note: 'said "check it"'));

    expect(validationOf(result).field, 'note');
  });

  test('a reading below the fill before it is rejected', () async {
    final readings = FakeOdometerReadingRepository();
    final refuels = FakeRefuelRepository([
      entry(
        id: 1,
        odometer: 10000,
        quantity: 30,
        pricePaid: 3000,
        filledAt: lastWeek,
      ),
    ]);

    final result = await LogOdometerReading(
      readings,
      refuels,
    ).execute(reading(odometer: 9500));

    expect(validationOf(result).field, 'odometer');
    expect(
      validationOf(result).reason,
      'Odometer must be greater than the previous reading.',
    );
    expect(readings.readings, isEmpty);
  });

  test('a backdated reading above the fill after it is rejected', () async {
    final readings = FakeOdometerReadingRepository();
    final refuels = FakeRefuelRepository([
      entry(
        id: 1,
        odometer: 10000,
        quantity: 30,
        pricePaid: 3000,
        filledAt: lastMonth,
      ),
      entry(
        id: 2,
        odometer: 11000,
        quantity: 30,
        pricePaid: 3000,
        filledAt: yesterday,
      ),
    ]);

    final result = await LogOdometerReading(
      readings,
      refuels,
    ).execute(reading(odometer: 11500, recordedAt: lastWeek));

    expect(
      validationOf(result).reason,
      'Odometer must be less than the next reading.',
    );
  });

  test('a backdated reading between two fills is accepted', () async {
    final readings = FakeOdometerReadingRepository();
    final refuels = FakeRefuelRepository([
      entry(
        id: 1,
        odometer: 10000,
        quantity: 30,
        pricePaid: 3000,
        filledAt: lastMonth,
      ),
      entry(
        id: 2,
        odometer: 11000,
        quantity: 30,
        pricePaid: 3000,
        filledAt: yesterday,
      ),
    ]);

    final result = await LogOdometerReading(
      readings,
      refuels,
    ).execute(reading(odometer: 10600, recordedAt: lastWeek));

    expect(result.isRight(), isTrue);
  });

  test('an earlier reading is a neighbour too', () async {
    final readings = FakeOdometerReadingRepository([
      OdometerReading(
        id: 1,
        vehicleId: 1,
        odometer: 12000,
        recordedAt: lastWeek,
      ),
    ]);

    final result = await LogOdometerReading(
      readings,
      FakeRefuelRepository(),
    ).execute(reading(odometer: 11800));

    expect(validationOf(result).field, 'odometer');
    expect(readings.readings, hasLength(1));
  });
}
