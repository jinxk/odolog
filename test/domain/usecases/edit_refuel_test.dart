import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/usecases/edit_refuel.dart';

import '../../helpers/entry_builder.dart';
import '../../helpers/fake_refuel_repository.dart';

void main() {
  ValidationFailure validationOf(Either<Failure, RefuelEntry> result) {
    return result.getLeft().toNullable()! as ValidationFailure;
  }

  List<RefuelEntry> threeFills() => [
    entry(
      id: 1,
      odometer: 1000,
      quantity: 20,
      pricePaid: 2000,
      filledAt: DateTime.utc(2020, 1, 1),
    ),
    entry(
      id: 2,
      odometer: 1500,
      quantity: 20,
      pricePaid: 2000,
      filledAt: DateTime.utc(2020, 1, 10),
    ),
    entry(
      id: 3,
      odometer: 2000,
      quantity: 20,
      pricePaid: 2000,
      filledAt: DateTime.utc(2020, 1, 20),
    ),
  ];

  test(
    'an edit that keeps the odometer between its neighbours is stored',
    () async {
      final repo = FakeRefuelRepository(threeFills());
      final result = await EditRefuel(repo).execute(
        entry(
          id: 2,
          odometer: 1600,
          quantity: 20,
          pricePaid: 2000,
          filledAt: DateTime.utc(2020, 1, 10),
        ),
      );

      expect(result.isRight(), isTrue);
      expect(repo.entries.firstWhere((e) => e.id == 2).odometer, 1600);
    },
  );

  test('an edit below the earlier neighbour is rejected', () async {
    final repo = FakeRefuelRepository(threeFills());
    final result = await EditRefuel(repo).execute(
      entry(
        id: 2,
        odometer: 900,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime.utc(2020, 1, 10),
      ),
    );

    expect(validationOf(result).field, 'odometer');
    expect(repo.entries.firstWhere((e) => e.id == 2).odometer, 1500);
  });

  test('an edit past the later neighbour is rejected', () async {
    final repo = FakeRefuelRepository(threeFills());
    final result = await EditRefuel(repo).execute(
      entry(
        id: 2,
        odometer: 2500,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime.utc(2020, 1, 10),
      ),
    );

    expect(validationOf(result).field, 'odometer');
    expect(repo.entries.firstWhere((e) => e.id == 2).odometer, 1500);
  });

  test('editing an unknown entry reports not found', () async {
    final repo = FakeRefuelRepository(threeFills());
    final result = await EditRefuel(repo).execute(
      entry(
        id: 9,
        odometer: 1600,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime.utc(2020, 1, 10),
      ),
    );

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });
}
