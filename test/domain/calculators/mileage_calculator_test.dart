import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/calculators/mileage_calculator.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';

import '../../helpers/entry_builder.dart';

void main() {
  const calculator = MileageCalculator();

  // The three-fill example from docs/design.md. The documented numbers live
  // here so the code and the doc cannot drift apart.
  final workedExample = <RefuelEntry>[
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

  group('worked example from the design doc', () {
    test(
      'price per unit and distance match the documented per-entry values',
      () {
        final derived = calculator.perEntry(workedExample);

        expect(derived[0].pricePerUnit, 100.00);
        expect(derived[1].pricePerUnit, 100.60);
        expect(derived[2].pricePerUnit, 100.60);

        expect(derived[0].distanceSincePrevious, isNull);
        expect(derived[1].distanceSincePrevious, 250);
        expect(derived[2].distanceSincePrevious, 350);
      },
    );

    test(
      'the full-tank window spans the partial and excludes the opening fill',
      () {
        final windows = calculator.windows(workedExample);

        expect(windows, hasLength(1));
        final window = windows.single;
        expect(window.openingEntryId, 1);
        expect(window.closingEntryId, 3);
        expect(window.fuelConsumed, 40.0);
        expect(window.distance, 600);
        expect(window.mileage, 15.0);
        expect(window.costInWindow, 4024.0);
        expect(window.costPerKm, closeTo(6.70666, 0.0001));
      },
    );

    test('range figures use the last fill and the tank capacity', () {
      expect(calculator.lastFillRange(workedExample), 350);
      expect(calculator.projectedRange(workedExample, 35), 525.0);
      expect(
        calculator.latestWindow(workedExample),
        calculator.windows(workedExample).single,
      );
    });
  });

  test('a single entry has no distance, no window, and no range', () {
    final entries = [
      entry(id: 1, odometer: 5000, quantity: 20, pricePaid: 2000),
    ];

    final derived = calculator.perEntry(entries);
    expect(derived, hasLength(1));
    expect(derived.single.distanceSincePrevious, isNull);
    expect(calculator.windows(entries), isEmpty);
    expect(calculator.latestWindow(entries), isNull);
    expect(calculator.lastFillRange(entries), isNull);
    expect(calculator.projectedRange(entries, 40), isNull);
  });

  test('two full fills close one window on the second fill only', () {
    final entries = [
      entry(id: 1, odometer: 0, quantity: 40, pricePaid: 4000),
      entry(id: 2, odometer: 500, quantity: 25, pricePaid: 2600),
    ];

    final window = calculator.windows(entries).single;
    expect(window.openingEntryId, 1);
    expect(window.closingEntryId, 2);
    expect(window.fuelConsumed, 25.0);
    expect(window.distance, 500);
    expect(window.mileage, 20.0);
    expect(window.costInWindow, 2600.0);
  });

  test('a history of only partial fills produces no window', () {
    final entries = [
      entry(
        id: 1,
        odometer: 100,
        quantity: 10,
        pricePaid: 1000,
        fullTank: false,
      ),
      entry(
        id: 2,
        odometer: 350,
        quantity: 12,
        pricePaid: 1200,
        fullTank: false,
      ),
      entry(
        id: 3,
        odometer: 600,
        quantity: 11,
        pricePaid: 1100,
        fullTank: false,
      ),
    ];

    expect(calculator.windows(entries), isEmpty);
    expect(calculator.latestWindow(entries), isNull);
  });

  test(
    'three full fills produce two windows and latest is the most recent',
    () {
      final entries = [
        entry(id: 1, odometer: 0, quantity: 30, pricePaid: 3000),
        entry(id: 2, odometer: 300, quantity: 20, pricePaid: 2000),
        entry(id: 3, odometer: 700, quantity: 25, pricePaid: 2500),
      ];

      final windows = calculator.windows(entries);
      expect(windows, hasLength(2));

      expect(windows[0].openingEntryId, 1);
      expect(windows[0].closingEntryId, 2);
      expect(windows[0].distance, 300);
      expect(windows[0].fuelConsumed, 20.0);
      expect(windows[0].mileage, 15.0);

      expect(windows[1].openingEntryId, 2);
      expect(windows[1].closingEntryId, 3);
      expect(windows[1].distance, 400);
      expect(windows[1].fuelConsumed, 25.0);
      expect(windows[1].mileage, 16.0);

      expect(calculator.latestWindow(entries), windows[1]);
    },
  );

  test('entries before the first full fill belong to no window', () {
    final entries = [
      entry(id: 1, odometer: 100, quantity: 8, pricePaid: 800, fullTank: false),
      entry(id: 2, odometer: 200, quantity: 30, pricePaid: 3000),
      entry(id: 3, odometer: 500, quantity: 24, pricePaid: 2400),
    ];

    final window = calculator.windows(entries).single;
    expect(window.openingEntryId, 2);
    expect(window.closingEntryId, 3);
    // The leading partial's 8 litres are not part of the window's fuel.
    expect(window.fuelConsumed, 24.0);
    expect(window.distance, 300);
  });

  test(
    'an entry flagged with an odometer override still forms windows by odometer',
    () {
      final entries = [
        entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
        entry(
          id: 2,
          odometer: 1400,
          quantity: 25,
          pricePaid: 2500,
          odometerOverride: true,
        ),
        entry(id: 3, odometer: 1900, quantity: 30, pricePaid: 3000),
      ];

      final windows = calculator.windows(entries);
      expect(windows, hasLength(2));
      expect(windows[0].closingEntryId, 2);
      expect(windows[0].distance, 400);
      expect(windows[0].fuelConsumed, 25.0);
      expect(windows[1].openingEntryId, 2);
      expect(windows[1].distance, 500);
      expect(windows[1].fuelConsumed, 30.0);
    },
  );

  test(
    'an override that rewinds the odometer produces no degenerate window',
    () {
      final entries = [
        entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
        entry(
          id: 2,
          odometer: 800,
          quantity: 25,
          pricePaid: 2500,
          odometerOverride: true,
        ),
        entry(id: 3, odometer: 1300, quantity: 30, pricePaid: 3000),
      ];

      final windows = calculator.windows(entries);

      // The rewind from 1000 to 800 closes nothing. The next full fill opens a
      // window at the rewound fill and closes a sane one over positive distance.
      expect(windows, hasLength(1));
      final window = windows.single;
      expect(window.openingEntryId, 2);
      expect(window.closingEntryId, 3);
      expect(window.distance, 500);
      expect(window.fuelConsumed, 30.0);
      expect(window.mileage, closeTo(16.6666, 0.0001));
    },
  );

  test('the fuel of a skipped span rolls into the next window', () {
    final entries = [
      entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000),
      entry(
        id: 2,
        odometer: 1200,
        quantity: 10,
        pricePaid: 1000,
        fullTank: false,
      ),
      entry(
        id: 3,
        odometer: 900,
        quantity: 28,
        pricePaid: 2800,
        odometerOverride: true,
      ),
      entry(id: 4, odometer: 1400, quantity: 30, pricePaid: 3000),
    ];

    final windows = calculator.windows(entries);
    expect(windows, hasLength(1));
    final window = windows.single;
    // Opening is the rewound full fill (id 3); its own 28 litres do not count.
    // The partial's 10 litres from the skipped span carry into this window
    // alongside the closing fill's 30, for 40 litres over 500 km.
    expect(window.openingEntryId, 3);
    expect(window.closingEntryId, 4);
    expect(window.distance, 500);
    expect(window.fuelConsumed, 40.0);
    expect(window.costInWindow, 4000.0);
    expect(window.mileage, 12.5);
  });

  test('CNG runs the same math with kg in place of litres', () {
    final entries = [
      entry(id: 1, odometer: 0, quantity: 5, pricePaid: 400),
      entry(id: 2, odometer: 300, quantity: 6, pricePaid: 480),
    ];

    final window = calculator.windows(entries).single;
    expect(window.fuelConsumed, 6.0);
    expect(window.distance, 300);
    expect(window.mileage, 50.0);
  });
}
