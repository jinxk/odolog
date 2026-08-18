import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/domain/usecases/reset_all_data.dart';

import '../../helpers/fake_data_eraser.dart';
import '../../helpers/fake_reminder_scheduler.dart';

void main() {
  test('a successful erase cancels every reminder', () async {
    final eraser = FakeDataEraser();
    final scheduler = FakeReminderScheduler();

    final result = await ResetAllData(eraser, scheduler).execute();

    expect(result.isRight(), isTrue);
    expect(eraser.erased, isTrue);
    expect(scheduler.cancelledAll, isTrue);
  });

  test('a failed erase leaves the reminders alone', () async {
    final eraser = FakeDataEraser(failure: const DatabaseFailure('locked'));
    final scheduler = FakeReminderScheduler();

    final result = await ResetAllData(eraser, scheduler).execute();

    final failure = result.getLeft().toNullable()! as DatabaseFailure;
    expect(failure.message, 'locked');
    expect(eraser.erased, isTrue);
    expect(scheduler.cancelledAll, isFalse);
  });
}
