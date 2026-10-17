import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../backup/data_bundle.dart';
import '../backup/data_bundle_codec.dart';
import '../backup/unit_of_work.dart';
import '../calculators/mileage_calculator.dart';
import '../entities/refuel_entry.dart';
import 'add_vehicle.dart';
import 'list_vehicles.dart';
import 'log_expense.dart';
import 'log_odometer_reading.dart';
import 'log_refuel.dart';
import 'log_service.dart';

const _duplicateIdMessage =
    'Some items in this file are already on this phone, so nothing was '
    'imported. Import only adds new items, it does not replace what is here.';

/// Decodes a backup file through [DataBundleCodec] and replays it through the
/// same use cases the forms write with, so an imported item passes exactly the
/// validation a hand-entered one does. The whole replay runs inside one
/// [UnitOfWork], so a file that fails on its fortieth row leaves the database
/// exactly as it was rather than half restored. Returns the bundle it just
/// imported so the caller can report what came in without decoding the file a
/// second time.
class ImportData {
  const ImportData(
    this._addVehicle,
    this._logRefuel,
    this._logService,
    this._logExpense,
    this._logOdometerReading,
    this._listVehicles,
    this._codec,
    this._unitOfWork,
  );

  final AddVehicle _addVehicle;
  final LogRefuel _logRefuel;
  final LogService _logService;
  final LogExpense _logExpense;
  final LogOdometerReading _logOdometerReading;
  final ListVehicles _listVehicles;
  final DataBundleCodec _codec;
  final UnitOfWork _unitOfWork;

  Future<Result<DataBundle>> execute(String content) async {
    final decoded = _codec.decode(content);
    return decoded.match(
      (failure) => Future<Result<DataBundle>>.value(left(failure)),
      _apply,
    );
  }

  Future<Result<DataBundle>> _apply(DataBundle bundle) async {
    final owners = await _knownVehicleIds(bundle);
    final ownerFailure = owners.getLeft().toNullable();
    if (ownerFailure != null) return left(ownerFailure);
    final orphan = _findOrphan(bundle, owners.getRight().toNullable()!);
    if (orphan != null) return left(orphan);

    final rolledOver = _vehiclesWithRollover(bundle.entries);
    try {
      await _unitOfWork.run(() => _write(bundle, rolledOver, byRun: false));
    } on _ImportAborted catch (aborted) {
      final withOverride = {
        for (final e in bundle.entries)
          if (e.odometerOverride) e.vehicleId,
      };
      if (withOverride.isEmpty) return left(aborted.failure);
      // An override fill is never checked, so where it goes decides whether
      // the rows around it pass. Try once more run by run, keep the first error.
      try {
        await _unitOfWork.run(() => _write(bundle, withOverride, byRun: true));
      } on _ImportAborted {
        return left(aborted.failure);
      }
    }
    return right(bundle);
  }

  Future<void> _write(
    DataBundle bundle,
    Set<int> vehicleIds, {
    required bool byRun,
  }) async {
    for (var i = 0; i < bundle.vehicles.length; i++) {
      final result = await _addVehicle.execute(bundle.vehicles[i]);
      _abortOnLeft(result, 'vehicles[$i]');
    }
    for (var i = 0; i < bundle.entries.length; i++) {
      if (vehicleIds.contains(bundle.entries[i].vehicleId)) continue;
      final result = await _logRefuel.execute(bundle.entries[i]);
      _abortOnLeft(result, 'refuels[$i]');
    }
    for (var i = 0; i < bundle.serviceLog.length; i++) {
      final result = await _logService.execute(bundle.serviceLog[i]);
      _abortOnLeft(result, 'serviceLog[$i]');
    }
    for (var i = 0; i < bundle.expenses.length; i++) {
      final result = await _logExpense.execute(bundle.expenses[i]);
      _abortOnLeft(result, 'expenses[$i]');
    }
    for (var i = 0; i < bundle.odometerReadings.length; i++) {
      if (vehicleIds.contains(bundle.odometerReadings[i].vehicleId)) continue;
      final result = await _logOdometerReading.execute(
        bundle.odometerReadings[i],
      );
      _abortOnLeft(result, 'odometerReadings[$i]');
    }
    if (byRun) {
      await _writeByRun(bundle, vehicleIds);
    } else {
      await _writeInDateOrder(bundle, vehicleIds);
    }
  }

  /// The file lists fills by odometer, which puts the fills after a rollover
  /// ahead of the ones before it, so such a vehicle replays its fills and
  /// readings by date.
  Future<void> _writeInDateOrder(DataBundle bundle, Set<int> vehicleIds) async {
    final records =
        <
            ({
              DateTime at,
              double odometer,
              String where,
              Future<Result<Object?>> Function() write,
            })
          >[
            for (var i = 0; i < bundle.entries.length; i++)
              if (vehicleIds.contains(bundle.entries[i].vehicleId))
                (
                  at: bundle.entries[i].filledAt,
                  odometer: bundle.entries[i].odometer,
                  where: 'refuels[$i]',
                  write: () => _logRefuel.execute(bundle.entries[i]),
                ),
            for (var i = 0; i < bundle.odometerReadings.length; i++)
              if (vehicleIds.contains(bundle.odometerReadings[i].vehicleId))
                (
                  at: bundle.odometerReadings[i].recordedAt,
                  odometer: bundle.odometerReadings[i].odometer,
                  where: 'odometerReadings[$i]',
                  write: () =>
                      _logOdometerReading.execute(bundle.odometerReadings[i]),
                ),
          ]
          ..sort((a, b) {
            final byTime = a.at.compareTo(b.at);
            return byTime != 0 ? byTime : a.odometer.compareTo(b.odometer);
          });
    for (final record in records) {
      _abortOnLeft(await record.write(), record.where);
    }
  }

