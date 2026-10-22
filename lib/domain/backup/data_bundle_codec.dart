import '../../core/typedefs.dart';
import '../entities/vehicle.dart';
import 'data_bundle.dart';

/// Port for turning a [DataBundle] into the interchange file format OdoLog
/// exports and imports, and back. The domain decides what a backup contains;
/// an implementation in an outer layer decides the file format and how it is
/// written. Kept as an interface here so the domain, and the presentation
/// layer that reaches it through a use case, stay free of any file format
/// detail. Today the only implementation is CSV; a future format only needs a
/// new implementation of this port.
abstract interface class DataBundleCodec {
  /// Serialises [bundle] to the format's current version.
  String encode(DataBundle bundle);

  /// A blank file with every section and one example row each, so a user can
  /// fill it in externally and import it back.
  String template();

  /// A file for adding to a phone that already has data: [vehicles] listed
  /// by id and name to copy from, and one example item per section with no
  /// id, pointing at the last of [vehicles]. [vehicles] is not empty. The
  /// examples are dated [now] and their odometers run on from [startOdometer],
  /// the latest odometer of that last vehicle, so the file imports as it is.
  String addTemplate(
    List<Vehicle> vehicles, {
    required double startOdometer,
    required DateTime now,
  });

  /// Parses [content] back into a [DataBundle]. A structural problem (a
  /// missing section, the wrong columns, an unparsable value) comes back as a
  /// Failure instead of throwing.
  Result<DataBundle> decode(String content);
}
