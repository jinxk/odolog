import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/repositories/vehicle_repository.dart';

/// In-memory [VehicleRepository] for use case tests. Vehicles with id 0 are
/// treated as unsaved and get an assigned id on add.
class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository([List<Vehicle> seed = const []]) {
    _vehicles.addAll(seed);
    for (final vehicle in seed) {
      if (vehicle.id >= _nextId) _nextId = vehicle.id + 1;
    }
  }

  final List<Vehicle> _vehicles = [];
  int _nextId = 1;

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);

  @override
  Future<Result<Vehicle>> add(Vehicle vehicle) async {
    final stored = vehicle.id == 0 ? vehicle.copyWith(id: _nextId++) : vehicle;
    _vehicles.add(stored);
    return right(stored);
  }

  @override
  Future<Result<Unit>> delete(int id) async {
    _vehicles.removeWhere((v) => v.id == id);
    return right(unit);
  }

  @override
  Future<Result<List<Vehicle>>> getAll() async => right(List.of(_vehicles));

  @override
  Future<Result<Vehicle>> getById(int id) async {
    final matches = _vehicles.where((v) => v.id == id).toList();
    return matches.isEmpty
        ? left(const NotFoundFailure('Vehicle does not exist.'))
        : right(matches.first);
  }

  @override
  Future<Result<Vehicle>> update(Vehicle vehicle) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index == -1) {
      return left(const NotFoundFailure('Vehicle does not exist.'));
    }
    _vehicles[index] = vehicle;
    return right(vehicle);
  }
}
