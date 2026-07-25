import 'dart:async';

import 'package:sqflite/sqflite.dart';

/// Zone key under which a running transaction parks its executor.
const Object transactionExecutorKey = #odologTransactionExecutor;

/// The executor to use for one statement: the transaction in flight when there
/// is one, otherwise [db]. sqflite deadlocks if the outer database is touched
/// while a transaction is open, and the DAOs are long lived singletons built
/// once around that database, so the transaction travels in a zone value rather
/// than through a second set of DAOs.
DatabaseExecutor currentExecutor(DatabaseExecutor db) =>
    Zone.current[transactionExecutorKey] as DatabaseExecutor? ?? db;
