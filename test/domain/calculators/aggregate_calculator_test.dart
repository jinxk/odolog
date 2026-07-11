import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/calculators/aggregate_calculator.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';

import '../../helpers/entry_builder.dart';

void main() {
  const calculator = AggregateCalculator();

  test(
    'lifetime totals sum spend and quantity and span the whole odometer range',
    () {
      final entries = <RefuelEntry>[
        entry(id: 1, odometer: 10000, quantity: 30, pricePaid: 3000),
        entry(
          id: 2,
          odometer: 10250,
          quantity: 15,
          pricePaid: 1509,
          fullTank: false,
        ),
        entry(id: 3, odometer: 10600, quantity: 25, pricePaid: 2515),
      ];

      final stats = calculator.lifetime(entries, tankCapacity: 35);

      expect(stats.totalSpend, 7024.0);
      expect(stats.totalQuantity, 70.0);
      expect(stats.totalDistance, 600);
      expect(stats.averageMileage, 15.0);
      expect(stats.averageCostPerKm, closeTo(6.70666, 0.0001));
      expect(stats.lastFillRange, 350);
      expect(stats.projectedRange, 525.0);
    },
  );

  test('entries group by calendar month across a month boundary', () {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 15);
    final lastMonth = DateTime(now.year, now.month - 1, 15);

    final entries = <RefuelEntry>[
      entry(
        id: 1,
        odometer: 1000,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime(lastMonth.year, lastMonth.month, 10),
      ),
      entry(
        id: 2,
        odometer: 1300,
        quantity: 25,
        pricePaid: 2500,
        filledAt: DateTime(lastMonth.year, lastMonth.month, 20),
      ),
      entry(
        id: 3,
        odometer: 1700,
        quantity: 30,
        pricePaid: 3000,
        filledAt: DateTime(thisMonth.year, thisMonth.month, 5),
      ),
      entry(
        id: 4,
        odometer: 2000,
        quantity: 28,
        pricePaid: 2800,
        filledAt: DateTime(thisMonth.year, thisMonth.month, 15),
      ),
    ];

    final months = calculator.monthly(entries);
    final lastKey = DateTime(lastMonth.year, lastMonth.month);
    final thisKey = DateTime(thisMonth.year, thisMonth.month);

    expect(months.keys, [lastKey, thisKey]);
    expect(months[lastKey]!.totalSpend, 4500.0);
    expect(months[thisKey]!.totalSpend, 5800.0);
  });

  test('distance into a month first fill is counted in that month', () {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 15);
    final lastMonth = DateTime(now.year, now.month - 1, 15);

    final entries = <RefuelEntry>[
      entry(
        id: 1,
        odometer: 1000,
        quantity: 20,
        pricePaid: 2000,
        filledAt: DateTime(lastMonth.year, lastMonth.month, 10),
      ),
      entry(
        id: 2,
        odometer: 1300,
        quantity: 25,
        pricePaid: 2500,
        filledAt: DateTime(lastMonth.year, lastMonth.month, 20),
      ),
      entry(
        id: 3,
        odometer: 1700,
        quantity: 30,
        pricePaid: 3000,
        filledAt: DateTime(thisMonth.year, thisMonth.month, 5),
      ),
      entry(
        id: 4,
        odometer: 2000,
        quantity: 28,
        pricePaid: 2800,
        filledAt: DateTime(thisMonth.year, thisMonth.month, 15),
      ),
    ];

    final months = calculator.monthly(entries);
    final lastKey = DateTime(lastMonth.year, lastMonth.month);
    final thisKey = DateTime(thisMonth.year, thisMonth.month);

    // Last month has no earlier entry, so it measures from its own first fill.
    expect(months[lastKey]!.totalDistance, 300);
    // This month measures from the last fill of the previous month, so the
    // 400 km driven into its first fill counts here: 2000 - 1300.
    expect(months[thisKey]!.totalDistance, 700);
  });

  test(
    'average mileage is distance weighted, not a mean of the window numbers',
    () {
      final entries = <RefuelEntry>[
        entry(id: 1, odometer: 0, quantity: 10, pricePaid: 1000),
        entry(id: 2, odometer: 200, quantity: 10, pricePaid: 1000),
        entry(id: 3, odometer: 800, quantity: 40, pricePaid: 4000),
      ];

      // Window one: 200 km on 10 litres = 20 km/l.
      // Window two: 600 km on 40 litres = 15 km/l.
      // A naive mean would give 17.5; the distance-weighted figure is 800 / 50.
      final stats = calculator.lifetime(entries);

      expect(stats.averageMileage, 16.0);
      expect(stats.averageMileage, isNot(17.5));
    },
  );
}
