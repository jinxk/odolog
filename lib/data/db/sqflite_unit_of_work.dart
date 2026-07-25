import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../domain/backup/unit_of_work.dart';
import 'transaction_zone.dart';

/// [UnitOfWork] over a sqflite transaction. The transaction executor is put in
/// a zone value for the length of the body so every DAO called underneath picks
/// it up; see [currentExecutor].
class SqfliteUnitOfWork implements UnitOfWork {
  const SqfliteUnitOfWork(this._db);

  final Database _db;

  @override
  Future<T> run<T>(Future<T> Function() body) {
    return _db.transaction(
      (txn) => runZoned(body, zoneValues: {transactionExecutorKey: txn}),
    );
  }
}
