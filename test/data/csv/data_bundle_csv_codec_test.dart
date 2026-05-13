import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/data/csv/data_bundle_csv_codec.dart';
import 'package:odolog/domain/entities/expense.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/export_data.dart';

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
  group('round trip', () {
    test('vehicles and refuels survive a full write and read cycle', () {
      final data = bundle(
        vehicles: [
          const Vehicle(
            id: 1,
            name: 'Activa',
            type: VehicleType.scooter,
            fuelCategory: FuelCategory.petrol,
            registrationNo: 'MH12AB1234',
            tankCapacity: 5.3,
          ),
          const Vehicle(
            id: 2,
            name: 'Swift, hatchback',
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
            variantId: 'iocl-xp100',
            stationName: 'Highway Fuels, near the mall',
            notes: 'Topped up before a trip, in a hurry',
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
      );

      final csv = DataBundleCsvWriter.write(data);
      final result = DataBundleCsvReader.read(csv);

      final read = result.getRight().toNullable()!;
      expect(read.vehicles, data.vehicles);
      expect(read.entries, data.entries);
    });

    test('a value with an embedded quote mark is escaped and restored', () {
      const vehicle = Vehicle(
        id: 1,
        name: 'Dad\'s "old" scooter',
        type: VehicleType.scooter,
        fuelCategory: FuelCategory.petrol,
      );
      final csv = DataBundleCsvWriter.write(bundle(vehicles: [vehicle]));

      // The writer doubles the embedded quote so the field stays one token.
      expect(csv, contains('"Dad\'s ""old"" scooter"'));

      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.vehicles.single.name, 'Dad\'s "old" scooter');
    });

    test('optional fields round trip as empty rather than the word null', () {
      const vehicle = Vehicle(
        id: 1,
        name: 'Bare',
        type: VehicleType.other,
        fuelCategory: FuelCategory.petrol,
      );
      final entry = RefuelEntry(
        id: 1,
        vehicleId: 1,
        filledAt: DateTime(2026, 1, 1),
        odometer: 100,
        quantity: 2,
        pricePaid: 200,
      );
      final csv = DataBundleCsvWriter.write(
        bundle(vehicles: [vehicle], entries: [entry]),
      );

      expect(csv, isNot(contains('null')));

      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.vehicles.single.registrationNo, isNull);
      expect(read.vehicles.single.tankCapacity, isNull);
      expect(read.vehicles.single.engineOilIntervalKm, isNull);
      expect(read.vehicles.single.generalServiceIntervalDays, isNull);
      expect(read.entries.single.variantId, isNull);
      expect(read.entries.single.stationName, isNull);
      expect(read.entries.single.notes, isNull);
    });

    test('an empty id column is read back as an unsaved row', () {
      final data = bundle(
        vehicles: const [
          Vehicle(
            id: 0,
            name: 'New',
            type: VehicleType.car,
            fuelCategory: FuelCategory.petrol,
          ),
        ],
      );
      final csv = DataBundleCsvWriter.write(data);
      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.vehicles.single.id, 0);
    });
  });

  group('the template', () {
    test('has the schema header, every section, and one example row each', () {
      final csv = DataBundleCsvWriter.template();
      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.vehicles, hasLength(1));
      expect(read.entries, hasLength(1));
      expect(read.serviceLog, hasLength(1));
      expect(read.expenses, hasLength(1));
      expect(csv, startsWith('"odolog","3"'));
    });
  });

  group('schema version 2', () {
    test('the claimed mileage and document dates round trip', () {
      final data = bundle(
        vehicles: [
          Vehicle(
            id: 1,
            name: 'Swift',
            type: VehicleType.car,
            fuelCategory: FuelCategory.petrol,
            claimedMileage: 21.5,
            insuranceExpiry: DateTime(2026, 8, 15),
            pucExpiry: DateTime(2026, 4, 1),
            fitnessExpiry: DateTime(2030, 1, 20),
          ),
          // A vehicle that leaves every new field unset still round trips with
          // them null rather than picking up a stray value.
          const Vehicle(
            id: 2,
            name: 'Activa',
            type: VehicleType.scooter,
            fuelCategory: FuelCategory.petrol,
          ),
        ],
      );

      final csv = DataBundleCsvWriter.write(data);
      // The writer always emits the current version; version 2's fields still
      // round trip inside it.
      expect(csv, startsWith('"odolog","3"'));

      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.vehicles, data.vehicles);
      final swift = read.vehicles.first;
      expect(swift.claimedMileage, 21.5);
      expect(swift.insuranceExpiry, DateTime(2026, 8, 15));
      expect(swift.rcExpiry, isNull);
      final activa = read.vehicles[1];
      expect(activa.claimedMileage, isNull);
      expect(activa.insuranceExpiry, isNull);
    });

    test('a version 1 file still imports with the new fields null', () {
      // A file written before v2: the six original vehicle columns only.
      final read = DataBundleCsvReader.read(
        '"odolog","1"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity"\n'
        '"1","Activa","scooter","petrol","MH12AB1234","5.3"\n'
        '"refuels"\n'
        '"id","vehicleId","filledAt","odometer","quantity","pricePaid",'
        '"fullTank","variantId","variantOther","stationName","notes",'
        '"odometerOverride"\n',
      ).getRight().toNullable()!;

      final vehicle = read.vehicles.single;
      expect(vehicle.name, 'Activa');
      expect(vehicle.registrationNo, 'MH12AB1234');
      expect(vehicle.tankCapacity, 5.3);
      expect(vehicle.claimedMileage, isNull);
      expect(vehicle.insuranceExpiry, isNull);
      expect(vehicle.pucExpiry, isNull);
      expect(vehicle.rcExpiry, isNull);
      expect(vehicle.fitnessExpiry, isNull);
      expect(vehicle.engineOilIntervalKm, isNull);
      expect(vehicle.generalServiceIntervalDays, isNull);
      expect(read.serviceLog, isEmpty);
      expect(read.expenses, isEmpty);
    });

    test('a version 2 file still imports with no service or expense rows', () {
      final read = DataBundleCsvReader.read(
        '"odolog","2"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity",'
        '"claimedMileage","insuranceExpiry","pucExpiry","rcExpiry",'
        '"fitnessExpiry"\n'
        '"1","Activa","scooter","petrol","","","","","","",""\n'
        '"refuels"\n'
        '"id","vehicleId","filledAt","odometer","quantity","pricePaid",'
        '"fullTank","variantId","variantOther","stationName","notes",'
        '"odometerOverride"\n',
      ).getRight().toNullable()!;

      expect(read.vehicles.single.name, 'Activa');
      expect(read.vehicles.single.engineOilIntervalKm, isNull);
      expect(read.serviceLog, isEmpty);
      expect(read.expenses, isEmpty);
    });
  });

  group('schema version 3', () {
    test('service intervals, service log, and expenses round trip', () {
      final data = bundle(
        vehicles: [
          const Vehicle(
            id: 1,
            name: 'Activa',
            type: VehicleType.scooter,
            fuelCategory: FuelCategory.petrol,
            engineOilIntervalKm: 2500,
            generalServiceIntervalDays: 120,
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
          ServiceLogEntry(
            id: 2,
            vehicleId: 1,
            template: ServiceTemplate.generalService,
            performedAt: DateTime(2026, 2, 1),
            odometer: 12300,
          ),
        ],
        expenses: [
          Expense(
            id: 1,
            vehicleId: 1,
            amount: 800,
            date: DateTime(2026, 1, 20),
            odometer: 12100,
            category: 'Tyre',
          ),
          Expense(
            id: 2,
            vehicleId: 1,
            amount: 5000,
            date: DateTime(2026, 3, 1),
            category: 'Insurance',
          ),
        ],
      );

      final csv = DataBundleCsvWriter.write(data);
      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;

      expect(read.vehicles.single.engineOilIntervalKm, 2500);
      expect(read.vehicles.single.generalServiceIntervalDays, 120);
      expect(read.serviceLog, data.serviceLog);
      expect(read.expenses, data.expenses);
    });

    test('an optional service cost and note round trip as empty', () {
      final entry = ServiceLogEntry(
        id: 1,
        vehicleId: 1,
        template: ServiceTemplate.generalService,
        performedAt: DateTime(2026, 1, 1),
        odometer: 100,
      );
      final csv = DataBundleCsvWriter.write(bundle(serviceLog: [entry]));

      expect(csv, isNot(contains('null')));
      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.serviceLog.single.cost, isNull);
      expect(read.serviceLog.single.note, isNull);
    });

    test('an optional expense odometer round trips as empty', () {
      final expense = Expense(
        id: 1,
        vehicleId: 1,
        amount: 100,
        date: DateTime(2026, 1, 1),
        category: 'Repair',
      );
      final csv = DataBundleCsvWriter.write(bundle(expenses: [expense]));

      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.expenses.single.odometer, isNull);
    });
  });

  group('malformed input', () {
    test('an empty file is rejected', () {
      final result = DataBundleCsvReader.read('');
      expect(failureOf(result).reason, contains('Line 1'));
    });

    test('a missing schema header is rejected', () {
      final result = DataBundleCsvReader.read('"not odolog","1"\n');
      expect(failureOf(result).field, 'schema');
      expect(failureOf(result).reason, contains('Line 1'));
    });

    test('an unsupported schema version is rejected', () {
      final result = DataBundleCsvReader.read(
        '"odolog","4"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity"\n'
        '"refuels"\n'
        '"id","vehicleId","filledAt","odometer","quantity","pricePaid",'
        '"fullTank","variantId","variantOther","stationName","notes",'
        '"odometerOverride"\n',
      );
      expect(failureOf(result).reason, contains('version'));
      expect(failureOf(result).reason, contains('Line 1'));
    });

    test('a version 2 file with a stray single-field row after refuels is '
        'rejected, not silently truncated', () {
      final result = DataBundleCsvReader.read(
        '"odolog","2"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity",'
        '"claimedMileage","insuranceExpiry","pucExpiry","rcExpiry",'
        '"fitnessExpiry"\n'
        '"refuels"\n'
        '"id","vehicleId","filledAt","odometer","quantity","pricePaid",'
        '"fullTank","variantId","variantOther","stationName","notes",'
        '"odometerOverride"\n'
        '"garbage"\n',
      );
      // A single-field row is not a legitimate section marker in a version
      // 2 file (it has no sections after refuels), so it must reach the row
      // parser and fail loudly on its field count rather than being read as
      // a boundary and dropped.
      expect(failureOf(result).field, 'refuels');
      expect(failureOf(result).reason, contains('Line 6'));
      expect(failureOf(result).reason, contains('expected 12 fields, found 1'));
    });

    test('a missing vehicles section marker is rejected', () {
      final result = DataBundleCsvReader.read('"odolog","1"\n"not vehicles"\n');
      expect(failureOf(result).field, 'vehicles');
      expect(failureOf(result).reason, contains('Line 2'));
    });

    test('unexpected vehicle columns are rejected', () {
      final result = DataBundleCsvReader.read(
        '"odolog","1"\n"vehicles"\n"id","name"\n',
      );
      expect(failureOf(result).field, 'vehicles');
      expect(failureOf(result).reason, contains('Line 3'));
    });

    test('a vehicle row with the wrong number of fields cites its line', () {
      final result = DataBundleCsvReader.read(
        '"odolog","1"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity"\n'
        '"1","Activa","scooter"\n'
        '"refuels"\n'
        '"id","vehicleId","filledAt","odometer","quantity","pricePaid",'
        '"fullTank","variantId","variantOther","stationName","notes",'
        '"odometerOverride"\n',
      );
      expect(failureOf(result).field, 'vehicles');
      expect(failureOf(result).reason, contains('Line 4'));
      expect(failureOf(result).reason, contains('expected 6 fields, found 3'));
    });

    test('an unknown fuel category cites its line', () {
      final result = DataBundleCsvReader.read(
        '"odolog","1"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity"\n'
        '"1","Activa","scooter","hydrogen","",""\n'
        '"refuels"\n'
        '"id","vehicleId","filledAt","odometer","quantity","pricePaid",'
        '"fullTank","variantId","variantOther","stationName","notes",'
        '"odometerOverride"\n',
      );
      expect(failureOf(result).reason, contains('Line 4'));
      expect(failureOf(result).reason, contains('hydrogen'));
    });

    test('a non numeric odometer in a refuel row cites its line', () {
      final result = DataBundleCsvReader.read(
        '"odolog","1"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity"\n'
        '"refuels"\n'
        '"id","vehicleId","filledAt","odometer","quantity","pricePaid",'
        '"fullTank","variantId","variantOther","stationName","notes",'
        '"odometerOverride"\n'
        '"1","1","2026-01-01T00:00:00.000","not a number","2","200","true",'
        '"","","","","false"\n',
      );
      expect(failureOf(result).field, 'refuels');
      expect(failureOf(result).reason, contains('Line 6'));
      expect(failureOf(result).reason, contains('odometer'));
    });

    test('an invalid boolean in a refuel row cites its line', () {
      final result = DataBundleCsvReader.read(
        '"odolog","1"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity"\n'
        '"refuels"\n'
        '"id","vehicleId","filledAt","odometer","quantity","pricePaid",'
        '"fullTank","variantId","variantOther","stationName","notes",'
        '"odometerOverride"\n'
        '"1","1","2026-01-01T00:00:00.000","100","2","200","yes",'
        '"","","","","false"\n',
      );
      expect(failureOf(result).reason, contains('Line 6'));
      expect(failureOf(result).reason, contains('fullTank'));
    });

    test('a missing refuels section at end of file is rejected', () {
      final result = DataBundleCsvReader.read(
        '"odolog","1"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity"\n',
      );
      expect(failureOf(result).field, 'refuels');
    });

    test('a version 3 file missing the service log section is rejected', () {
      final result = DataBundleCsvReader.read(
        '"odolog","3"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity",'
        '"claimedMileage","insuranceExpiry","pucExpiry","rcExpiry",'
        '"fitnessExpiry","engineOilIntervalKm","generalServiceIntervalDays"\n'
        '"refuels"\n'
        '"id","vehicleId","filledAt","odometer","quantity","pricePaid",'
        '"fullTank","variantId","variantOther","stationName","notes",'
        '"odometerOverride"\n',
      );
      expect(failureOf(result).field, 'service_log');
    });
  });
}
