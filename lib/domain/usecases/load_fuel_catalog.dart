import '../../core/typedefs.dart';
import '../entities/fuel_variant.dart';
import '../entities/vehicle.dart';
import '../repositories/catalog_repository.dart';

class LoadFuelCatalog {
  const LoadFuelCatalog(this._repository);

  final CatalogRepository _repository;

  Future<Result<List<FuelVariant>>> execute({FuelCategory? category}) async {
    final result = await _repository.load();
    if (category == null) return result;
    return result.map(
      (variants) => variants.where((v) => v.category == category).toList(),
    );
  }
}
