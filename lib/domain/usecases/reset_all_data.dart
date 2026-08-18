import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../backup/data_eraser.dart';
import '../reminders/reminder_scheduler.dart';

/// Erases every vehicle and everything logged against it, then cancels every
/// scheduled reminder. A failed erase leaves the reminders untouched.
class ResetAllData {
  const ResetAllData(this._eraser, this._scheduler);

  final DataEraser _eraser;
  final ReminderScheduler _scheduler;

  Future<Result<Unit>> execute() async {
    final erased = await _eraser.eraseAll();
    return erased.match(
      (failure) => Future<Result<Unit>>.value(left(failure)),
      (_) async {
        await _scheduler.cancelAll();
        return right(unit);
      },
    );
  }
}
