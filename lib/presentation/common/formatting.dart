import 'package:intl/intl.dart';

import '../../domain/entities/service_log_entry.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/value_objects/service_due_status.dart';

/// Shared display formatting. Kept in one place so every screen shows the same
/// number of decimals and the same units, and so the fuel unit always follows
/// the vehicle's category rather than being set by hand.

/// The quantity unit label for a category: kg for CNG, L otherwise.
String unitLabel(FuelCategory category) => category.unit == 'kg' ? 'kg' : 'L';

/// The mileage unit label for a category: km/kg for CNG, km/l otherwise.
String mileageUnit(FuelCategory category) =>
    category.unit == 'kg' ? 'km/kg' : 'km/l';

/// The price per unit label, for example "/L" or "/kg".
String perUnitLabel(FuelCategory category) => '/${unitLabel(category)}';

String formatMileage(double value) => value.toStringAsFixed(1);

String formatQuantity(double value) => value.toStringAsFixed(2);

String formatDistance(double value) =>
    '${NumberFormat.decimalPattern().format(value.round())} km';

String formatMoney(double value, String symbol) =>
    '$symbol ${value.toStringAsFixed(2)}';

String formatMoneyPerKm(double value, String symbol) =>
    '$symbol ${value.toStringAsFixed(2)} /km';

String formatDate(DateTime when) => DateFormat('d MMM yyyy').format(when);

String formatDateTime(DateTime when) =>
    DateFormat('d MMM yyyy, h:mm a').format(when);

String formatMonth(DateTime month) => DateFormat('MMMM yyyy').format(month);

String vehicleTypeLabel(VehicleType type) => switch (type) {
  VehicleType.car => 'Car',
  VehicleType.motorcycle => 'Motorcycle',
  VehicleType.scooter => 'Scooter',
  VehicleType.other => 'Other',
};

String fuelCategoryLabel(FuelCategory category) => switch (category) {
  FuelCategory.petrol => 'Petrol',
  FuelCategory.diesel => 'Diesel',
  FuelCategory.cng => 'CNG',
  FuelCategory.lpg => 'LPG',
};

/// The short display name for a vehicle document, used in the form section and
/// the dashboard glance. Acronyms stay uppercased.
String documentLabel(VehicleDocument document) => switch (document) {
  VehicleDocument.insurance => 'Insurance',
  VehicleDocument.puc => 'PUC',
  VehicleDocument.rc => 'RC',
  VehicleDocument.fitness => 'Fitness',
};

String serviceTemplateLabel(ServiceTemplate template) => switch (template) {
  ServiceTemplate.engineOil => 'Engine oil',
  ServiceTemplate.generalService => 'General service',
};

/// A one-line countdown for one maintenance template, for example "Engine oil
/// due in about 180 km" or "General service overdue by 12 days". A template
/// whose distance dimension applies is read by distance; otherwise its date
/// dimension is read by days. Falls back to a plain "not enough data yet"
/// once a vehicle has no refuel history to measure against.
String serviceDueSummary(ServiceDueStatus status) {
  final label = serviceTemplateLabel(status.template);
  final km = status.remainingKm;
  if (km != null) {
    final whole = km.abs().round();
    return km > 0
        ? '$label due in about $whole km'
        : '$label overdue by $whole km';
  }
  final days = status.remainingDays;
  if (days != null) {
    if (days == 0) return '$label due today';
    final whole = days.abs();
    final unit = whole == 1 ? 'day' : 'days';
    return days > 0
        ? '$label due in about $whole $unit'
        : '$label overdue by $whole $unit';
  }
  return '$label: not enough data yet';
}
