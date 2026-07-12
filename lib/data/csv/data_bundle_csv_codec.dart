/// Reads and writes the CSV format used for both a full backup and the blank
/// import template. One file carries both entities: a schema header row, a
/// `vehicles` section with its own column header, then a `refuels` section
/// with its own. The schema version lets the columns grow without breaking
/// older files: the writer emits version 2 (vehicles gained a claimed mileage
/// figure and four document expiry dates), and the reader still accepts a
/// version 1 file, filling the new vehicle fields with null.
library;

import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../../domain/entities/refuel_entry.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/export_data.dart';
import 'csv_grammar.dart';

/// The section names and column headers the writer and the reader both agree
/// on, kept in one place so they cannot drift apart from each other.
abstract final class DataBundleCsvFormat {
  static const schemaTag = 'odolog';

  /// The version the writer emits. The reader accepts every version in
  /// [supportedVersions].
  static const schemaVersion = '2';

  /// Versions the reader understands. Version 1 predates the vehicle document
  /// and claimed mileage columns; its files still import.
  static const supportedVersions = ['1', '2'];

  static const vehiclesSection = 'vehicles';
  static const refuelsSection = 'refuels';

  /// The original six vehicle columns, still the shape of a version 1 file.
  static const vehicleHeaderV1 = [
    'id',
    'name',
    'type',
    'fuelCategory',
    'registrationNo',
    'tankCapacity',
  ];

  /// Version 2 appends the claimed mileage figure and the four document expiry
  /// dates. Dates are written as ISO 8601, or empty when unset.
  static const vehicleHeaderV2 = [
    ...vehicleHeaderV1,
    'claimedMileage',
    'insuranceExpiry',
    'pucExpiry',
    'rcExpiry',
    'fitnessExpiry',
  ];

  /// The header the writer emits: always the current version.
  static const vehicleHeader = vehicleHeaderV2;

  /// The expected vehicle header for a given file [version].
  static List<String> vehicleHeaderFor(String version) =>
      version == '1' ? vehicleHeaderV1 : vehicleHeaderV2;

  static const refuelHeader = [
    'id',
    'vehicleId',
    'filledAt',
    'odometer',
    'quantity',
    'pricePaid',
    'fullTank',
    'variantId',
    'variantOther',
    'stationName',
    'notes',
    'odometerOverride',
  ];
}

/// Serialises a [DataBundle] to the CSV format described in
/// [DataBundleCsvFormat].
class DataBundleCsvWriter {
  const DataBundleCsvWriter._();

  /// Serialises [bundle] to CSV: the schema header, then the vehicles
  /// section, then the refuels section, every field quoted.
  static String write(DataBundle bundle) {
    final buffer = StringBuffer();
    buffer.writeln(
      CsvGrammar.row([
        DataBundleCsvFormat.schemaTag,
        DataBundleCsvFormat.schemaVersion,
      ]),
    );
    buffer.writeln(CsvGrammar.row([DataBundleCsvFormat.vehiclesSection]));
    buffer.writeln(CsvGrammar.row(DataBundleCsvFormat.vehicleHeader));
    for (final vehicle in bundle.vehicles) {
      buffer.writeln(CsvGrammar.row(_vehicleFields(vehicle)));
    }
    buffer.writeln(CsvGrammar.row([DataBundleCsvFormat.refuelsSection]));
    buffer.writeln(CsvGrammar.row(DataBundleCsvFormat.refuelHeader));
    for (final entry in bundle.entries) {
      buffer.writeln(CsvGrammar.row(_refuelFields(entry)));
    }
    return buffer.toString();
  }

  /// A blank file with both section headers and one realistic example row
  /// each, so a user can fill it in externally and import it back. The
  /// example ids are left as if unsaved would also work on import (an empty
  /// id column asks the database to assign one), but a filled in id keeps the
  /// vehicles and refuels sections linked to each other by example.
  static String template() {
    return write((vehicles: [_exampleVehicle], entries: [_exampleEntry]));
  }

  static List<String> _vehicleFields(Vehicle vehicle) => [
    vehicle.id.toString(),
    vehicle.name,
    vehicle.type.name,
    vehicle.fuelCategory.name,
    vehicle.registrationNo ?? '',
    vehicle.tankCapacity?.toString() ?? '',
    vehicle.claimedMileage?.toString() ?? '',
    vehicle.insuranceExpiry?.toIso8601String() ?? '',
    vehicle.pucExpiry?.toIso8601String() ?? '',
    vehicle.rcExpiry?.toIso8601String() ?? '',
    vehicle.fitnessExpiry?.toIso8601String() ?? '',
  ];

