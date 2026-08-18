import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';

/// Port for permanently deleting everything OdoLog has stored: every
/// vehicle, refuel, service entry, expense, and odometer reading. The delete
/// all data feature is the only caller.
abstract class DataEraser {
  Future<Result<Unit>> eraseAll();
}
