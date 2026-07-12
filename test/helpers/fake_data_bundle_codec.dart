import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/backup/data_bundle.dart';
import 'package:odolog/domain/backup/data_bundle_codec.dart';

/// A [DataBundleCodec] stand-in for use case tests: encode and template
/// return a marker string instead of real CSV, and decode is scripted per
/// test rather than parsing anything.
class FakeDataBundleCodec implements DataBundleCodec {
  FakeDataBundleCodec({this._decodeResult});

  final Result<DataBundle>? _decodeResult;
  DataBundle? lastEncoded;

  @override
  String encode(DataBundle bundle) {
    lastEncoded = bundle;
    return 'encoded';
  }

  @override
  String template() => 'template';

  @override
  Result<DataBundle> decode(String content) =>
      _decodeResult ??
      left(const ValidationFailure(field: 'schema', reason: 'not scripted'));
}
