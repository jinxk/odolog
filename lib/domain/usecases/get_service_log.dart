import '../../core/typedefs.dart';
import '../entities/service_log_entry.dart';
import '../repositories/service_log_repository.dart';

class GetServiceLog {
  const GetServiceLog(this._repository);

  final ServiceLogRepository _repository;

  /// The vehicle's service history, most recent first.
  Future<Result<List<ServiceLogEntry>>> execute(int vehicleId) async {
    final result = await _repository.getForVehicle(vehicleId);
    return result.map((entries) {
      final sorted = List<ServiceLogEntry>.of(entries)
        ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
      return sorted;
    });
  }
}
