import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/repositories/service_log_repository.dart';

/// In-memory [ServiceLogRepository] for use case tests. Entries with id 0 are
/// treated as unsaved and get an assigned id on add, mimicking SQLite.
class FakeServiceLogRepository implements ServiceLogRepository {
  FakeServiceLogRepository([List<ServiceLogEntry> seed = const []]) {
    _entries.addAll(seed);
    for (final entry in seed) {
      if (entry.id >= _nextId) _nextId = entry.id + 1;
    }
  }

  final List<ServiceLogEntry> _entries = [];
  int _nextId = 1;

  List<ServiceLogEntry> get entries => List.unmodifiable(_entries);

  @override
  Future<Result<ServiceLogEntry>> add(ServiceLogEntry entry) async {
    final stored = entry.id == 0 ? entry.copyWith(id: _nextId++) : entry;
    _entries.add(stored);
    return right(stored);
  }

  @override
  Future<Result<Unit>> delete(int id) async {
    _entries.removeWhere((e) => e.id == id);
    return right(unit);
  }

  @override
  Future<Result<List<ServiceLogEntry>>> getForVehicle(int vehicleId) async {
    return right(_entries.where((e) => e.vehicleId == vehicleId).toList());
  }
}
