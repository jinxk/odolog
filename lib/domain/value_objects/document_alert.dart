import 'package:equatable/equatable.dart';

import '../entities/vehicle.dart';

/// The single most urgent document expiry worth surfacing on a glance element:
/// which document, when it lapses, and how many days remain. Produced only when
/// something is close enough (or already past) to be worth showing.
class DocumentAlert extends Equatable {
  const DocumentAlert({
    required this.document,
    required this.expiry,
    required this.daysRemaining,
  });

  final VehicleDocument document;

  /// The date the document lapses.
  final DateTime expiry;

  /// Whole calendar days from today until [expiry]. Zero means it lapses today;
  /// a negative value means it lapsed that many days ago.
  final int daysRemaining;

  /// Whether the document has already lapsed.
  bool get overdue => daysRemaining < 0;

  @override
  List<Object?> get props => [document, expiry, daysRemaining];
}
