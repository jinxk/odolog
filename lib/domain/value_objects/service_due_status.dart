import 'package:equatable/equatable.dart';

import '../entities/service_log_entry.dart';

/// Where one maintenance template stands right now: how far off it is by
/// distance, by time, and whether it has tipped into overdue. Either figure
/// can be null when its dimension does not apply to the template or there is
/// not enough history yet to compute it.
class ServiceDueStatus extends Equatable {
  const ServiceDueStatus({
    required this.template,
    this.remainingKm,
    this.remainingDays,
    this.projectedDueDate,
    required this.overdue,
  });

  final ServiceTemplate template;

  /// Km left before the interval is up, negative once overdue. Null when the
  /// template has no distance dimension or the vehicle has no refuel history
  /// to measure from.
  final double? remainingKm;

  /// Days left before the interval is up, negative once overdue. Null when
  /// the template has no date dimension or there is no baseline date yet.
  final int? remainingDays;

  /// The calendar date the reminder should fire on: the date dimension's due
  /// date directly, or, for a distance-only template, that distance projected
  /// onto a date using the vehicle's recent pace. Null when neither dimension
  /// yields a date, in which case no notification is scheduled even though
  /// [remainingKm] may still be shown in the UI as a countdown.
  final DateTime? projectedDueDate;

  /// True once either dimension has crossed zero: whichever comes first wins.
  final bool overdue;

  @override
  List<Object?> get props => [
    template,
    remainingKm,
    remainingDays,
    projectedDueDate,
    overdue,
  ];
}
