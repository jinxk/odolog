import '../entities/expense.dart';
import '../entities/refuel_entry.dart';
import '../entities/service_log_entry.dart';
import '../entities/vehicle.dart';

/// The full set of vehicles and everything logged against them: a snapshot
/// fit for a backup or a restore. Encoding this to a file, and decoding it
/// back, is [DataBundleCodec]'s job; the use cases that produce and consume a
/// bundle only assemble or apply it.
typedef DataBundle = ({
  List<Vehicle> vehicles,
  List<RefuelEntry> entries,
  List<ServiceLogEntry> serviceLog,
  List<Expense> expenses,
});
