import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/entities/fuel_variant.dart';
import 'package:odolog/domain/repositories/catalog_repository.dart';

/// In-memory [CatalogRepository] for widget tests, so the fuel variant dropdown
/// never has to reach the JSON asset through rootBundle.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository([this._variants = const []]);

  final List<FuelVariant> _variants;

  @override
  Future<Result<List<FuelVariant>>> load() async => right(_variants);
}
