import '../../core/typedefs.dart';
import '../entities/odometer_reading.dart';
import '../repositories/odometer_reading_repository.dart';

/// Puts a deleted odometer reading back at its original id, for the undo
/// action on the delete snack bar. No validation: the reading was valid when
/// it was saved.
class RestoreOdometerReading {
  const RestoreOdometerReading(this._repository);

  final OdometerReadingRepository _repository;

  Future<Result<OdometerReading>> execute(OdometerReading reading) =>
      _repository.add(reading);
}
