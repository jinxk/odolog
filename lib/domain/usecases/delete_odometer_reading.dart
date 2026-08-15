import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../repositories/odometer_reading_repository.dart';

class DeleteOdometerReading {
  const DeleteOdometerReading(this._repository);

  final OdometerReadingRepository _repository;

  Future<Result<Unit>> execute(int id) => _repository.delete(id);
}
