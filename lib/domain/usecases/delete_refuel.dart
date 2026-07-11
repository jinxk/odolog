import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../repositories/refuel_repository.dart';

class DeleteRefuel {
  const DeleteRefuel(this._repository);

  final RefuelRepository _repository;

  Future<Result<Unit>> execute(int id) => _repository.delete(id);
}
