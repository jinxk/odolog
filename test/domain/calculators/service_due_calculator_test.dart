import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/calculators/service_due_calculator.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';

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
  const calculator = ServiceDueCalculator();
  // A fixed "now" keeps the arithmetic readable; every date below is derived
  // from it rather than hardcoded, so the test does not rot.
  final now = DateTime(2026, 1, 1);

  group('statusFor', () {
    test('a distance-only template reports remaining km and no days', () {
      final status = calculator.statusFor(
        template: ServiceTemplate.engineOil,
        kmInterval: 3000,
        baselineOdometer: 10000,
        latestOdometer: 11000,
        now: now,
      );

      expect(status.remainingKm, 2000);
      expect(status.remainingDays, isNull);
      expect(status.overdue, isFalse);
    });

    test(
      'a distance-only template goes overdue once the interval is used up',
      () {
        final status = calculator.statusFor(
          template: ServiceTemplate.engineOil,
          kmInterval: 3000,
          baselineOdometer: 10000,
          latestOdometer: 13500,
          now: now,
        );

        expect(status.remainingKm, -500);
        expect(status.overdue, isTrue);
      },
    );

    test('a date-only template reports remaining days and no km', () {
      final status = calculator.statusFor(
        template: ServiceTemplate.generalService,
        dayInterval: 180,
        baselineDate: now.subtract(const Duration(days: 30)),
        now: now,
      );

      expect(status.remainingDays, 150);
      expect(status.remainingKm, isNull);
      expect(status.overdue, isFalse);
      expect(status.projectedDueDate, now.add(const Duration(days: 150)));
    });

    test('a date-only template goes overdue past its due date', () {
      final status = calculator.statusFor(
        template: ServiceTemplate.generalService,
        dayInterval: 180,
        baselineDate: now.subtract(const Duration(days: 200)),
        now: now,
      );

      expect(status.remainingDays, -20);
      expect(status.overdue, isTrue);
    });

    test(
      'whichever dimension is closer wins the overdue call when both apply',
      () {
        // The date side has 150 days left; the km side, projected at 50 km a
        // day, has only 10 days left. The km side must be the one that flips
        // this to overdue and sets the projected date.
        final status = calculator.statusFor(
          template: ServiceTemplate.engineOil,
          kmInterval: 3000,
          dayInterval: 180,
          baselineOdometer: 10000,
          baselineDate: now.subtract(const Duration(days: 30)),
          latestOdometer: 12500,
          averageDailyDistance: 50,
          now: now,
        );

        expect(status.remainingKm, 500);
        expect(status.remainingDays, 150);
        expect(status.overdue, isFalse);
        // 500 km left at 50 km a day is 10 days out, well before the 150 day
        // mark the date side reports.
        expect(status.projectedDueDate, now.add(const Duration(days: 10)));
      },
    );

    test('the km dimension marks overdue even while the date side is not', () {
      final status = calculator.statusFor(
        template: ServiceTemplate.engineOil,
        kmInterval: 3000,
        dayInterval: 180,
        baselineOdometer: 10000,
        baselineDate: now.subtract(const Duration(days: 30)),
        latestOdometer: 13200,
        averageDailyDistance: 50,
        now: now,
      );

      expect(status.remainingKm, -200);
      expect(status.remainingDays, 150);
      expect(status.overdue, isTrue);
    });

    test(
      'a distance dimension with no refuel history yields no projected date',
      () {
        final status = calculator.statusFor(
          template: ServiceTemplate.engineOil,
          kmInterval: 3000,
          baselineOdometer: 10000,
          latestOdometer: 11000,
          now: now,
        );

        expect(status.remainingKm, 2000);
        expect(status.projectedDueDate, isNull);
      },
    );

    test('neither dimension set yields an empty status', () {
      final status = calculator.statusFor(
        template: ServiceTemplate.generalService,
        now: now,
      );

      expect(status.remainingKm, isNull);
      expect(status.remainingDays, isNull);
      expect(status.projectedDueDate, isNull);
      expect(status.overdue, isFalse);
    });
  });

  group('lastLogFor', () {
    test('returns the most recent entry for the template only', () {
      final log = [
        ServiceLogEntry(
          id: 1,
          vehicleId: 1,
          template: ServiceTemplate.engineOil,
          performedAt: now.subtract(const Duration(days: 60)),
          odometer: 9000,
        ),
        ServiceLogEntry(
          id: 2,
          vehicleId: 1,
          template: ServiceTemplate.generalService,
          performedAt: now.subtract(const Duration(days: 10)),
          odometer: 9800,
        ),
        ServiceLogEntry(
          id: 3,
          vehicleId: 1,
          template: ServiceTemplate.engineOil,
          performedAt: now.subtract(const Duration(days: 20)),
          odometer: 9600,
        ),
      ];

      final latest = ServiceDueCalculator.lastLogFor(
        log,
        ServiceTemplate.engineOil,
      );
      expect(latest!.id, 3);
    });

    test('returns null when the template has never been logged', () {
      expect(
        ServiceDueCalculator.lastLogFor([], ServiceTemplate.engineOil),
        isNull,
      );
    });
  });

  group('averageDailyDistance', () {
    test('divides total distance by total days across the full history', () {
      final refuels = [
        _refuel(
          odometer: 10000,
          filledAt: now.subtract(const Duration(days: 100)),
        ),
        _refuel(odometer: 15000, filledAt: now),
      ];

      expect(ServiceDueCalculator.averageDailyDistance(refuels), 50);
    });

    test('is null with fewer than two fills', () {
      final refuels = [_refuel(odometer: 10000, filledAt: now)];
      expect(ServiceDueCalculator.averageDailyDistance(refuels), isNull);
    });

    test('is null when the span is the same day', () {
      final refuels = [
        _refuel(odometer: 10000, filledAt: now),
        _refuel(odometer: 10050, filledAt: now.add(const Duration(hours: 2))),
      ];
      expect(ServiceDueCalculator.averageDailyDistance(refuels), isNull);
    });
  });
}