  static List<String> _refuelFields(RefuelEntry entry) => [
    entry.id.toString(),
    entry.vehicleId.toString(),
    entry.filledAt.toIso8601String(),
    entry.odometer.toString(),
    entry.quantity.toString(),
    entry.pricePaid.toString(),
    entry.fullTank.toString(),
    entry.variantId ?? '',
    entry.variantOther ?? '',
    entry.stationName ?? '',
    entry.notes ?? '',
    entry.odometerOverride.toString(),
  ];

  static final _exampleVehicle = Vehicle(
    id: 1,
    name: 'Activa',
    type: VehicleType.scooter,
    fuelCategory: FuelCategory.petrol,
    registrationNo: 'MH12AB1234',
    tankCapacity: 5.3,
    claimedMileage: 60,
    insuranceExpiry: DateTime(2026, 8, 15),
    pucExpiry: DateTime(2026, 4, 1),
  );

  static final _exampleEntry = RefuelEntry(
    id: 1,
    vehicleId: 1,
    filledAt: DateTime(2026, 1, 15, 9, 30),
    odometer: 12500,
    quantity: 4.2,
    pricePaid: 420,
    stationName: 'Highway Fuels',
    notes: 'Topped up before a trip',
  );
}

/// Raised by a row parser to unwind straight to [DataBundleCsvReader.read]
/// with the failure already built, instead of threading a [Result] through
/// every intermediate call.
class _CsvFormatException implements Exception {
  const _CsvFormatException(this.failure);

  final ValidationFailure failure;
}

/// Parses the CSV format described in [DataBundleCsvFormat] back into a
/// [DataBundle].
class DataBundleCsvReader {
  const DataBundleCsvReader._();

  /// Parses [content] back into a [DataBundle]. A structural problem (a
  /// missing section, the wrong columns, an unparsable value) comes back as a
  /// [ValidationFailure] whose reason names the physical line it was found
  /// on. This does not re-check the free text character restriction: a row
  /// written before that restriction existed may still carry a quote mark,
  /// and the RFC 4180 escaping above already carries it safely, so rejecting
  /// it here would only break a legitimate restore.
  static Result<DataBundle> read(String content) {
    try {
      return right(_read(content));
    } on _CsvFormatException catch (e) {
      return left(e.failure);
    }
  }

  static DataBundle _read(String content) {
    final records = CsvGrammar.parse(content);
    if (records.isEmpty) {
      throw const _CsvFormatException(
        ValidationFailure(
          field: 'schema',
          reason: 'Line 1: the file is empty.',
        ),
      );
    }

    var cursor = 0;
    final version = _expectSchemaHeader(records[cursor++]);

    _expectSectionMarker(records, cursor, DataBundleCsvFormat.vehiclesSection);
    cursor++;
    _expectHeaderRow(
      records,
      cursor,
      DataBundleCsvFormat.vehicleHeaderFor(version),
      DataBundleCsvFormat.vehiclesSection,
    );
    cursor++;

    final vehicles = <Vehicle>[];
    while (cursor < records.length && records[cursor].fields.length != 1) {
      vehicles.add(_parseVehicle(records[cursor], version));
      cursor++;
    }

    _expectSectionMarker(records, cursor, DataBundleCsvFormat.refuelsSection);
    cursor++;
    _expectHeaderRow(
      records,
      cursor,
      DataBundleCsvFormat.refuelHeader,
      DataBundleCsvFormat.refuelsSection,
    );
    cursor++;

    final entries = <RefuelEntry>[];
    while (cursor < records.length) {
      entries.add(_parseRefuel(records[cursor]));
      cursor++;
    }

    return (vehicles: vehicles, entries: entries);
  }

