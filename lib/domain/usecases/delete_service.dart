import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../repositories/service_log_repository.dart';

class DeleteService {
  const DeleteService(this._repository);

  final ServiceLogRepository _repository;

  Future<Result<Unit>> execute(int id) => _repository.delete(id);
}
