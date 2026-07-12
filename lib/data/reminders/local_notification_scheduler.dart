/// The Android implementation of the [ReminderScheduler] port, over
/// flutter_local_notifications. It schedules zoned notifications ahead of each
/// document expiry and reconciles the whole set on every sync. Everything here
/// is best effort and Android only: on any other platform, or when the plugin
/// or permission is unavailable, it quietly does nothing so the rest of the app
/// is unaffected. Reboot survival is handled by the plugin's boot receiver,
/// declared in the Android manifest, which reschedules on BOOT_COMPLETED.
library;

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/calculators/document_reminder_planner.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/reminders/reminder_scheduler.dart';
import '../../domain/value_objects/document_reminder.dart';

class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler();

  static const _channelId = 'document_expiry';
  static const _channelName = 'Document expiry reminders';
  static const _channelDescription =
      'Reminders before insurance, PUC, RC, and fitness expire.';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  @override
  Future<void> sync(List<DocumentReminder> reminders) async {
    // The whole feature is Android only for now, and the host test platform is
    // not Android, so this short circuit also keeps widget tests from touching
    // the plugin channel.
    if (!Platform.isAndroid) return;
    try {
      await _ensureReady();
      // Full reconcile: clear everything, then lay down the current set. The
      // reminders are all future scheduled, so cancelling first cannot drop a
      // notification the user is looking at.
      await _plugin.cancelAll();
      for (final reminder in reminders) {
        await _schedule(reminder);
      }
    } catch (_) {
      // Best effort by contract: a denied permission or a device without
      // scheduling support must not break saving a vehicle.
    }
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    tz.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> _schedule(DocumentReminder reminder) {
    final noun = _noun(reminder.document);
    final unit = reminder.daysBefore == 1 ? 'day' : 'days';
    final when = DateFormat('d MMM yyyy').format(reminder.expiry);
    return _plugin.zonedSchedule(
      id: _idFor(reminder),
      title:
          '${reminder.vehicleName} $noun expires in '
          '${reminder.daysBefore} $unit',
      body: 'Renew before $when to avoid a fine.',
      scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // Inexact is deliberate: a day granular reminder does not need an exact
      // alarm, and asking for one triggers the Android 14 exact alarm
      // permission prompt for no real benefit.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// A stable notification id per (vehicle, document, lead time) so a reschedule
  /// overwrites the same slot rather than stacking duplicates. The lead time is
  /// folded in by its position in the planner's ordering to keep ids in a
  /// small, dense range; collision free for any realistic vehicle count.
  int _idFor(DocumentReminder reminder) {
    final lead = DocumentReminderPlanner.leadDays.indexOf(reminder.daysBefore);
    return reminder.vehicleId * 100 +
        reminder.document.index * 10 +
        (lead < 0 ? 0 : lead);
  }

  String _noun(VehicleDocument document) => switch (document) {
    VehicleDocument.insurance => 'insurance',
    VehicleDocument.puc => 'PUC',
    VehicleDocument.rc => 'RC',
    VehicleDocument.fitness => 'fitness',
  };
}
