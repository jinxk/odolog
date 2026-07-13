/// Reads and writes the JSON format used for both a full backup and the blank
/// import template. One document carries every entity: a schema tag and
/// version at the top, then one array per entity. JSON replaced CSV as the
/// export format in 1.1; [DataBundleJsonCodec.decode] still hands anything
/// that does not look like JSON to the old CSV reader, so a backup written by
/// an earlier version keeps restoring.
library;

import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../../domain/backup/data_bundle.dart';
import '../../domain/backup/data_bundle_codec.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/refuel_entry.dart';
import '../../domain/entities/service_log_entry.dart';
import '../../domain/entities/vehicle.dart';
import '../csv/data_bundle_csv_codec.dart';

/// The key names and version the writer and the reader both agree on, kept in
/// one place so they cannot drift apart from each other.
abstract final class DataBundleJsonFormat {
  static const schemaTag = 'odolog';

  /// The version the writer emits. The reader accepts every version in
  /// [supportedVersions]. The count restarts at 1 because the JSON format has
  /// no version history to stay compatible with; the CSV versions belong to
  /// the CSV reader.
  static const schemaVersion = 1;

  static const supportedVersions = [1];

  static const vehiclesKey = 'vehicles';
  static const refuelsKey = 'refuels';
  static const serviceLogKey = 'serviceLog';
  static const expensesKey = 'expenses';
}

/// Raised by an item parser to unwind straight to [DataBundleJsonCodec.decode]
/// with the failure already built, instead of threading a [Result] through
/// every intermediate call.
class _JsonFormatException implements Exception {
  const _JsonFormatException(this.failure);

  final ValidationFailure failure;
}

Never _fail(String section, String reason) {
  throw _JsonFormatException(ValidationFailure(field: section, reason: reason));
}

/// [DataBundleCodec] over the JSON format described in [DataBundleJsonFormat].
class DataBundleJsonCodec implements DataBundleCodec {
  const DataBundleJsonCodec();

