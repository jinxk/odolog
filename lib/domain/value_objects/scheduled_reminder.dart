import 'package:equatable/equatable.dart';

/// Which planner produced a reminder. The settings screen switches the two
/// categories independently, so a row has to say which one it belongs to.
enum ReminderCategory { document, service }

/// One reminder that is currently scheduled on the device, flattened for
/// display. [DocumentReminder] and [ServiceReminder] carry the fields their
/// own planners need; this is the single shape a list can render.
class ScheduledReminder extends Equatable {
  const ScheduledReminder({
    required this.category,
    required this.title,
    required this.vehicleName,
    required this.fireAt,
  });

  final ReminderCategory category;

  /// What the reminder is about, for example "Insurance expiry" or
  /// "General service". The vehicle is not folded in: it stays in
  /// [vehicleName] so a caller can lay the two out as it likes.
  final String title;

  final String vehicleName;

  /// Local wall-clock instant the reminder fires at.
  final DateTime fireAt;

  @override
  List<Object?> get props => [category, title, vehicleName, fireAt];
}
