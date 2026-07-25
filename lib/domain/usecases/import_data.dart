import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../backup/data_bundle.dart';
import '../backup/data_bundle_codec.dart';
import '../backup/unit_of_work.dart';
import 'add_vehicle.dart';
import 'list_vehicles.dart';
import 'log_expense.dart';
import 'log_refuel.dart';
import 'log_service.dart';

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
    this._listVehicles,
    this._codec,
    this._unitOfWork,
  );

  final AddVehicle _addVehicle;
  final LogRefuel _logRefuel;
  final LogService _logService;
  final LogExpense _logExpense;
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

    try {
      await _unitOfWork.run(() => _write(bundle));
    } on _ImportAborted catch (aborted) {
      return left(aborted.failure);
    }
    return right(bundle);
  }

  Future<void> _write(DataBundle bundle) async {
    for (var i = 0; i < bundle.vehicles.length; i++) {
      final result = await _addVehicle.execute(bundle.vehicles[i]);
      _abortOnLeft(result, 'vehicles[$i]');
    }
    for (var i = 0; i < bundle.entries.length; i++) {
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
  /// convention the codec uses for a structural problem.
  static Failure _locate(Failure failure, String where) => switch (failure) {
    ValidationFailure() => ValidationFailure(
      field: failure.field,
      reason: '$where: ${failure.reason}',
    ),
    NotFoundFailure() => NotFoundFailure('$where: ${failure.message}'),
    DatabaseFailure() => DatabaseFailure('$where: ${failure.message}'),
  };
}

/// Carries a located [Failure] out of the unit of work body.
class _ImportAborted implements Exception {
  const _ImportAborted(this.failure);

  final Failure failure;
}
