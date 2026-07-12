/// The Android implementation of the [ReminderScheduler] port, over
/// flutter_local_notifications. It schedules zoned notifications ahead of each
/// document expiry and each service due date, and reconciles each category
/// independently on its own sync call. Everything here is best effort and
/// Android only: on any other platform, or when the plugin or permission is
/// unavailable, it quietly does nothing so the rest of the app is unaffected.
/// Reboot survival is handled by the plugin's boot receiver, declared in the
/// Android manifest, which reschedules on BOOT_COMPLETED.
library;

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/calculators/document_reminder_planner.dart';
import '../../domain/entities/service_log_entry.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/reminders/reminder_scheduler.dart';
import '../../domain/value_objects/document_reminder.dart';
import '../../domain/value_objects/service_reminder.dart';

class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler();

  static const _documentChannelId = 'document_expiry';
  static const _documentChannelName = 'Document expiry reminders';
  static const _documentChannelDescription =
      'Reminders before insurance, PUC, RC, and fitness expire.';

  static const _serviceChannelId = 'service_due';
  static const _serviceChannelName = 'Service due reminders';
  static const _serviceChannelDescription =
      'Reminders when engine oil or a general service comes due.';

  /// Service reminder ids start above every id [_documentIdFor] can produce
  /// for a realistic vehicle count, so the two categories can be cancelled and
  /// rescheduled independently without a blanket cancelAll clobbering the
  /// other one.
  static const _serviceIdOffset = 1000000;

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
      await _cancelWhere((id) => id < _serviceIdOffset);
      for (final reminder in reminders) {
        await _scheduleDocument(reminder);
      }
    } catch (_) {
      // Best effort by contract: a denied permission or a device without
      // scheduling support must not break saving a vehicle.
    }
  }

  @override
  Future<void> syncServiceReminders(List<ServiceReminder> reminders) async {
    if (!Platform.isAndroid) return;
    try {
      await _ensureReady();
      await _cancelWhere((id) => id >= _serviceIdOffset);
      for (final reminder in reminders) {
        await _scheduleService(reminder);
      }
    } catch (_) {
      // Best effort, same contract as sync.
    }
  }

  /// Cancels only the currently scheduled notifications whose id [matches],
  /// so reconciling one category (document expiries or service due dates)
  /// leaves the other alone. The reminders in a category are all future
  /// scheduled, so cancelling first cannot drop a notification the user is
  /// looking at.
  Future<void> _cancelWhere(bool Function(int id) matches) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (matches(request.id)) {
        await _plugin.cancel(id: request.id);
      }
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

  Future<void> _scheduleDocument(DocumentReminder reminder) {
    final noun = _noun(reminder.document);
    final unit = reminder.daysBefore == 1 ? 'day' : 'days';
    final when = DateFormat('d MMM yyyy').format(reminder.expiry);
    return _plugin.zonedSchedule(
      id: _documentIdFor(reminder),
      title:
          '${reminder.vehicleName} $noun expires in '
          '${reminder.daysBefore} $unit',
      body: 'Renew before $when to avoid a fine.',
      scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _documentChannelId,
          _documentChannelName,
          channelDescription: _documentChannelDescription,
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

  Future<void> _scheduleService(ServiceReminder reminder) {
    return _plugin.zonedSchedule(
      id: _serviceIdFor(reminder),
      title:
          '${reminder.vehicleName}: ${_templateNoun(reminder.template)} is due',
      body: 'Log it once it is done to reset this reminder.',
      scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _serviceChannelId,
          _serviceChannelName,
          channelDescription: _serviceChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// A stable notification id per (vehicle, document, lead time) so a reschedule
  /// overwrites the same slot rather than stacking duplicates. The lead time is
  /// folded in by its position in the planner's ordering to keep ids in a
  /// small, dense range; collision free for any realistic vehicle count.
  int _documentIdFor(DocumentReminder reminder) {
    final lead = DocumentReminderPlanner.leadDays.indexOf(reminder.daysBefore);
    return reminder.vehicleId * 100 +
        reminder.document.index * 10 +
        (lead < 0 ? 0 : lead);
  }

  /// A stable notification id per (vehicle, template) above [_serviceIdOffset],
  /// so it can never collide with a document reminder id.
  int _serviceIdFor(ServiceReminder reminder) =>
      _serviceIdOffset + reminder.vehicleId * 10 + reminder.template.index;

  String _noun(VehicleDocument document) => switch (document) {
    VehicleDocument.insurance => 'insurance',
    VehicleDocument.puc => 'PUC',
    VehicleDocument.rc => 'RC',
    VehicleDocument.fitness => 'fitness',
  };

  String _templateNoun(ServiceTemplate template) => switch (template) {
    ServiceTemplate.engineOil => 'engine oil',
    ServiceTemplate.generalService => 'general service',
  };
}
