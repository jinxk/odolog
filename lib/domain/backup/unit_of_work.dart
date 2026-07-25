/// Port for running several writes as one unit: [run] executes [body] and
/// commits what it wrote, and anything thrown inside it discards the lot before
/// reaching the caller. Restoring a backup goes through this so a bundle that
/// fails on its fortieth row does not leave the first thirty-nine behind.
abstract interface class UnitOfWork {
  /// Runs [body] and returns its value once the work is committed.
  Future<T> run<T>(Future<T> Function() body);
}
