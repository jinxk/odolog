import '../backup/data_bundle_codec.dart';

/// A blank backup file with every section and one example row each, for a
/// user to fill in externally and import back.
class GetDataBundleTemplate {
  const GetDataBundleTemplate(this._codec);

  final DataBundleCodec _codec;

  String execute() => _codec.template();
}
