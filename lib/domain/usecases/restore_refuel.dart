import '../../core/typedefs.dart';
import '../entities/refuel_entry.dart';
import '../repositories/refuel_repository.dart';

/// Puts a deleted fill back at its original id, for the undo action on the
/// delete snack bar. No validation: the entry was valid when it was saved.
class RestoreRefuel {
  const RestoreRefuel(this._repository);

  final RefuelRepository _repository;

  Future<Result<RefuelEntry>> execute(RefuelEntry entry) =>
      _repository.add(entry);
}
