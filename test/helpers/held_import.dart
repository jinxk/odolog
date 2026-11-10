import 'dart:async';

import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/backup/data_bundle.dart';
import 'package:odolog/domain/usecases/import_data.dart';

/// An import that stays running until the test completes [result], so a
/// screen can be checked while the import is in progress.
class HeldImport implements ImportData {
  final result = Completer<Result<DataBundle>>();

  @override
  Future<Result<DataBundle>> execute(String content) => result.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
