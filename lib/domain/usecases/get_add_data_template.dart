import '../../core/typedefs.dart';
import '../backup/data_bundle_codec.dart';
import 'list_vehicles.dart';

/// The template for adding to a phone that already has data. With no vehicle
/// there is nothing for the examples to point at, so it is the blank one.
class GetAddDataTemplate {
  const GetAddDataTemplate(this._listVehicles, this._codec);

  final ListVehicles _listVehicles;
  final DataBundleCodec _codec;

  Future<Result<String>> execute() async {
    final vehicles = await _listVehicles.execute();
    return vehicles.map(
      (list) => list.isEmpty ? _codec.template() : _codec.addTemplate(list),
    );
  }
}