  /// Serialises [bundle] to JSON, pretty printed so the file stays editable
  /// by hand, which is the whole point of the template flow.
  @override
  String encode(DataBundle bundle) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'schema': DataBundleJsonFormat.schemaTag,
      'version': DataBundleJsonFormat.schemaVersion,
      DataBundleJsonFormat.vehiclesKey: [
        for (final vehicle in bundle.vehicles) _vehicleJson(vehicle),
      ],
      DataBundleJsonFormat.refuelsKey: [
        for (final entry in bundle.entries) _refuelJson(entry),
      ],
      DataBundleJsonFormat.serviceLogKey: [
        for (final entry in bundle.serviceLog) _serviceLogJson(entry),
      ],
      DataBundleJsonFormat.expensesKey: [
        for (final expense in bundle.expenses) _expenseJson(expense),
      ],
    });
  }

  /// A blank file with every array and one realistic example item each, so a
  /// user can fill it in externally and import it back. The example ids are
  /// kept: left out they would also work on import (a missing id asks the
  /// database to assign one), but a filled in id keeps the arrays linked to
  /// each other by example.
  @override
  String template() {
    return encode((
      vehicles: [_exampleVehicle],
      entries: [_exampleEntry],
      serviceLog: [_exampleServiceLog],
      expenses: [_exampleExpense],
    ));
  }

  /// Parses [content] back into a [DataBundle]. A structural problem (a
  /// missing array, a wrong type, an unparsable value) comes back as a
  /// [ValidationFailure] whose reason names where it was found. Content that
  /// does not open a JSON object goes to [DataBundleCsvReader] instead: a
  /// backup written before the JSON format existed is CSV, and the CSV reader
  /// also owns the "not an OdoLog export file" complaint for anything else.
  @override
  Result<DataBundle> decode(String content) {
    if (!content.trimLeft().startsWith('{')) {
      return DataBundleCsvReader.read(content);
    }
    try {
      return right(_read(content));
    } on _JsonFormatException catch (e) {
      return left(e.failure);
    }
  }

  static DataBundle _read(String content) {
    final Object? decoded;
    try {
      decoded = json.decode(content);
    } on FormatException catch (e) {
      _fail('schema', 'Not valid JSON: ${e.message}');
    }
    if (decoded is! Map<String, Object?>) {
      _fail('schema', 'Expected a JSON object at the top level.');
    }
    if (decoded['schema'] != DataBundleJsonFormat.schemaTag) {
      _fail('schema', 'Not an OdoLog export file.');
    }
    final version = decoded['version'];
    if (version is! int ||
        !DataBundleJsonFormat.supportedVersions.contains(version)) {
      _fail(
        'schema',
        'File format version "$version" is not supported here, expected one '
            'of ${DataBundleJsonFormat.supportedVersions.join(', ')}.',
      );
    }
    return (
      vehicles: _items(
        decoded,
        DataBundleJsonFormat.vehiclesKey,
        _parseVehicle,
      ),
      entries: _items(decoded, DataBundleJsonFormat.refuelsKey, _parseRefuel),
      serviceLog: _items(
        decoded,
        DataBundleJsonFormat.serviceLogKey,
        _parseServiceLog,
      ),
      expenses: _items(
        decoded,
        DataBundleJsonFormat.expensesKey,
        _parseExpense,
      ),
    );
  }

  /// Reads the array under [key] and parses each element, naming the element
  /// ("vehicles[2]") in any failure so a hand edited file points back at the
  /// item that broke.
  static List<T> _items<T>(
    Map<String, Object?> document,
    String key,
    T Function(Map<String, Object?> item, String where) parse,
  ) {
    final raw = document[key];
    if (raw is! List) {
      _fail(key, 'Expected a "$key" array.');
    }
    final items = <T>[];
    for (var i = 0; i < raw.length; i++) {
      final element = raw[i];
      final where = '$key[$i]';
      if (element is! Map<String, Object?>) {
        _fail(key, 'Expected $where to be an object.');
      }
      items.add(parse(element, where));
    }
    return items;
  }

  static Map<String, Object?> _vehicleJson(Vehicle vehicle) => {
    'id': vehicle.id,
    'name': vehicle.name,
    'type': vehicle.type.name,
    'fuelCategory': vehicle.fuelCategory.name,
    'registrationNo': vehicle.registrationNo,
    'tankCapacity': vehicle.tankCapacity,
    'claimedMileage': vehicle.claimedMileage,
    'insuranceExpiry': vehicle.insuranceExpiry?.toIso8601String(),
    'pucExpiry': vehicle.pucExpiry?.toIso8601String(),
    'rcExpiry': vehicle.rcExpiry?.toIso8601String(),
    'fitnessExpiry': vehicle.fitnessExpiry?.toIso8601String(),
    'engineOilIntervalKm': vehicle.engineOilIntervalKm,
    'generalServiceIntervalDays': vehicle.generalServiceIntervalDays,
  };

  static Map<String, Object?> _refuelJson(RefuelEntry entry) => {
    'id': entry.id,
    'vehicleId': entry.vehicleId,
    'filledAt': entry.filledAt.toIso8601String(),
    'odometer': entry.odometer,
    'quantity': entry.quantity,
    'pricePaid': entry.pricePaid,
    'fullTank': entry.fullTank,
    'variantId': entry.variantId,
    'variantOther': entry.variantOther,
    'stationName': entry.stationName,
    'notes': entry.notes,
    'odometerOverride': entry.odometerOverride,
  };

  static Map<String, Object?> _serviceLogJson(ServiceLogEntry entry) => {
    'id': entry.id,
    'vehicleId': entry.vehicleId,
    'template': entry.template.name,
    'performedAt': entry.performedAt.toIso8601String(),
    'odometer': entry.odometer,
    'cost': entry.cost,
    'note': entry.note,
  };

  static Map<String, Object?> _expenseJson(Expense expense) => {
    'id': expense.id,
    'vehicleId': expense.vehicleId,
    'amount': expense.amount,
    'date': expense.date.toIso8601String(),
    'odometer': expense.odometer,
    'category': expense.category,
  };

  static Vehicle _parseVehicle(Map<String, Object?> item, String where) {
    final name = item['name'];
    if (name is! String || name.trim().isEmpty) {
      _fail(where, '$where: "name" is required.');
    }
    return Vehicle(
      id: _id(item, where),
      name: name,
      type: _vehicleType(item['type'], where),
      fuelCategory: _fuelCategory(item['fuelCategory'], where),
      registrationNo: _optionalString(item, 'registrationNo', where),
      tankCapacity: _optionalDouble(item, 'tankCapacity', where),
      claimedMileage: _optionalDouble(item, 'claimedMileage', where),
      insuranceExpiry: _optionalDateTime(item, 'insuranceExpiry', where),
      pucExpiry: _optionalDateTime(item, 'pucExpiry', where),
      rcExpiry: _optionalDateTime(item, 'rcExpiry', where),
      fitnessExpiry: _optionalDateTime(item, 'fitnessExpiry', where),
      engineOilIntervalKm: _optionalDouble(item, 'engineOilIntervalKm', where),
      generalServiceIntervalDays: _optionalInt(
        item,
        'generalServiceIntervalDays',
        where,
      ),
    );
  }

  static RefuelEntry _parseRefuel(Map<String, Object?> item, String where) {
    return RefuelEntry(
      id: _id(item, where),
      vehicleId: _requiredInt(item, 'vehicleId', where),
      filledAt: _requiredDateTime(item, 'filledAt', where),
      odometer: _requiredDouble(item, 'odometer', where),
      quantity: _requiredDouble(item, 'quantity', where),
      pricePaid: _requiredDouble(item, 'pricePaid', where),
      fullTank: _optionalBool(item, 'fullTank', where) ?? true,
      variantId: _optionalString(item, 'variantId', where),
      variantOther: _optionalString(item, 'variantOther', where),
      stationName: _optionalString(item, 'stationName', where),
      notes: _optionalString(item, 'notes', where),
      odometerOverride: _optionalBool(item, 'odometerOverride', where) ?? false,
    );
  }

  static ServiceLogEntry _parseServiceLog(
    Map<String, Object?> item,
    String where,
  ) {
    return ServiceLogEntry(
      id: _id(item, where),
      vehicleId: _requiredInt(item, 'vehicleId', where),
      template: _serviceTemplate(item['template'], where),
      performedAt: _requiredDateTime(item, 'performedAt', where),
      odometer: _requiredDouble(item, 'odometer', where),
      cost: _optionalDouble(item, 'cost', where),
      note: _optionalString(item, 'note', where),
    );
  }

  static Expense _parseExpense(Map<String, Object?> item, String where) {
    final category = item['category'];
    if (category is! String) {
      _fail(where, '$where: "category" is required.');
    }
    return Expense(
      id: _id(item, where),
      vehicleId: _requiredInt(item, 'vehicleId', where),
      amount: _requiredDouble(item, 'amount', where),
      date: _requiredDateTime(item, 'date', where),
      odometer: _optionalDouble(item, 'odometer', where),
      category: category,
    );
  }

  static VehicleType _vehicleType(Object? raw, String where) {
    for (final type in VehicleType.values) {
      if (type.name == raw) return type;
    }
    _fail(where, '$where: unknown vehicle type "$raw".');
  }

  static FuelCategory _fuelCategory(Object? raw, String where) {
    for (final category in FuelCategory.values) {
      if (category.name == raw) return category;
    }
    _fail(where, '$where: unknown fuel category "$raw".');
  }

  static ServiceTemplate _serviceTemplate(Object? raw, String where) {
    for (final template in ServiceTemplate.values) {
      if (template.name == raw) return template;
    }
    _fail(where, '$where: unknown service template "$raw".');
  }

  /// A missing or null id reads back as 0, which asks the database to assign
  /// one on import, the same convention the CSV format used.
  static int _id(Map<String, Object?> item, String where) {
    if (item['id'] == null) return 0;
    return _requiredInt(item, 'id', where);
  }

  static int _requiredInt(
    Map<String, Object?> item,
    String label,
    String where,
  ) {
    final value = _optionalInt(item, label, where);
    if (value == null) {
      _fail(where, '$where: "$label" must be a whole number.');
    }
    return value;
  }

  /// Accepts any JSON number with an integral value, not just an int token: a
  /// hand edited file that writes 3 as 3.0 should not fail the import over it.
  static int? _optionalInt(
    Map<String, Object?> item,
    String label,
    String where,
  ) {
    final raw = item[label];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num && raw == raw.roundToDouble()) return raw.round();
    _fail(where, '$where: "$label" must be a whole number.');
  }

  static double _requiredDouble(
    Map<String, Object?> item,
    String label,
    String where,
  ) {
    final value = _optionalDouble(item, label, where);
    if (value == null) {
      _fail(where, '$where: "$label" must be a number.');
    }
    return value;
  }

  static double? _optionalDouble(
    Map<String, Object?> item,
    String label,
    String where,
  ) {
    final raw = item[label];
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    _fail(where, '$where: "$label" must be a number.');
  }

  static bool? _optionalBool(
    Map<String, Object?> item,
    String label,
    String where,
  ) {
    final raw = item[label];
    if (raw == null) return null;
    if (raw is bool) return raw;
    _fail(where, '$where: "$label" must be true or false.');
  }

  /// An absent key, a null, and an empty string all read back as null, so a
  /// template user can clear an example value any of the three ways.
  static String? _optionalString(
    Map<String, Object?> item,
    String label,
    String where,
  ) {
    final raw = item[label];
    if (raw == null) return null;
    if (raw is String) return raw.isEmpty ? null : raw;
    _fail(where, '$where: "$label" must be text.');
  }

  static DateTime _requiredDateTime(
    Map<String, Object?> item,
    String label,
    String where,
  ) {
    final value = _optionalDateTime(item, label, where);
    if (value == null) {
      _fail(where, '$where: "$label" must be an ISO 8601 date and time.');
    }
    return value;
  }

  static DateTime? _optionalDateTime(
    Map<String, Object?> item,
    String label,
    String where,
  ) {
    final raw = item[label];
    if (raw == null) return null;
    final value = raw is String ? DateTime.tryParse(raw) : null;
    if (value == null) {
      _fail(where, '$where: "$label" must be an ISO 8601 date, or null.');
    }
    return value;
  }

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
    engineOilIntervalKm: 3000,
    generalServiceIntervalDays: 180,
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

  static final _exampleServiceLog = ServiceLogEntry(
    id: 1,
    vehicleId: 1,
    template: ServiceTemplate.engineOil,
    performedAt: DateTime(2026, 1, 10),
    odometer: 12000,
    cost: 450,
    note: 'Full synthetic',
  );

  static final _exampleExpense = Expense(
    id: 1,
    vehicleId: 1,
    amount: 800,
    date: DateTime(2026, 1, 20),
    odometer: 12550,
    category: 'Tyre',
  );
}
