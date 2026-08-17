import '../../core/typedefs.dart';
import '../entities/service_log_entry.dart';
import '../repositories/service_log_repository.dart';

/// Puts a deleted service log entry back at its original id, for the undo
/// action on the delete snack bar. No validation: the entry was valid when
/// it was saved.
class RestoreServiceEntry {
  const RestoreServiceEntry(this._repository);

  final ServiceLogRepository _repository;

  Future<Result<ServiceLogEntry>> execute(ServiceLogEntry entry) =>
      _repository.add(entry);
}
