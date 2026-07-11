import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../entities/refuel_entry.dart';
import '../repositories/refuel_repository.dart';

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

    if (entry.odometerOverride) {
      return _repository.add(entry);
    }

    final existing = await _repository.getForVehicle(entry.vehicleId);
    return existing.match(
      (failure) => Future<Result<RefuelEntry>>.value(left(failure)),
      (entries) {
        if (entries.isNotEmpty && entry.odometer <= entries.last.odometer) {
          return Future<Result<RefuelEntry>>.value(
            left(
              const ValidationFailure(
                field: 'odometer',
                reason: 'Odometer must be greater than the previous reading.',
              ),
            ),
          );
        }
        return _repository.add(entry);
      },
    );
  }
}
