import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../entities/service_log_entry.dart';

abstract class ServiceLogRepository {
  /// Entries for a vehicle, in no particular order; callers sort as needed.
  Future<Result<List<ServiceLogEntry>>> getForVehicle(int vehicleId);
  Future<Result<ServiceLogEntry>> add(ServiceLogEntry entry);
  Future<Result<Unit>> delete(int id);
}