  /// Each run goes in the way a vehicle with no rollover does: fills in file
  /// order, then readings, a reading going with the last run that started at
  /// or before it. Override fills go after the readings, except the one that
  /// starts a later run, so a backdated one cannot sit in front of a reading
  /// saved before it.
  Future<void> _writeByRun(DataBundle bundle, Set<int> vehicleIds) async {
    for (final vehicleId in vehicleIds) {
      final runs = const MileageCalculator().runs([
        for (final e in bundle.entries)
          if (e.vehicleId == vehicleId) e,
      ]);
      final starts = [
        for (final run in runs.skip(1))
          run.map((e) => e.filledAt).reduce((a, b) => a.isBefore(b) ? a : b),
      ];
      for (var r = 0; r < runs.length; r++) {
        final inRun = Set<RefuelEntry>.identity()..addAll(runs[r]);
        final fills = [
          for (var i = 0; i < bundle.entries.length; i++)
            if (inRun.contains(bundle.entries[i])) i,
        ];
        bool waits(int i) =>
            bundle.entries[i].odometerOverride &&
            (r == 0 ||
                !bundle.entries[i].filledAt.isAtSameMomentAs(starts[r - 1]));
        for (final i in fills.where((i) => !waits(i))) {
          _abortOnLeft(
            await _logRefuel.execute(bundle.entries[i]),
            'refuels[$i]',
          );
        }
        for (var i = 0; i < bundle.odometerReadings.length; i++) {
          final reading = bundle.odometerReadings[i];
          if (reading.vehicleId != vehicleId) continue;
          final started = starts
              .where((start) => !start.isAfter(reading.recordedAt))
              .length;
          if (started != r) continue;
          _abortOnLeft(
            await _logOdometerReading.execute(reading),
            'odometerReadings[$i]',
          );
        }
        for (final i in fills.where(waits)) {
          _abortOnLeft(
            await _logRefuel.execute(bundle.entries[i]),
            'refuels[$i]',
          );
        }
      }
    }
  }

  /// Vehicles whose fills in the bundle hold a rollover. driveOrder hands back
  /// the same list when there is none.
  static Set<int> _vehiclesWithRollover(List<RefuelEntry> entries) {
    final byVehicle = <int, List<RefuelEntry>>{};
    for (final entry in entries) {
      (byVehicle[entry.vehicleId] ??= []).add(entry);
    }
    return {
      for (final MapEntry(:key, :value) in byVehicle.entries)
        if (!identical(const MileageCalculator().driveOrder(value), value)) key,
    };
  }

  /// Turns a rejected write into a throw, the only way out of a unit of work
  /// that also undoes the rows written before it.
  static void _abortOnLeft(Result<Object?> result, String where) {
    final failure = result.getLeft().toNullable();
    if (failure != null) throw _ImportAborted(_locate(failure, where));
  }

  /// Every vehicle id the bundle is allowed to reference: the ones it carries
  /// plus the ones already on the device.
  Future<Result<Set<int>>> _knownVehicleIds(DataBundle bundle) async {
    final existing = await _listVehicles.execute();
    return existing.map(
      (vehicles) => {
        ...vehicles.map((vehicle) => vehicle.id),
        ...bundle.vehicles.map((vehicle) => vehicle.id),
      },
    );
  }

  /// The first row pointing at a vehicle that is neither in the bundle nor on
  /// the device. Ids are never remapped, so such a row has no owner and the
  /// whole file is refused before anything is written.
  static Failure? _findOrphan(DataBundle bundle, Set<int> known) {
    for (var i = 0; i < bundle.entries.length; i++) {
      final id = bundle.entries[i].vehicleId;
      if (!known.contains(id)) return _orphan(id, 'refuels[$i]');
    }
    for (var i = 0; i < bundle.serviceLog.length; i++) {
      final id = bundle.serviceLog[i].vehicleId;
      if (!known.contains(id)) return _orphan(id, 'serviceLog[$i]');
    }
    for (var i = 0; i < bundle.expenses.length; i++) {
      final id = bundle.expenses[i].vehicleId;
      if (!known.contains(id)) return _orphan(id, 'expenses[$i]');
    }
    for (var i = 0; i < bundle.odometerReadings.length; i++) {
      final id = bundle.odometerReadings[i].vehicleId;
      if (!known.contains(id)) return _orphan(id, 'odometerReadings[$i]');
    }
    return null;
  }

  static Failure _orphan(int vehicleId, String where) => _locate(
    ValidationFailure(
      field: 'vehicleId',
      reason: 'Vehicle $vehicleId is not in this backup or on this device.',
    ),
    where,
  );

  /// Points a complaint at the item that raised it, the same "refuels[3]"
  /// convention the codec uses for a structural problem. A duplicate id gets
  /// the plain message with no location, since the location names a table.
  static Failure _locate(Failure failure, String where) => switch (failure) {
    ValidationFailure() => ValidationFailure(
      field: failure.field,
      reason: '$where: ${failure.reason}',
    ),
    NotFoundFailure() => NotFoundFailure('$where: ${failure.message}'),
    DuplicateIdFailure() => const DuplicateIdFailure(_duplicateIdMessage),
    DatabaseFailure() => DatabaseFailure('$where: ${failure.message}'),
  };
}

/// Carries a located [Failure] out of the unit of work body.
class _ImportAborted implements Exception {
  const _ImportAborted(this.failure);

  final Failure failure;
}
