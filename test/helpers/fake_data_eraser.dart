import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/backup/data_eraser.dart';

/// In-memory [DataEraser] for tests. Records whether [eraseAll] ran and
/// returns [failure] instead when one is set.
class FakeDataEraser implements DataEraser {
  FakeDataEraser({this.failure});

  final Failure? failure;
  bool erased = false;

  @override
  Future<Result<Unit>> eraseAll() async {
    erased = true;
    final failure = this.failure;
    return failure == null ? right(unit) : left(failure);
  }
}
