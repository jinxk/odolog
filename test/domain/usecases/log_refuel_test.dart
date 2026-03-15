import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/usecases/log_refuel.dart';

import '../../helpers/entry_builder.dart';
import '../../helpers/fake_refuel_repository.dart';

void main() {
  ValidationFailure validationOf(Either<Failure, RefuelEntry> result) {
    return result.getLeft().toNullable()! as ValidationFailure;
  }

  test('odometer equal to the previous reading is rejected', () async {
    final repo = FakeRefuelRepository([
      entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
    ]);
    final result = await LogRefuel(
      repo,
    ).execute(entry(id: 0, odometer: 1000, quantity: 20, pricePaid: 2000));

    expect(validationOf(result).field, 'odometer');
    expect(repo.entries, hasLength(1));
  });

  test('odometer lower than the previous reading is rejected', () async {
    final repo = FakeRefuelRepository([
      entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
    ]);
    final result = await LogRefuel(
      repo,
    ).execute(entry(id: 0, odometer: 900, quantity: 20, pricePaid: 2000));

    expect(validationOf(result).field, 'odometer');
  });

  test('zero quantity is rejected', () async {
    final result = await LogRefuel(
      FakeRefuelRepository(),
    ).execute(entry(id: 0, odometer: 1000, quantity: 0, pricePaid: 2000));

    expect(validationOf(result).field, 'quantity');
  });

  test('negative quantity is rejected', () async {
    final result = await LogRefuel(
      FakeRefuelRepository(),
    ).execute(entry(id: 0, odometer: 1000, quantity: -5, pricePaid: 2000));

    expect(validationOf(result).field, 'quantity');
  });

  test('zero price is rejected', () async {
    final result = await LogRefuel(
      FakeRefuelRepository(),
    ).execute(entry(id: 0, odometer: 1000, quantity: 20, pricePaid: 0));

    expect(validationOf(result).field, 'price');
  });

  test('negative price is rejected', () async {
    final result = await LogRefuel(
      FakeRefuelRepository(),
    ).execute(entry(id: 0, odometer: 1000, quantity: 20, pricePaid: -100));

    expect(validationOf(result).field, 'price');
  });

  test('a fill dated in the future is rejected', () async {
    final result = await LogRefuel(FakeRefuelRepository()).execute(
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

  test('the override path allows a lower odometer', () async {
    final repo = FakeRefuelRepository([
      entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
    ]);
    final result = await LogRefuel(repo).execute(
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
    final result = await LogRefuel(
      repo,
    ).execute(entry(id: 0, odometer: 1000, quantity: 20, pricePaid: 2000));

    final stored = result.getRight().toNullable()!;
    expect(stored.id, 1);
    expect(repo.entries, hasLength(1));
    expect(repo.entries.single.odometer, 1000);
  });
}
