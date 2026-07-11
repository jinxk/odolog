import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../entities/refuel_entry.dart';

abstract class RefuelRepository {
  /// Entries for a vehicle ordered by odometer, then by [RefuelEntry.filledAt].
  Future<Result<List<RefuelEntry>>> getForVehicle(int vehicleId);
  Future<Result<RefuelEntry>> getById(int id);
  Future<Result<RefuelEntry>> add(RefuelEntry entry);
  Future<Result<RefuelEntry>> update(RefuelEntry entry);
  Future<Result<Unit>> delete(int id);
}
