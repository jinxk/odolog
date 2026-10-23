import '../../domain/backup/data_bundle.dart';

/// The snackbar text shown after an import.
String importSummary(DataBundle bundle) =>
    'Imported ${_counted(bundle.vehicles.length, 'vehicle')}, '
    '${_counted(bundle.entries.length, 'refuel')}, '
    '${_counted(bundle.serviceLog.length, 'service')}, '
    '${_counted(bundle.expenses.length, 'expense')}, and '
    '${_counted(bundle.odometerReadings.length, 'odometer reading')}.';

/// "1 vehicle", "2 vehicles". Every noun in the import summary takes a plain
/// -s plural.
String _counted(int count, String noun) =>
    '$count $noun${count == 1 ? '' : 's'}';
