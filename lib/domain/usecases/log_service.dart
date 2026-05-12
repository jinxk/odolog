import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../entities/service_log_entry.dart';
import '../repositories/service_log_repository.dart';
import '../validators/text_input_validator.dart';

class LogService {
  const LogService(this._repository);

  final ServiceLogRepository _repository;

  Future<Result<ServiceLogEntry>> execute(ServiceLogEntry entry) async {
    if (entry.odometer <= 0) {
      return left(
        const ValidationFailure(
          field: 'odometer',
          reason: 'Odometer must be greater than zero.',
        ),
      );
    }
    if (entry.performedAt.isAfter(DateTime.now())) {
      return left(
        const ValidationFailure(
          field: 'performedAt',
          reason: 'Date cannot be in the future.',
        ),
      );
    }
    final cost = entry.cost;
    if (cost != null && cost < 0) {
      return left(
        const ValidationFailure(
          field: 'cost',
          reason: 'Cost cannot be negative.',
        ),
      );
    }
    final note = entry.note;
    if (note != null) {
      final issue = TextInputValidator.check(note);
      if (issue != null) {
        return left(ValidationFailure(field: 'note', reason: issue));
      }
    }
    return _repository.add(entry);
  }
}
