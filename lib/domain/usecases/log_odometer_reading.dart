import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../entities/odometer_reading.dart';
import '../repositories/odometer_reading_repository.dart';
import '../repositories/refuel_repository.dart';
import '../validators/odometer_sequence_validator.dart';
import '../validators/text_input_validator.dart';

/// Stores an odometer reading taken without a refuel. The sequence check looks
/// at the vehicle's fills as well as its earlier readings, since both sit on
/// the same line of travel.
class LogOdometerReading {
  const LogOdometerReading(this._repository, this._refuelRepository);

  final OdometerReadingRepository _repository;
  final RefuelRepository _refuelRepository;

  Future<Result<OdometerReading>> execute(OdometerReading reading) async {
    if (reading.odometer <= 0) {
      return left(
        const ValidationFailure(
          field: 'odometer',
          reason: 'Odometer must be greater than zero.',
        ),
      );
    }
    if (reading.recordedAt.isAfter(DateTime.now())) {
      return left(
        const ValidationFailure(
          field: 'recordedAt',
          reason: 'Date cannot be in the future.',
        ),
      );
    }
    final note = reading.note;
    if (note != null) {
      final issue = TextInputValidator.check(note);
      if (issue != null) {
        return left(ValidationFailure(field: 'note', reason: issue));
      }
    }

    final refuelsResult = await _refuelRepository.getForVehicle(
      reading.vehicleId,
    );
    final refuelsFailure = refuelsResult.getLeft().toNullable();
    if (refuelsFailure != null) return left(refuelsFailure);

    final readingsResult = await _repository.getForVehicle(reading.vehicleId);
    final readingsFailure = readingsResult.getLeft().toNullable();
    if (readingsFailure != null) return left(readingsFailure);

    final issue = OdometerSequenceValidator.check(
      OdometerSequenceValidator.readingPoint(reading),
      OdometerSequenceValidator.pointsOf(
        refuelsResult.getRight().toNullable()!,
        readingsResult.getRight().toNullable()!,
      ),
    );
    if (issue != null) return left(issue);
    return _repository.add(reading);
  }
}
