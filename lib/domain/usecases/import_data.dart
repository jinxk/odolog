import 'dart:isolate';

import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../backup/data_bundle.dart';
import '../backup/data_bundle_codec.dart';
import '../backup/unit_of_work.dart';
import '../calculators/mileage_calculator.dart';
import '../entities/refuel_entry.dart';
import '../repositories/odometer_reading_repository.dart';
import '../repositories/refuel_repository.dart';
import '../validators/odometer_sequence_validator.dart';
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
    this._refuelRepository,
    this._readingRepository,
  );

  final AddVehicle _addVehicle;
  final LogRefuel _logRefuel;
  final LogService _logService;
  final LogExpense _logExpense;
  final LogOdometerReading _logOdometerReading;
  final ListVehicles _listVehicles;
  final DataBundleCodec _codec;
  final UnitOfWork _unitOfWork;
  final RefuelRepository _refuelRepository;
  final OdometerReadingRepository _readingRepository;

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
    final known = owners.getRight().toNullable()!;
    final orphan = _findOrphan(bundle, known);
    if (orphan != null) return left(orphan);
    final stored = await _findStoredItem(bundle, known);
    if (stored != null) return left(stored);

    final rolledOver = _vehiclesWithRollover(bundle.entries);
    // Order per vehicle: 0 the first try (file order, by date for a rollover
    // vehicle), 1 run by run, 2 run by run with override fills held back,
    // 3 the order the rows were saved in. An override fill is never checked,
    // so where it goes decides whether the rows around it pass. Vehicles never
    // check each other's rows, so a refused vehicle moves on alone and the
    // whole file is written again. If every order is refused the first error
    // is kept.
    final orders = <int, int>{};
    Failure? first;
    while (true) {
      try {
        await _unitOfWork.run(() => _write(bundle, rolledOver, orders));
        return right(bundle);
      } on _ImportAborted catch (aborted) {
        first ??= aborted.failure;
        final vehicleId = aborted.vehicleId;
        if (vehicleId == null) return left(first);
        final next = (orders[vehicleId] ?? 0) + 1;
        if (next > 3) return left(first);
        orders[vehicleId] = next;
      }
    }
  }

  Future<void> _write(
    DataBundle bundle,
    Set<int> rolledOver,
    Map<int, int> orders,
  ) async {
    bool plain(int vehicleId) =>
        !rolledOver.contains(vehicleId) && !orders.containsKey(vehicleId);
    for (var i = 0; i < bundle.vehicles.length; i++) {
      final result = await _addVehicle.execute(bundle.vehicles[i]);
      _abortOnLeft(result, 'vehicles[$i]');
    }
    for (var i = 0; i < bundle.entries.length; i++) {
      final vehicleId = bundle.entries[i].vehicleId;
      if (!plain(vehicleId)) continue;
      final result = await _logRefuel.execute(bundle.entries[i]);
      _abortOnLeft(result, 'refuels[$i]', vehicleId);
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
      final vehicleId = bundle.odometerReadings[i].vehicleId;
      if (!plain(vehicleId)) continue;
      final result = await _logOdometerReading.execute(
        bundle.odometerReadings[i],
      );
      _abortOnLeft(result, 'odometerReadings[$i]', vehicleId);
    }
    // Rollover vehicles still on the first try go in together, so the first
    // error is the one the first try reports.
    await _writeInDateOrder(bundle, {
      for (final v in rolledOver)
        if ((orders[v] ?? 0) == 0) v,
    });
    for (final MapEntry(key: vehicleId, value: order) in orders.entries) {
      switch (order) {
        case 1:
          await _writeByRun(bundle, {vehicleId}, false);
        case 2:
          await _writeByRun(bundle, {vehicleId}, true);
        case 3:
          await _writeSaved(bundle, vehicleId);
      }
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
              int vehicleId,
              Future<Result<Object?>> Function() write,
            })
          >[
            for (var i = 0; i < bundle.entries.length; i++)
              if (vehicleIds.contains(bundle.entries[i].vehicleId))
                (
                  at: bundle.entries[i].filledAt,
                  odometer: bundle.entries[i].odometer,
                  where: 'refuels[$i]',
                  vehicleId: bundle.entries[i].vehicleId,
                  write: () => _logRefuel.execute(bundle.entries[i]),
                ),
            for (var i = 0; i < bundle.odometerReadings.length; i++)
              if (vehicleIds.contains(bundle.odometerReadings[i].vehicleId))
                (
                  at: bundle.odometerReadings[i].recordedAt,
                  odometer: bundle.odometerReadings[i].odometer,
                  where: 'odometerReadings[$i]',
                  vehicleId: bundle.odometerReadings[i].vehicleId,
                  write: () =>
                      _logOdometerReading.execute(bundle.odometerReadings[i]),
                ),
          ]
          ..sort((a, b) {
            final byTime = a.at.compareTo(b.at);
            return byTime != 0 ? byTime : a.odometer.compareTo(b.odometer);
          });
    for (final record in records) {
      _abortOnLeft(await record.write(), record.where, record.vehicleId);
    }
  }

  /// Each run goes in the way a vehicle with no rollover does: fills in file
  /// order, then readings, a reading going with the last run that started at
  /// or before it. With [holdOverrides], override fills go after the
  /// readings, except the one that starts a later run, so a backdated one
  /// cannot sit in front of a reading saved before it.
  Future<void> _writeByRun(
    DataBundle bundle,
    Set<int> vehicleIds,
    bool holdOverrides,
  ) async {
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
            holdOverrides &&
            bundle.entries[i].odometerOverride &&
            (r == 0 ||
                !bundle.entries[i].filledAt.isAtSameMomentAs(starts[r - 1]));
        for (final i in fills.where((i) => !waits(i))) {
          _abortOnLeft(
            await _logRefuel.execute(bundle.entries[i]),
            'refuels[$i]',
            vehicleId,
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
            vehicleId,
          );
        }
        for (final i in fills.where(waits)) {
          _abortOnLeft(
            await _logRefuel.execute(bundle.entries[i]),
            'refuels[$i]',
            vehicleId,
          );
        }
      }
    }
  }

  /// The vehicle's fills and readings in the order they were saved. The rows
  /// are written only through [_logRefuel] and [_logOdometerReading].
  Future<void> _writeSaved(DataBundle bundle, int vehicleId) async {
    final fills = [
      for (var i = 0; i < bundle.entries.length; i++)
        if (bundle.entries[i].vehicleId == vehicleId) i,
    ]..sort((a, b) => bundle.entries[a].id.compareTo(bundle.entries[b].id));
    final readings =
        [
          for (var i = 0; i < bundle.odometerReadings.length; i++)
            if (bundle.odometerReadings[i].vehicleId == vehicleId) i,
        ]..sort(
          (a, b) => bundle.odometerReadings[a].id.compareTo(
            bundle.odometerReadings[b].id,
          ),
        );
    // With no fitting interleaving, fills then readings: the writes below
    // refuse the vehicle with a located error.
    final path =
        await _savedOrder(
          [
            for (final i in fills)
              OdometerSequenceValidator.refuelPoint(bundle.entries[i]),
          ],
          [for (final i in fills) bundle.entries[i].odometerOverride],
          [
            for (final i in readings)
              OdometerSequenceValidator.readingPoint(
                bundle.odometerReadings[i],
              ),
          ],
        ) ??
        [for (final _ in fills) true, for (final _ in readings) false];
    var f = 0;
    var r = 0;
    for (final isFill in path) {
      if (isFill) {
        final i = fills[f++];
        _abortOnLeft(
          await _logRefuel.execute(bundle.entries[i]),
          'refuels[$i]',
          vehicleId,
        );
      } else {
        final i = readings[r++];
        _abortOnLeft(
          await _logOdometerReading.execute(bundle.odometerReadings[i]),
          'odometerReadings[$i]',
          vehicleId,
        );
      }
    }
  }

  /// Ids only grow, so a vehicle's fills by id and its readings by id are each
  /// in the order they were saved. Only how the two lists interleave is
  /// unknown. This finds an interleaving in which every checked row fits the
  /// rows before it, the same check [LogRefuel] and [LogOdometerReading] run;
  /// an override fill is never checked. The path holds true for a fill and
  /// false for a reading, or is null when none fits. It runs on its own
  /// isolate because it can take seconds on a large file.
  static Future<List<bool>?> _savedOrder(
    List<OdometerPoint> fills,
    List<bool> overrides,
    List<OdometerPoint> readings,
  ) => Isolate.run(() {
    final placed = <OdometerPoint>[];
    final path = <bool>[];
    final dead = <int>{};
    bool fits(OdometerPoint point) =>
        OdometerSequenceValidator.check(point, placed) == null;
    // An explicit stack instead of recursion, so a long history cannot
    // overflow the call stack. [tried] counts the moves already made from the
    // current state (0 none, 1 the fill, 2 the reading); [resume] holds it for
    // each state on the path.
    var f = 0;
    var r = 0;
    var tried = 0;
    final resume = <int>[];
    while (true) {
      if (f == fills.length && r == readings.length) return path;
      final isDead = tried == 0 && !dead.add(f * (readings.length + 1) + r);
      if (!isDead) {
        if (tried == 0) {
          tried = 1;
          if (f < fills.length && (overrides[f] || fits(fills[f]))) {
            placed.add(fills[f++]);
            path.add(true);
            resume.add(tried);
            tried = 0;
            continue;
          }
        }
        if (tried == 1) {
          tried = 2;
          if (r < readings.length && fits(readings[r])) {
            placed.add(readings[r++]);
            path.add(false);
            resume.add(tried);
            tried = 0;
            continue;
          }
        }
      }
      if (path.isEmpty) return null;
      if (path.removeLast()) {
        f--;
      } else {
        r--;
      }
      placed.removeLast();
      tried = resume.removeLast();
    }
  });

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
  static void _abortOnLeft(
    Result<Object?> result,
    String where, [
    int? vehicleId,
  ]) {
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      throw _ImportAborted(_locate(failure, where), vehicleId);
    }
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

  /// A fill or reading in the bundle whose id is already stored, under any
  /// vehicle: the id is the table key, so the insert would clash. The odometer
  /// check can refuse the file first, so this is caught before any try. A read
  /// that fails is returned as it is.
  Future<Failure?> _findStoredItem(
    DataBundle bundle,
    Set<int> vehicleIds,
  ) async {
    final fillIds = <int>{};
    final readingIds = <int>{};
    for (final vehicleId in vehicleIds) {
      final fills = await _refuelRepository.getForVehicle(vehicleId);
      final fillsFailure = fills.getLeft().toNullable();
      if (fillsFailure != null) return fillsFailure;
      fillIds.addAll(fills.getRight().toNullable()!.map((e) => e.id));
      final readings = await _readingRepository.getForVehicle(vehicleId);
      final readingsFailure = readings.getLeft().toNullable();
      if (readingsFailure != null) return readingsFailure;
      readingIds.addAll(readings.getRight().toNullable()!.map((r) => r.id));
    }
    if (bundle.entries.any((e) => fillIds.contains(e.id)) ||
        bundle.odometerReadings.any((r) => readingIds.contains(r.id))) {
      return const DuplicateIdFailure(_duplicateIdMessage);
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

/// Carries a located [Failure] out of the unit of work body, with the vehicle
/// whose row raised it. A row that does not depend on order has none.
class _ImportAborted implements Exception {
  const _ImportAborted(this.failure, [this.vehicleId]);

  final Failure failure;
  final int? vehicleId;
}
