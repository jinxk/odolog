import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/validators/odometer_sequence_validator.dart';

import '../../helpers/entry_builder.dart';

void main() {
  final now = DateTime.now();
  final lastMonth = now.subtract(const Duration(days: 30));
  final lastWeek = now.subtract(const Duration(days: 7));

  test('points cover both fills and readings', () {
    final points = OdometerSequenceValidator.pointsOf(
      [
        entry(
          id: 1,
          odometer: 1000,
          quantity: 20,
          pricePaid: 2000,
          filledAt: lastMonth,
        ),
      ],
      [
        OdometerReading(
          id: 1,
          vehicleId: 1,
          odometer: 1400,
          recordedAt: lastWeek,
        ),
      ],
    );

    expect(points, [
      (at: lastMonth, odometer: 1000.0),
      (at: lastWeek, odometer: 1400.0),
    ]);
  });

  test('a fill dated after a reading needs a higher odometer', () {
    final issue = OdometerSequenceValidator.check(
      OdometerSequenceValidator.refuelPoint(
        entry(
          id: 0,
          odometer: 1300,
          quantity: 20,
          pricePaid: 2000,
          filledAt: now,
        ),
      ),
      OdometerSequenceValidator.pointsOf(const [], [
        OdometerReading(
          id: 1,
          vehicleId: 1,
          odometer: 1400,
          recordedAt: lastWeek,
        ),
      ]),
    );

    expect(issue, isNotNull);
    expect(issue!.field, 'odometer');
    expect(issue.reason, 'Odometer must be greater than the previous reading.');
  });

  test('a fill above the reading before it passes', () {
    final issue = OdometerSequenceValidator.check(
      OdometerSequenceValidator.refuelPoint(
        entry(
          id: 0,
          odometer: 1500,
          quantity: 20,
          pricePaid: 2000,
          filledAt: now,
        ),
      ),
      OdometerSequenceValidator.pointsOf(const [], [
        OdometerReading(
          id: 1,
          vehicleId: 1,
          odometer: 1400,
          recordedAt: lastWeek,
        ),
      ]),
    );

    expect(issue, isNull);
  });

  test('a reading dated after a fill must sit above it', () {
    final fill = entry(
      id: 1,
      odometer: 1000,
      quantity: 20,
      pricePaid: 2000,
      filledAt: lastWeek,
    );

    final issue = OdometerSequenceValidator.check(
      OdometerSequenceValidator.readingPoint(
        OdometerReading(id: 0, vehicleId: 1, odometer: 900, recordedAt: now),
      ),
      OdometerSequenceValidator.pointsOf([fill], const []),
    );

    expect(issue, isNotNull);
    expect(issue!.field, 'odometer');
  });

  test('a same moment record still needs a higher reading', () {
    final issue = OdometerSequenceValidator.check(
      OdometerSequenceValidator.readingPoint(
        OdometerReading(id: 0, vehicleId: 1, odometer: 1000, recordedAt: now),
      ),
      OdometerSequenceValidator.pointsOf([
        entry(
          id: 1,
          odometer: 1000,
          quantity: 20,
          pricePaid: 2000,
          filledAt: now,
        ),
      ], const []),
    );

    expect(issue, isNotNull);
  });

  test('nothing to compare against passes', () {
    final issue = OdometerSequenceValidator.check(
      OdometerSequenceValidator.readingPoint(
        OdometerReading(id: 0, vehicleId: 1, odometer: 1000, recordedAt: now),
      ),
      const [],
    );

    expect(issue, isNull);
  });
}
