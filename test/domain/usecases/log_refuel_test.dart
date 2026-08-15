import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/usecases/log_refuel.dart';

import '../../helpers/entry_builder.dart';
import '../../helpers/fake_odometer_reading_repository.dart';
import '../../helpers/fake_refuel_repository.dart';

void main() {
  LogRefuel logRefuel(
    FakeRefuelRepository repo, [
    FakeOdometerReadingRepository? readings,
  ]) => LogRefuel(repo, readings ?? FakeOdometerReadingRepository());

  ValidationFailure validationOf(Either<Failure, RefuelEntry> result) {
    return result.getLeft().toNullable()! as ValidationFailure;
  }

  test('odometer equal to the previous reading is rejected', () async {
    final repo = FakeRefuelRepository([
      entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
    ]);
    final result = await logRefuel(
      repo,
    ).execute(entry(id: 0, odometer: 1000, quantity: 20, pricePaid: 2000));

    expect(validationOf(result).field, 'odometer');
    expect(repo.entries, hasLength(1));
  });

  test('odometer lower than the previous reading is rejected', () async {
    final repo = FakeRefuelRepository([
      entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
    ]);
    final result = await logRefuel(repo).execute(
      entry(
        id: 0,
        odometer: 900,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime.utc(2020, 1, 2),
      ),
    );

    expect(validationOf(result).field, 'odometer');
  });

  test('a backdated fill with an in-between odometer is accepted', () async {
    final repo = FakeRefuelRepository([
      entry(
        id: 1,
        odometer: 1000,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime.utc(2020, 1, 1),
      ),
      entry(
        id: 2,
        odometer: 2000,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime.utc(2020, 1, 20),
      ),
    ]);
    final result = await logRefuel(repo).execute(
      entry(
        id: 0,
        odometer: 1500,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime.utc(2020, 1, 10),
      ),
    );

    expect(result.isRight(), isTrue);
    expect(repo.entries, hasLength(3));
  });

  test('a backdated fill reading past a later fill is rejected', () async {
    final repo = FakeRefuelRepository([
      entry(
        id: 1,
        odometer: 1000,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime.utc(2020, 1, 20),
      ),
    ]);
    final result = await logRefuel(repo).execute(
      entry(
        id: 0,
        odometer: 1200,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime.utc(2020, 1, 10),
      ),
    );

    expect(validationOf(result).field, 'odometer');
    expect(repo.entries, hasLength(1));
  });

  test('zero quantity is rejected', () async {
    final result = await logRefuel(
      FakeRefuelRepository(),
    ).execute(entry(id: 0, odometer: 1000, quantity: 0, pricePaid: 2000));

    expect(validationOf(result).field, 'quantity');
  });

  test('negative quantity is rejected', () async {
    final result = await logRefuel(
      FakeRefuelRepository(),
    ).execute(entry(id: 0, odometer: 1000, quantity: -5, pricePaid: 2000));

    expect(validationOf(result).field, 'quantity');
  });

  test('zero price is rejected', () async {
    final result = await logRefuel(
      FakeRefuelRepository(),
    ).execute(entry(id: 0, odometer: 1000, quantity: 20, pricePaid: 0));

    expect(validationOf(result).field, 'price');
  });

  test('negative price is rejected', () async {
    final result = await logRefuel(
      FakeRefuelRepository(),
    ).execute(entry(id: 0, odometer: 1000, quantity: 20, pricePaid: -100));

    expect(validationOf(result).field, 'price');
  });

  test('a fill dated in the future is rejected', () async {
    final result = await logRefuel(FakeRefuelRepository()).execute(
      entry(
        id: 0,
        odometer: 1000,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    expect(validationOf(result).field, 'filledAt');
  });

  test('notes containing a quote mark are rejected', () async {
    final result = await logRefuel(FakeRefuelRepository()).execute(
      entry(
        id: 0,
        odometer: 1000,
        quantity: 20,
        pricePaid: 2000,
      ).copyWith(notes: 'a "quoted" note'),
    );

    expect(validationOf(result).field, 'notes');
  });

  test('the override path allows a lower odometer', () async {
    final repo = FakeRefuelRepository([
      entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
    ]);
    final result = await logRefuel(repo).execute(
      entry(
        id: 0,
        odometer: 500,
        quantity: 20,
        pricePaid: 2000,
        odometerOverride: true,
      ),
    );

    expect(result.isRight(), isTrue);
    expect(repo.entries, hasLength(2));
  });

  test('a valid fill is stored and given an id', () async {
    final repo = FakeRefuelRepository();
    final result = await logRefuel(
      repo,
    ).execute(entry(id: 0, odometer: 1000, quantity: 20, pricePaid: 2000));

    final stored = result.getRight().toNullable()!;
    expect(stored.id, 1);
    expect(repo.entries, hasLength(1));
    expect(repo.entries.single.odometer, 1000);
  });

  test('a fill dated after a manual reading must read higher', () async {
    final now = DateTime.now();
    final repo = FakeRefuelRepository();
    final readings = FakeOdometerReadingRepository([
      OdometerReading(
        id: 1,
        vehicleId: 1,
        odometer: 1400,
        recordedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    final result = await logRefuel(repo, readings).execute(
      entry(
        id: 0,
        odometer: 1300,
        quantity: 20,
        pricePaid: 2000,
        filledAt: now,
      ),
    );

    expect(validationOf(result).field, 'odometer');
    expect(repo.entries, isEmpty);
  });

  test('a fill above the manual reading before it is stored', () async {
    final now = DateTime.now();
    final repo = FakeRefuelRepository();
    final readings = FakeOdometerReadingRepository([
      OdometerReading(
        id: 1,
        vehicleId: 1,
        odometer: 1400,
        recordedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    final result = await logRefuel(repo, readings).execute(
      entry(
        id: 0,
        odometer: 1500,
        quantity: 20,
        pricePaid: 2000,
        filledAt: now,
      ),
    );

    expect(result.isRight(), isTrue);
    expect(repo.entries, hasLength(1));
  });

  test('the override still lets a fill past a manual reading', () async {
    final now = DateTime.now();
    final repo = FakeRefuelRepository();
    final readings = FakeOdometerReadingRepository([
      OdometerReading(
        id: 1,
        vehicleId: 1,
        odometer: 1400,
        recordedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    final result = await logRefuel(repo, readings).execute(
      entry(
        id: 0,
        odometer: 900,
        quantity: 20,
        pricePaid: 2000,
        filledAt: now,
        odometerOverride: true,
      ),
    );

    expect(result.isRight(), isTrue);
  });
}
