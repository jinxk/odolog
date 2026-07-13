import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/data/csv/data_bundle_csv_codec.dart';
import 'package:odolog/data/json/data_bundle_json_codec.dart';
import 'package:odolog/domain/backup/data_bundle.dart';
import 'package:odolog/domain/entities/expense.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';

ValidationFailure failureOf(Result<DataBundle> result) {
  return result.getLeft().toNullable()! as ValidationFailure;
}

/// A bundle literal with only the fields a given test cares about; the rest
/// default to empty so most tests do not have to spell out all four sections.
DataBundle bundle({
  List<Vehicle> vehicles = const [],
  List<RefuelEntry> entries = const [],
  List<ServiceLogEntry> serviceLog = const [],
  List<Expense> expenses = const [],
}) => (
  vehicles: vehicles,
  entries: entries,
  serviceLog: serviceLog,
  expenses: expenses,
);

void main() {
  const codec = DataBundleJsonCodec();

  group('round trip', () {
    test('all four sections survive a full write and read cycle', () {
      final data = bundle(
        vehicles: [
          Vehicle(
            id: 1,
            name: 'Activa',
            type: VehicleType.scooter,
            fuelCategory: FuelCategory.petrol,
            registrationNo: 'MH12AB1234',
            tankCapacity: 5.3,
            claimedMileage: 60,
            insuranceExpiry: DateTime(2026, 8, 15),
            pucExpiry: DateTime(2026, 4, 1),
            engineOilIntervalKm: 3000,
            generalServiceIntervalDays: 180,
          ),
          const Vehicle(
            id: 2,
            name: 'Swift, "the hatchback"',
            type: VehicleType.car,
            fuelCategory: FuelCategory.diesel,
          ),
        ],
        entries: [
          RefuelEntry(
            id: 1,
            vehicleId: 1,
            filledAt: DateTime(2026, 1, 15, 9, 30),
            odometer: 12500,
            quantity: 4.2,
            pricePaid: 420,
            fullTank: true,
            variantId: 'iocl_xp100',
            stationName: 'Highway Fuels, near the mall',
            notes: 'Topped up before a trip',
          ),
          RefuelEntry(
            id: 2,
            vehicleId: 2,
            filledAt: DateTime(2026, 2, 1, 18, 0),
            odometer: 20000,
            quantity: 30,
            pricePaid: 3000,
            fullTank: false,
            odometerOverride: true,
          ),
        ],
        serviceLog: [
          ServiceLogEntry(
            id: 1,
            vehicleId: 1,
            template: ServiceTemplate.engineOil,
            performedAt: DateTime(2026, 1, 10),
            odometer: 12000,
            cost: 450,
            note: 'Full synthetic',
          ),
        ],
        expenses: [
          Expense(
            id: 1,
            vehicleId: 1,
            amount: 800,
            date: DateTime(2026, 1, 20),
            odometer: 12550,
            category: 'Tyre',
          ),
        ],
      );

      final encoded = codec.encode(data);
      final read = codec.decode(encoded).getRight().toNullable()!;

      expect(read.vehicles, data.vehicles);
      expect(read.entries, data.entries);
      expect(read.serviceLog, data.serviceLog);
      expect(read.expenses, data.expenses);
    });

    test('optional fields round trip as null', () {
      final entry = RefuelEntry(
        id: 1,
        vehicleId: 1,
        filledAt: DateTime(2026, 1, 1),
        odometer: 100,
        quantity: 2,
        pricePaid: 200,
      );

      final encoded = codec.encode(bundle(entries: [entry]));
      final read = codec.decode(encoded).getRight().toNullable()!;

      expect(read.entries.single, entry);
      expect(read.entries.single.variantId, isNull);
      expect(read.entries.single.stationName, isNull);
    });
  });

  group('template', () {
    test('decodes back into one example item per section', () {
      final read = codec.decode(codec.template()).getRight().toNullable()!;

      expect(read.vehicles, hasLength(1));
      expect(read.entries, hasLength(1));
      expect(read.serviceLog, hasLength(1));
      expect(read.expenses, hasLength(1));
    });

    test('is pretty printed for hand editing', () {
      expect(codec.template(), contains('\n  '));
    });
  });

  group('hand edited files', () {
    test('a missing id asks the database to assign one', () {
      final document =
          json.decode(codec.encode(bundle(vehicles: [_vehicle()])))
              as Map<String, Object?>;
      final vehicles = document['vehicles'] as List;
      (vehicles.single as Map<String, Object?>).remove('id');

      final read = codec.decode(json.encode(document)).getRight().toNullable()!;

      expect(read.vehicles.single.id, 0);
    });

    test('a whole number written with a decimal point still reads', () {
      final document =
          json.decode(codec.encode(bundle(vehicles: [_vehicle()])))
              as Map<String, Object?>;
      final vehicles = document['vehicles'] as List;
      (vehicles.single as Map<String, Object?>)['id'] = 1.0;

      final read = codec.decode(json.encode(document)).getRight().toNullable()!;

      expect(read.vehicles.single.id, 1);
    });

    test('missing booleans fall back to the entity defaults', () {
      final entry = RefuelEntry(
        id: 1,
        vehicleId: 1,
        filledAt: DateTime(2026, 1, 1),
        odometer: 100,
        quantity: 2,
        pricePaid: 200,
      );
      final document =
          json.decode(codec.encode(bundle(entries: [entry])))
              as Map<String, Object?>;
      final refuels = document['refuels'] as List;
      (refuels.single as Map<String, Object?>)
        ..remove('fullTank')
        ..remove('odometerOverride');

      final read = codec.decode(json.encode(document)).getRight().toNullable()!;

      expect(read.entries.single.fullTank, isTrue);
      expect(read.entries.single.odometerOverride, isFalse);
    });
  });

  group('failures', () {
    test('a CSV backup from an older version still decodes', () {
      final data = bundle(
        vehicles: [_vehicle()],
        entries: [
          RefuelEntry(
            id: 1,
            vehicleId: 1,
            filledAt: DateTime(2026, 1, 15, 9, 30),
            odometer: 12500,
            quantity: 4.2,
            pricePaid: 420,
          ),
        ],
      );
      final legacy = DataBundleCsvWriter.write(data);

      final read = codec.decode(legacy).getRight().toNullable()!;

      expect(read.vehicles, data.vehicles);
      expect(read.entries, data.entries);
    });

    test('content that is neither JSON nor an OdoLog CSV is rejected', () {
      final failure = failureOf(codec.decode('hello there'));

      expect(failure.reason, contains('not an OdoLog export file'));
    });

    test('a JSON object without the schema tag is rejected', () {
      final failure = failureOf(codec.decode('{"foo": 1}'));

      expect(failure.reason, contains('Not an OdoLog export file'));
    });

    test('an unsupported version is named in the failure', () {
      final failure = failureOf(
        codec.decode(
          '{"schema": "odolog", "version": 99, "vehicles": [], '
          '"refuels": [], "serviceLog": [], "expenses": []}',
        ),
      );

      expect(failure.reason, contains('99'));
    });

    test('a malformed JSON document is rejected as not valid JSON', () {
      final failure = failureOf(codec.decode('{"schema": "odolog",'));

      expect(failure.reason, contains('Not valid JSON'));
    });

    test('a missing section array is named in the failure', () {
      final failure = failureOf(
        codec.decode(
          '{"schema": "odolog", "version": 1, "vehicles": [], '
          '"refuels": [], "serviceLog": []}',
        ),
      );

      expect(failure.reason, contains('expenses'));
    });

    test('a broken item names its position in the failure', () {
      final document =
          json.decode(codec.encode(bundle(vehicles: [_vehicle()])))
              as Map<String, Object?>;
      final vehicles = document['vehicles'] as List;
      (vehicles.single as Map<String, Object?>)['fuelCategory'] = 'plutonium';

      final failure = failureOf(codec.decode(json.encode(document)));

      expect(failure.reason, contains('vehicles[0]'));
      expect(failure.reason, contains('plutonium'));
    });

    test('a vehicle without a name is rejected', () {
      final document =
          json.decode(codec.encode(bundle(vehicles: [_vehicle()])))
              as Map<String, Object?>;
      final vehicles = document['vehicles'] as List;
      (vehicles.single as Map<String, Object?>)['name'] = '  ';

      final failure = failureOf(codec.decode(json.encode(document)));

      expect(failure.reason, contains('"name" is required'));
    });
  });
}

Vehicle _vehicle() => const Vehicle(
  id: 1,
  name: 'Activa',
  type: VehicleType.scooter,
  fuelCategory: FuelCategory.petrol,
);
