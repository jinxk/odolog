import '../../core/typedefs.dart';
import '../entities/fuel_variant.dart';

abstract class CatalogRepository {
  Future<Result<List<FuelVariant>>> load();
}
