import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../entities/refuel_entry.dart';
import '../repositories/refuel_repository.dart';
import '../validators/odometer_sequence_validator.dart';
import '../validators/text_input_validator.dart';

class LogRefuel {
  const LogRefuel(this._repository);

  final RefuelRepository _repository;

  Future<Result<RefuelEntry>> execute(RefuelEntry entry) async {
    if (entry.quantity <= 0) {
      return left(
        const ValidationFailure(
          field: 'quantity',
          reason: 'Quantity must be greater than zero.',
        ),
      );
    }
    if (entry.pricePaid <= 0) {
      return left(
        const ValidationFailure(
          field: 'price',
          reason: 'Price must be greater than zero.',
        ),
      );
    }
    if (entry.filledAt.isAfter(DateTime.now())) {
      return left(
        const ValidationFailure(
          field: 'filledAt',
          reason: 'Date cannot be in the future.',
        ),
      );
    }
    final stationName = entry.stationName;
    if (stationName != null) {
      final issue = TextInputValidator.check(stationName);
      if (issue != null) {
        return left(ValidationFailure(field: 'stationName', reason: issue));
      }
    }
    final notes = entry.notes;
    if (notes != null) {
      final issue = TextInputValidator.check(notes);
      if (issue != null) {
        return left(ValidationFailure(field: 'notes', reason: issue));
      }
    }

    if (entry.odometerOverride) {
      return _repository.add(entry);
    }

    final existing = await _repository.getForVehicle(entry.vehicleId);
    return existing.match(
      (failure) => Future<Result<RefuelEntry>>.value(left(failure)),
      (entries) {
        final issue = OdometerSequenceValidator.check(entry, entries);
        if (issue != null) {
          return Future<Result<RefuelEntry>>.value(left(issue));
        }
        return _repository.add(entry);
      },
    );
  }
}
