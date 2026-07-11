import '../../core/typedefs.dart';
import '../calculators/mileage_calculator.dart';
import '../entities/refuel_entry.dart';
import '../value_objects/entry_derived.dart';
import '../repositories/refuel_repository.dart';

typedef HistoryItem = ({RefuelEntry entry, EntryDerived derived});

class GetVehicleHistory {
  const GetVehicleHistory(this._repository);

  final RefuelRepository _repository;

  Future<Result<List<HistoryItem>>> execute(int vehicleId) async {
    final result = await _repository.getForVehicle(vehicleId);
    return result.map((entries) {
      final derived = const MileageCalculator().perEntry(entries);
      return [
        for (var i = 0; i < entries.length; i++)
          (entry: entries[i], derived: derived[i]),
      ];
    });
  }
}