  /// Validates the schema header row and returns the declared version, which
  /// the caller threads into vehicle parsing so an older file is read with its
  /// own column set.
  static String _expectSchemaHeader(CsvRecord record) {
    if (record.fields.length != 2 ||
        record.fields[0] != DataBundleCsvFormat.schemaTag) {
      throw _CsvFormatException(
        ValidationFailure(
          field: 'schema',
          reason: 'Line ${record.line}: not an OdoLog export file.',
        ),
      );
    }
    final version = record.fields[1];
    if (!DataBundleCsvFormat.supportedVersions.contains(version)) {
      throw _CsvFormatException(
        ValidationFailure(
          field: 'schema',
          reason:
              'Line ${record.line}: file format version '
              '"$version" is not supported here, expected one of '
              '${DataBundleCsvFormat.supportedVersions.join(', ')}.',
        ),
      );
    }
    return version;
  }

  static void _expectSectionMarker(
    List<CsvRecord> records,
    int cursor,
    String name,
  ) {
    if (cursor >= records.length) {
      throw _CsvFormatException(
        ValidationFailure(
          field: name,
          reason:
              'Line ${_eofLine(records)}: expected the "$name" section, '
              'found end of file.',
        ),
      );
    }
    final record = records[cursor];
    if (record.fields.length != 1 || record.fields[0] != name) {
      throw _CsvFormatException(
        ValidationFailure(
          field: name,
          reason: 'Line ${record.line}: expected the "$name" section marker.',
        ),
      );
    }
  }

  static void _expectHeaderRow(
    List<CsvRecord> records,
    int cursor,
    List<String> expected,
    String section,
  ) {
    if (cursor >= records.length) {
      throw _CsvFormatException(
        ValidationFailure(
          field: section,
          reason:
              'Line ${_eofLine(records)}: missing the $section column '
              'header row.',
        ),
      );
    }
    final record = records[cursor];
    if (!_sameFields(record.fields, expected)) {
      throw _CsvFormatException(
        ValidationFailure(
          field: section,
          reason:
              'Line ${record.line}: unexpected columns for the $section '
              'section, expected ${expected.join(', ')}.',
        ),
      );
    }
  }

  static int _eofLine(List<CsvRecord> records) =>
      records.isEmpty ? 1 : records.last.line + 1;

