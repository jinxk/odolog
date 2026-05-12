import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/calculators/service_due_calculator.dart';
import 'package:odolog/domain/calculators/service_reminder_planner.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';

RefuelEntry _refuel({required double odometer, required DateTime filledAt}) {
  return RefuelEntry(
    id: 1,
    vehicleId: 1,
    filledAt: filledAt,
    odometer: odometer,
    quantity: 1,
    pricePaid: 1,
  );
}

void main() {
  const planner = ServiceReminderPlanner();
  final now = DateTime(2026, 1, 1, 8);

  const vehicle = Vehicle(
    id: 1,
    name: 'Swift',
    type: VehicleType.car,
    fuelCategory: FuelCategory.petrol,
    generalServiceIntervalDays: 30,
  );

  test('a date-due template with a future due date produces one reminder', () {
    final refuels = [
      _refuel(
        odometer: 10000,
        filledAt: now.subtract(const Duration(days: 10)),
      ),
    ];

    final reminders = planner.plan(
      [vehicle],
      refuelsByVehicle: {1: refuels},
      serviceLogByVehicle: {},
      now: now,
    );

    expect(reminders, hasLength(1));
    expect(reminders.single.template, ServiceTemplate.generalService);
    expect(reminders.single.fireAt.isAfter(now), isTrue);
  });

  test('a vehicle with no refuel history produces no reminders', () {
    final reminders = planner.plan(
      [vehicle],
      refuelsByVehicle: {},
      serviceLogByVehicle: {},
      now: now,
    );

    expect(reminders, isEmpty);
  });

  test(
    'logging a service resets its countdown and pushes the reminder out',
    () {
      final refuels = [
        _refuel(
          odometer: 10000,
          filledAt: now.subtract(const Duration(days: 40)),
        ),
      ];
      final serviceLog = [
        ServiceLogEntry(
          id: 1,
          vehicleId: 1,
          template: ServiceTemplate.generalService,
          performedAt: now.subtract(const Duration(days: 5)),
          odometer: 10200,
        ),
      ];

      final withoutLog = planner.plan(
        [vehicle],
        refuelsByVehicle: {1: refuels},
        serviceLogByVehicle: {},
        now: now,
      );
      final withLog = planner.plan(
        [vehicle],
        refuelsByVehicle: {1: refuels},
        serviceLogByVehicle: {1: serviceLog},
        now: now,
      );

      // Without a log the 30 day interval against a 40 day old fill is already
      // overdue, so it fires immediately (not in the future) and contributes no
      // reminder; logging the service resets the baseline to 5 days ago, which
      // is still within the interval and yields a future reminder.
      expect(withoutLog, isEmpty);
      expect(withLog, hasLength(1));
    },
  );

  test('a distance-only template projects a date from the recent pace', () {
    const oilVehicle = Vehicle(
      id: 1,
      name: 'Swift',
      type: VehicleType.car,
      fuelCategory: FuelCategory.petrol,
      engineOilIntervalKm: 3000,
    );
    final refuels = [
      _refuel(
        odometer: 10000,
        filledAt: now.subtract(const Duration(days: 100)),
      ),
      _refuel(odometer: 11000, filledAt: now),
    ];

    final reminders = planner.plan(
      [oilVehicle],
      refuelsByVehicle: {1: refuels},
      serviceLogByVehicle: {},
      now: now,
    );

    // The general service dimension has no interval of its own set here,
    // so it falls back to the default and also contributes a reminder;
    // only the engine oil one is asserted on.
    final oilReminder = reminders.firstWhere(
      (r) => r.template == ServiceTemplate.engineOil,
    );
    // 3000 km interval from a 10000 baseline, 11000 latest: 2000 km left at
    // 10 km a day (1000 km over 100 days) projects 200 days out.
    final expected = DateTime(
      now.year,
      now.month,
      now.day + 200,
      ServiceDueCalculator.fireHour,
    );
    expect(oilReminder.fireAt, expected);
  });
}
