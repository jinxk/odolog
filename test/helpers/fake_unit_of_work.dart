import 'package:odolog/domain/backup/unit_of_work.dart';

/// A [UnitOfWork] with no database behind it: it runs the body and records
/// whether the body threw, which is what a real implementation would roll back
/// on.
class FakeUnitOfWork implements UnitOfWork {
  bool ran = false;
  bool rolledBack = false;

  @override
  Future<T> run<T>(Future<T> Function() body) async {
    ran = true;
    try {
      return await body();
    } catch (_) {
      rolledBack = true;
      rethrow;
    }
  }
}
