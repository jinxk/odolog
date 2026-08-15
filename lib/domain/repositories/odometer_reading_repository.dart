import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../entities/odometer_reading.dart';

abstract class OdometerReadingRepository {
  /// Readings for a vehicle ordered by odometer, then by
  /// [OdometerReading.recordedAt], matching the refuel ordering so the two
  /// lists merge without a resort.
  Future<Result<List<OdometerReading>>> getForVehicle(int vehicleId);
  Future<Result<OdometerReading>> add(OdometerReading reading);
  Future<Result<Unit>> delete(int id);
}
