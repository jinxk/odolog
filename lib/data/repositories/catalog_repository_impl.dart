import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../../domain/entities/fuel_variant.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../catalog/catalog_loader.dart';

/// [CatalogRepository] backed by the JSON asset. The loader already degrades a
/// missing or malformed catalog to an empty list, so load always succeeds.
class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._loader);

  final CatalogLoader _loader;

  @override
  Future<Result<List<FuelVariant>>> load() async {
    return right(await _loader.load());
  }
}
