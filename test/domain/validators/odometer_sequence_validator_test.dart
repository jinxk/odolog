import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/validators/odometer_sequence_validator.dart';

import '../../helpers/entry_builder.dart';

void main() {
  final now = DateTime.now();

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
