import '../../core/typedefs.dart';
import '../entities/odometer_reading.dart';
import '../repositories/odometer_reading_repository.dart';

class GetOdometerReadings {
  const GetOdometerReadings(this._repository);

  final OdometerReadingRepository _repository;

  /// The vehicle's manual odometer readings, in the repository's odometer then
  /// date order, ready to merge with the refuel history.
  Future<Result<List<OdometerReading>>> execute(int vehicleId) =>
      _repository.getForVehicle(vehicleId);
}
