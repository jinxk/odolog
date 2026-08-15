import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/repositories/odometer_reading_repository.dart';

/// In-memory [OdometerReadingRepository] for use case tests. Readings with id
/// 0 are treated as unsaved and get an assigned id on add, mimicking SQLite.
class FakeOdometerReadingRepository implements OdometerReadingRepository {
  FakeOdometerReadingRepository([List<OdometerReading> seed = const []]) {
    _readings.addAll(seed);
    for (final reading in seed) {
      if (reading.id >= _nextId) _nextId = reading.id + 1;
    }
  }

  final List<OdometerReading> _readings = [];
  int _nextId = 1;

  /// When set, [add] returns this instead of storing the reading, so a caller
  /// can be tested against a write that fails.
  Failure? failOnAdd;

  List<OdometerReading> get readings => List.unmodifiable(_readings);

  @override
  Future<Result<OdometerReading>> add(OdometerReading reading) async {
    if (failOnAdd != null) return left(failOnAdd!);
    final stored = reading.id == 0 ? reading.copyWith(id: _nextId++) : reading;
    _readings.add(stored);
    return right(stored);
  }

  @override
  Future<Result<Unit>> delete(int id) async {
    _readings.removeWhere((r) => r.id == id);
    return right(unit);
  }

  @override
  Future<Result<List<OdometerReading>>> getForVehicle(int vehicleId) async {
    final list = _readings.where((r) => r.vehicleId == vehicleId).toList()
      ..sort((a, b) {
        final byOdometer = a.odometer.compareTo(b.odometer);
        return byOdometer != 0
            ? byOdometer
            : a.recordedAt.compareTo(b.recordedAt);
      });
    return right(list);
  }
}
