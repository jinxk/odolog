import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../backup/data_bundle_codec.dart';
import '../calculators/latest_odometer.dart';
import '../repositories/odometer_reading_repository.dart';
import '../repositories/refuel_repository.dart';
import 'list_vehicles.dart';

/// The template for adding to a phone that already has data. The examples
/// follow the newest vehicle: they start after its latest odometer and are
/// dated now, so the file imports as downloaded. With no vehicle there is
/// nothing for the examples to point at, so it is the blank one.
class GetAddDataTemplate {
  const GetAddDataTemplate(
    this._listVehicles,
    this._refuelRepository,
    this._readingRepository,
    this._codec,
  );

  final ListVehicles _listVehicles;
  final RefuelRepository _refuelRepository;
  final OdometerReadingRepository _readingRepository;
  final DataBundleCodec _codec;

  Future<Result<String>> execute() async {
    final vehiclesResult = await _listVehicles.execute();
    final vehiclesFailure = vehiclesResult.getLeft().toNullable();
    if (vehiclesFailure != null) return left(vehiclesFailure);
    final vehicles = vehiclesResult.getRight().toNullable()!;
    if (vehicles.isEmpty) return right(_codec.template());

    final newest = vehicles.last;
    final refuelsResult = await _refuelRepository.getForVehicle(newest.id);
    final refuelsFailure = refuelsResult.getLeft().toNullable();
    if (refuelsFailure != null) return left(refuelsFailure);
    final readingsResult = await _readingRepository.getForVehicle(newest.id);
    final readingsFailure = readingsResult.getLeft().toNullable();
    if (readingsFailure != null) return left(readingsFailure);

    final latest = LatestOdometerCalculator.of(
      refuelsResult.getRight().toNullable()!,
      readingsResult.getRight().toNullable()!,
    );
    return right(
      _codec.addTemplate(
        vehicles,
        startOdometer: latest?.odometer ?? 0,
        now: DateTime.now(),
      ),
    );
  }
}
