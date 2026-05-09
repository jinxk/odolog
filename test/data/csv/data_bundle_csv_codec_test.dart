import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/data/csv/data_bundle_csv_codec.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/export_data.dart';

ValidationFailure failureOf(Result<DataBundle> result) {
  return result.getLeft().toNullable()! as ValidationFailure;
}

void main() {
  group('round trip', () {
    test('vehicles and refuels survive a full write and read cycle', () {
      final bundle = (
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

      final csv = DataBundleCsvWriter.write(bundle);
      final result = DataBundleCsvReader.read(csv);

      final read = result.getRight().toNullable()!;
      expect(read.vehicles, bundle.vehicles);
      expect(read.entries, bundle.entries);
    });

    test('a value with an embedded quote mark is escaped and restored', () {
      const vehicle = Vehicle(
        id: 1,
        name: 'Dad\'s "old" scooter',
        type: VehicleType.scooter,
        fuelCategory: FuelCategory.petrol,
      );
      final csv = DataBundleCsvWriter.write((vehicles: [vehicle], entries: []));

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
      final csv = DataBundleCsvWriter.write((
        vehicles: [vehicle],
        entries: [entry],
      ));

      expect(csv, isNot(contains('null')));

      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.vehicles.single.registrationNo, isNull);
      expect(read.vehicles.single.tankCapacity, isNull);
      expect(read.entries.single.variantId, isNull);
      expect(read.entries.single.stationName, isNull);
      expect(read.entries.single.notes, isNull);
    });

    test('an empty id column is read back as an unsaved row', () {
      const bundle = (
        vehicles: [
          Vehicle(
            id: 0,
            name: 'New',
            type: VehicleType.car,
            fuelCategory: FuelCategory.petrol,
          ),
        ],
        entries: <RefuelEntry>[],
      );
      final csv = DataBundleCsvWriter.write(bundle);
      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.vehicles.single.id, 0);
    });
  });

  group('the template', () {
    test('has the schema header, both sections, and one example row each', () {
      final csv = DataBundleCsvWriter.template();
      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.vehicles, hasLength(1));
      expect(read.entries, hasLength(1));
      expect(csv, startsWith('"odolog","2"'));
    });
  });

  group('schema version 2', () {
    test('the claimed mileage and document dates round trip', () {
      final bundle = (
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
        entries: <RefuelEntry>[],
      );

      final csv = DataBundleCsvWriter.write(bundle);
      expect(csv, startsWith('"odolog","2"'));

      final read = DataBundleCsvReader.read(csv).getRight().toNullable()!;
      expect(read.vehicles, bundle.vehicles);
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
        '"odolog","3"\n"vehicles"\n'
        '"id","name","type","fuelCategory","registrationNo","tankCapacity"\n'
        '"refuels"\n'
        '"id","vehicleId","filledAt","odometer","quantity","pricePaid",'
        '"fullTank","variantId","variantOther","stationName","notes",'
        '"odometerOverride"\n',
      );
      expect(failureOf(result).reason, contains('version'));
      expect(failureOf(result).reason, contains('Line 1'));
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
  });
}