  static bool _sameFields(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static Vehicle _parseVehicle(CsvRecord record, String version) {
    const section = DataBundleCsvFormat.vehiclesSection;
    final header = DataBundleCsvFormat.vehicleHeaderFor(version);
    final fields = record.fields;
    if (fields.length != header.length) {
      throw _CsvFormatException(
        ValidationFailure(
          field: section,
          reason:
              'Line ${record.line}: expected '
              '${header.length} fields, found '
              '${fields.length}.',
        ),
      );
    }
    final id = fields[0].isEmpty
        ? 0
        : _requiredInt(
            fields[0],
            label: 'id',
            line: record.line,
            section: section,
          );
    final name = fields[1];
    if (name.trim().isEmpty) {
      throw _CsvFormatException(
        ValidationFailure(
          field: section,
          reason: 'Line ${record.line}: "name" is required.',
        ),
      );
    }
    // Version 1 files stop at tankCapacity, so the new fields read back null.
    final hasV2 = version != '1';
    return Vehicle(
      id: id,
      name: name,
      type: _vehicleType(fields[2], record.line),
      fuelCategory: _fuelCategory(fields[3], record.line, section),
      registrationNo: fields[4].isEmpty ? null : fields[4],
      tankCapacity: _optionalDouble(
        fields[5],
        label: 'tankCapacity',
        line: record.line,
        section: section,
      ),
      claimedMileage: hasV2
          ? _optionalDouble(
              fields[6],
              label: 'claimedMileage',
              line: record.line,
              section: section,
            )
          : null,
      insuranceExpiry: hasV2
          ? _optionalDateTime(
              fields[7],
              label: 'insuranceExpiry',
              line: record.line,
              section: section,
            )
          : null,
      pucExpiry: hasV2
          ? _optionalDateTime(
              fields[8],
              label: 'pucExpiry',
              line: record.line,
              section: section,
            )
          : null,
      rcExpiry: hasV2
          ? _optionalDateTime(
              fields[9],
              label: 'rcExpiry',
              line: record.line,
              section: section,
            )
          : null,
      fitnessExpiry: hasV2
          ? _optionalDateTime(
              fields[10],
              label: 'fitnessExpiry',
              line: record.line,
              section: section,
            )
          : null,
    );
  }

  static RefuelEntry _parseRefuel(CsvRecord record) {
    const section = DataBundleCsvFormat.refuelsSection;
    final fields = record.fields;
    if (fields.length != DataBundleCsvFormat.refuelHeader.length) {
      throw _CsvFormatException(
        ValidationFailure(
          field: section,
          reason:
              'Line ${record.line}: expected '
              '${DataBundleCsvFormat.refuelHeader.length} fields, found '
              '${fields.length}.',
        ),
      );
    }
    final id = fields[0].isEmpty
        ? 0
        : _requiredInt(
            fields[0],
            label: 'id',
            line: record.line,
            section: section,
          );
    return RefuelEntry(
      id: id,
      vehicleId: _requiredInt(
        fields[1],
        label: 'vehicleId',
        line: record.line,
        section: section,
      ),
      filledAt: _requiredDateTime(
        fields[2],
        line: record.line,
        section: section,
      ),
      odometer: _requiredDouble(
        fields[3],
        label: 'odometer',
        line: record.line,
        section: section,
      ),
      quantity: _requiredDouble(
        fields[4],
        label: 'quantity',
        line: record.line,
        section: section,
      ),
      pricePaid: _requiredDouble(
        fields[5],
        label: 'pricePaid',
        line: record.line,
        section: section,
      ),
      fullTank: _requiredBool(
        fields[6],
        label: 'fullTank',
        line: record.line,
        section: section,
      ),
      variantId: fields[7].isEmpty ? null : fields[7],
      variantOther: fields[8].isEmpty ? null : fields[8],
      stationName: fields[9].isEmpty ? null : fields[9],
      notes: fields[10].isEmpty ? null : fields[10],
      odometerOverride: _requiredBool(
        fields[11],
        label: 'odometerOverride',
        line: record.line,
        section: section,
      ),
    );
  }

  static VehicleType _vehicleType(String raw, int line) {
    for (final type in VehicleType.values) {
      if (type.name == raw) return type;
    }
    throw _CsvFormatException(
      ValidationFailure(
        field: DataBundleCsvFormat.vehiclesSection,
        reason: 'Line $line: unknown vehicle type "$raw".',
      ),
    );
  }

  static FuelCategory _fuelCategory(String raw, int line, String section) {
    for (final category in FuelCategory.values) {
      if (category.name == raw) return category;
    }
    throw _CsvFormatException(
      ValidationFailure(
        field: section,
        reason: 'Line $line: unknown fuel category "$raw".',
      ),
    );
  }

  static int _requiredInt(
    String raw, {
    required String label,
    required int line,
    required String section,
  }) {
    final value = int.tryParse(raw);
    if (value == null) {
      throw _CsvFormatException(
        ValidationFailure(
          field: section,
          reason: 'Line $line: "$label" must be a whole number.',
        ),
      );
    }
    return value;
  }

  static double _requiredDouble(
    String raw, {
    required String label,
    required int line,
    required String section,
  }) {
    final value = double.tryParse(raw);
    if (value == null) {
      throw _CsvFormatException(
        ValidationFailure(
          field: section,
          reason: 'Line $line: "$label" must be a number.',
        ),
      );
    }
    return value;
  }

  static double? _optionalDouble(
    String raw, {
    required String label,
    required int line,
    required String section,
  }) {
    if (raw.isEmpty) return null;
    return _requiredDouble(raw, label: label, line: line, section: section);
  }

  static bool _requiredBool(
    String raw, {
    required String label,
    required int line,
    required String section,
  }) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    throw _CsvFormatException(
      ValidationFailure(
        field: section,
        reason: 'Line $line: "$label" must be "true" or "false".',
      ),
    );
  }

  static DateTime _requiredDateTime(
    String raw, {
    required int line,
    required String section,
  }) {
    final value = DateTime.tryParse(raw);
    if (value == null) {
      throw _CsvFormatException(
        ValidationFailure(
          field: section,
          reason: 'Line $line: "filledAt" must be an ISO 8601 date and time.',
        ),
      );
    }
    return value;
  }

  static DateTime? _optionalDateTime(
    String raw, {
    required String label,
    required int line,
    required String section,
  }) {
    if (raw.isEmpty) return null;
    final value = DateTime.tryParse(raw);
    if (value == null) {
      throw _CsvFormatException(
        ValidationFailure(
          field: section,
          reason: 'Line $line: "$label" must be an ISO 8601 date, or empty.',
        ),
      );
    }
    return value;
  }
}
