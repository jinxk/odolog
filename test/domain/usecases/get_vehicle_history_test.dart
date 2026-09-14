import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/calculators/mileage_calculator.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/usecases/get_vehicle_history.dart';

import '../../helpers/entry_builder.dart';
import '../../helpers/fake_refuel_repository.dart';

void main() {
  final now = DateTime.now();

  // The meter rolled over after fill 2, so fill 3 is saved with the override at
  // a lower reading than the first fill of its run.
  List<RefuelEntry> afterRollover({
    double quantityTwo = 25,
    double pricePaidTwo = 2500,
    double quantityFour = 20,
    double pricePaidFour = 2000,
  }) => [
    entry(
      id: 1,
      odometer: 99000,
      quantity: 25,
      pricePaid: 2500,
      filledAt: now.subtract(const Duration(days: 30)),
    ),
    entry(
      id: 2,
      odometer: 99400,
      quantity: quantityTwo,
      pricePaid: pricePaidTwo,
      filledAt: now.subtract(const Duration(days: 20)),
    ),
    entry(
      id: 3,
      odometer: 100,
      quantity: 25,
      pricePaid: 2500,
      odometerOverride: true,
      filledAt: now.subtract(const Duration(days: 10)),
    ),
    entry(
      id: 4,
      odometer: 450,
      quantity: quantityFour,
      pricePaid: pricePaidFour,
      filledAt: now.subtract(const Duration(days: 2)),
    ),
  ];

  test(
    'after a rollover the last item is the fill logged most recently',
    () async {
      final history = GetVehicleHistory(FakeRefuelRepository(afterRollover()));

      final items = (await history.execute(1)).getRight().toNullable()!;

      expect(items.map((i) => i.entry.id), [1, 2, 3, 4]);
      expect(items.last.entry.id, 4);
      expect(items[2].derived.distanceSincePrevious, isNull);
      expect(items[3].derived.distanceSincePrevious, 350);
    },
  );

  test(
    'after a rollover the last price is the price per unit of the latest fill',
    () async {
      final history = GetVehicleHistory(
        FakeRefuelRepository(
          afterRollover(
            quantityTwo: 25,
            pricePaidTwo: 2600,
            quantityFour: 20,
            pricePaidFour: 2100,
          ),
        ),
      );

      final items = (await history.execute(1)).getRight().toNullable()!;

      expect(
        const MileageCalculator().lastKnownPricePerUnit([
          for (final item in items) item.entry,
        ]),
        105.0,
      );
    },
  );
}
