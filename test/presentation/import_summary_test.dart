import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/backup/data_bundle.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/presentation/settings/import_summary.dart';

DataBundle _bundleWithReadings(int count) => (
  vehicles: const [],
  entries: const [],
  serviceLog: const [],
  expenses: const [],
  odometerReadings: [
    for (var i = 0; i < count; i++)
      OdometerReading(
        id: i + 1,
        vehicleId: 1,
        odometer: 1000.0 + i,
        recordedAt: DateTime(2026, 1, 1 + i),
      ),
  ],
);

void main() {
  test('the summary always ends with the odometer readings', () {
    expect(
      importSummary(_bundleWithReadings(12)),
      'Imported 0 vehicles, 0 refuels, 0 services, 0 expenses, '
      'and 12 odometer readings.',
    );
  });

  test('one reading is singular', () {
    expect(
      importSummary(_bundleWithReadings(1)),
      'Imported 0 vehicles, 0 refuels, 0 services, 0 expenses, '
      'and 1 odometer reading.',
    );
  });

  test('no readings still names them', () {
    expect(
      importSummary(_bundleWithReadings(0)),
      'Imported 0 vehicles, 0 refuels, 0 services, 0 expenses, '
      'and 0 odometer readings.',
    );
  });
}
