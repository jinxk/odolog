import '../../core/typedefs.dart';
import '../../domain/backup/data_bundle.dart';
import '../../domain/backup/data_bundle_codec.dart';
import 'data_bundle_csv_codec.dart';

/// [DataBundleCodec] over the CSV format described in [DataBundleCsvFormat].
/// Fronts the existing writer and reader; the format itself is unchanged.
class DataBundleCodecImpl implements DataBundleCodec {
  const DataBundleCodecImpl();

  @override
  String encode(DataBundle bundle) => DataBundleCsvWriter.write(bundle);

  @override
  String template() => DataBundleCsvWriter.template();

  @override
  Result<DataBundle> decode(String content) =>
      DataBundleCsvReader.read(content);
}
