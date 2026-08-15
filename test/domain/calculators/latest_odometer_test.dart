import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/calculators/latest_odometer.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';

import '../../helpers/entry_builder.dart';

void main() {
  final now = DateTime.now();
  final lastMonth = now.subtract(const Duration(days: 30));
  final lastWeek = now.subtract(const Duration(days: 7));

  test('no fills and no readings gives null', () {
    expect(LatestOdometerCalculator.of(const [], const []), isNull);
  });

  test('the last fill wins when there are no readings', () {
    final latest = LatestOdometerCalculator.of([
      entry(
        id: 1,
        odometer: 10000,
        quantity: 30,
        pricePaid: 3000,
        filledAt: lastMonth,
      ),
      entry(
        id: 2,
        odometer: 10600,
        quantity: 25,
        pricePaid: 2500,
        filledAt: lastWeek,
      ),
    ], const []);

    expect(latest!.odometer, 10600);
    expect(latest.at, lastWeek);
  });

  test('a reading beyond the last fill wins', () {
    final latest = LatestOdometerCalculator.of(
      [
        entry(
          id: 1,
          odometer: 10600,
          quantity: 25,
          pricePaid: 2500,
          filledAt: lastWeek,
        ),
      ],
      [OdometerReading(id: 1, vehicleId: 1, odometer: 11200, recordedAt: now)],
    );

    expect(latest!.odometer, 11200);
    expect(latest.at, now);
  });

  test('a reading behind the last fill does not win', () {
    final latest = LatestOdometerCalculator.of(
      [
        entry(
          id: 1,
          odometer: 10600,
          quantity: 25,
          pricePaid: 2500,
          filledAt: lastWeek,
        ),
      ],
      [
        OdometerReading(
          id: 1,
          vehicleId: 1,
          odometer: 10100,
          recordedAt: lastMonth,
        ),
      ],
    );

    expect(latest!.odometer, 10600);
  });

  test('readings alone give the highest one', () {
    final latest = LatestOdometerCalculator.of(const [], [
      OdometerReading(
        id: 1,
        vehicleId: 1,
        odometer: 500,
        recordedAt: lastMonth,
      ),
      OdometerReading(id: 2, vehicleId: 1, odometer: 900, recordedAt: now),
    ]);

    expect(latest!.odometer, 900);
    expect(latest.at, now);
  });
}
