import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/calculators/document_reminder_planner.dart';
import 'package:odolog/domain/entities/vehicle.dart';

void main() {
  const planner = DocumentReminderPlanner();
  // A fixed "now" keeps the arithmetic readable; every date below is derived
  // from it rather than hardcoded, so the test does not rot.
  final now = DateTime(2026, 1, 1, 8);

  Vehicle vehicleWith({
    DateTime? insurance,
    DateTime? puc,
    DateTime? rc,
    DateTime? fitness,
  }) => Vehicle(
    id: 1,
    name: 'Swift',
    type: VehicleType.car,
    fuelCategory: FuelCategory.petrol,
    insuranceExpiry: insurance,
    pucExpiry: puc,
    rcExpiry: rc,
    fitnessExpiry: fitness,
  );

  group('plan', () {
    test('a vehicle with no dates produces no reminders', () {
      expect(planner.plan([vehicleWith()], now: now), isEmpty);
    });

    test('one date yields the four lead times, all in the future', () {
      final expiry = now.add(const Duration(days: 60));
      final reminders = planner.plan([
        vehicleWith(insurance: expiry),
      ], now: now);

      expect(reminders.map((r) => r.daysBefore).toSet(), {30, 15, 7, 1});
      expect(
        reminders.every((r) => r.document == VehicleDocument.insurance),
        isTrue,
      );
      expect(reminders.every((r) => r.fireAt.isAfter(now)), isTrue);
      // The 30-day reminder fires at 09:00 local, 30 days before expiry.
      final thirty = reminders.firstWhere((r) => r.daysBefore == 30);
      expect(
        thirty.fireAt,
        DateTime(expiry.year, expiry.month, expiry.day - 30, 9),
      );
    });

    test('lead times whose fire moment has passed are dropped', () {
      // Expiry is only 10 days out, so the 30 and 15 day reminders are already
      // in the past and must not be scheduled; 7 and 1 remain.
      final expiry = now.add(const Duration(days: 10));
      final reminders = planner.plan([vehicleWith(puc: expiry)], now: now);

      expect(reminders.map((r) => r.daysBefore).toSet(), {7, 1});
    });

    test('every set document contributes its own reminders', () {
      final soon = now.add(const Duration(days: 40));
      final reminders = planner.plan([
        vehicleWith(insurance: soon, rc: soon),
      ], now: now);

      expect(reminders.map((r) => r.document).toSet(), {
        VehicleDocument.insurance,
        VehicleDocument.rc,
      });
      expect(reminders, hasLength(8));
    });
  });

  group('nearestAlert', () {
    test('nothing within the window returns null', () {
      final far = now.add(const Duration(days: 90));
      expect(
        planner.nearestAlert(vehicleWith(insurance: far), now: now),
        isNull,
      );
    });

    test('the soonest upcoming document wins and is not overdue', () {
      final alert = planner.nearestAlert(
        vehicleWith(
          insurance: now.add(const Duration(days: 25)),
          puc: now.add(const Duration(days: 5)),
        ),
        now: now,
      )!;

      expect(alert.document, VehicleDocument.puc);
      expect(alert.daysRemaining, 5);
      expect(alert.overdue, isFalse);
    });

    test('an overdue document outranks an upcoming one', () {
      final alert = planner.nearestAlert(
        vehicleWith(
          insurance: now.add(const Duration(days: 3)),
          puc: now.subtract(const Duration(days: 2)),
        ),
        now: now,
      )!;

      expect(alert.document, VehicleDocument.puc);
      expect(alert.daysRemaining, -2);
      expect(alert.overdue, isTrue);
    });
  });
}
