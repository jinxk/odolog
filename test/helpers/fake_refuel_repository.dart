import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/repositories/refuel_repository.dart';

/// In-memory [RefuelRepository] for use case tests. Entries with id 0 are
/// treated as unsaved and get an assigned id on add, mimicking SQLite.
class FakeRefuelRepository implements RefuelRepository {
  FakeRefuelRepository([List<RefuelEntry> seed = const []]) {
    _entries.addAll(seed);
    for (final entry in seed) {
      if (entry.id >= _nextId) _nextId = entry.id + 1;
    }
  }

  final List<RefuelEntry> _entries = [];
  int _nextId = 1;

  List<RefuelEntry> get entries => List.unmodifiable(_entries);

  @override
  Future<Result<RefuelEntry>> add(RefuelEntry entry) async {
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
  Future<Result<RefuelEntry>> getById(int id) async {
    final matches = _entries.where((e) => e.id == id).toList();
    return matches.isEmpty
        ? left(const NotFoundFailure('Entry does not exist.'))
        : right(matches.first);
  }

  @override
  Future<Result<List<RefuelEntry>>> getForVehicle(int vehicleId) async {
    final list = _entries.where((e) => e.vehicleId == vehicleId).toList()
      ..sort((a, b) {
        final byOdometer = a.odometer.compareTo(b.odometer);
        return byOdometer != 0 ? byOdometer : a.filledAt.compareTo(b.filledAt);
      });
    return right(list);
  }

  @override
  Future<Result<RefuelEntry>> update(RefuelEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      return left(const NotFoundFailure('Entry does not exist.'));
    }
    _entries[index] = entry;
    return right(entry);
  }
}
