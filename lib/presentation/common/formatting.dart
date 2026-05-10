import 'package:intl/intl.dart';

import '../../domain/entities/vehicle.dart';

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
