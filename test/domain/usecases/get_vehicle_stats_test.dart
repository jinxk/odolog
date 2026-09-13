import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/get_vehicle_stats.dart';

import '../../helpers/entry_builder.dart';
import '../../helpers/fake_expense_repository.dart';
import '../../helpers/fake_odometer_reading_repository.dart';
import '../../helpers/fake_refuel_repository.dart';
import '../../helpers/fake_service_log_repository.dart';
import '../../helpers/fake_vehicle_repository.dart';

void main() {
  test(
    'lifetime distance adds the distance on each side of a rollover',
    () async {
      final now = DateTime.now();
      DateTime daysAgo(int days) => now.subtract(Duration(days: days));

      const vehicle = Vehicle(
        id: 1,
        name: 'Swift',
        type: VehicleType.car,
        fuelCategory: FuelCategory.petrol,
      );
      final stats = GetVehicleStats(
        FakeVehicleRepository([vehicle]),
        FakeRefuelRepository([
          entry(
            id: 1,
            odometer: 99000,
            quantity: 25,
            pricePaid: 2500,
            filledAt: daysAgo(40),
          ),
          entry(
            id: 2,
            odometer: 99400,
            quantity: 25,
            pricePaid: 2500,
            filledAt: daysAgo(30),
          ),
          entry(
            id: 3,
            odometer: 100,
            quantity: 25,
            pricePaid: 2500,
            odometerOverride: true,
            filledAt: daysAgo(20),
          ),
          entry(
            id: 4,
            odometer: 600,
            quantity: 25,
            pricePaid: 2500,
            filledAt: daysAgo(5),
          ),
        ]),
        FakeExpenseRepository(),
        FakeServiceLogRepository(),
        FakeOdometerReadingRepository([
          OdometerReading(
            id: 1,
            vehicleId: 1,
            odometer: 99500,
            recordedAt: daysAgo(25),
          ),
          OdometerReading(
            id: 2,
            vehicleId: 1,
            odometer: 700,
            recordedAt: daysAgo(2),
          ),
        ]),
      );

      final result = (await stats.execute(1)).getRight().toNullable()!;

      expect(result.totalDistance, 1100);
    },
  );
}
