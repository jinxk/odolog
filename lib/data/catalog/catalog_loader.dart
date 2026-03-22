import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../domain/entities/fuel_variant.dart';
import '../../domain/entities/vehicle.dart';

/// Reads and parses the fuel catalog asset, caching the result for the session.
/// A missing or malformed asset degrades to an empty list instead of throwing,
/// so fuel logging never blocks on the catalog; the free-text "Other" option in
/// the UI covers anything the catalog lacks.
class CatalogLoader {
  CatalogLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/fuel_catalog.json';

  final AssetBundle _bundle;
  List<FuelVariant>? _cache;

  Future<List<FuelVariant>> load() async {
    return _cache ??= await _read();
  }

  Future<List<FuelVariant>> _read() async {
    try {
      final raw = await _bundle.loadString(assetPath);
      final decoded = json.decode(raw);
      if (decoded is! Map) return const [];
      final brands = decoded['brands'];
      if (brands is! List) return const [];

      final variants = <FuelVariant>[];
      for (final brand in brands) {
        if (brand is! Map) continue;
        final brandId = brand['id'];
        final brandName = brand['name'];
        final products = brand['products'];
        if (brandId is! String || brandName is! String || products is! List) {
          continue;
        }
        for (final product in products) {
          if (product is! Map) continue;
          final variant = _variant(brandId, brandName, product);
          if (variant != null) variants.add(variant);
        }
      }
      return variants;
    } catch (_) {
      return const [];
    }
  }

  FuelVariant? _variant(
    String brandId,
    String brandName,
    Map<Object?, Object?> product,
  ) {
    final id = product['id'];
    final name = product['name'];
    final categoryName = product['category'];
    if (id is! String || name is! String || categoryName is! String) {
      return null;
    }
    final category = _category(categoryName);
    if (category == null) return null;

    final tier = product['tier'];
    final unit = product['unit'];
    return FuelVariant(
      id: id,
      brandId: brandId,
      brandName: brandName,
      name: name,
      category: category,
      tier: tier is String ? tier : null,
      unit: unit is String ? unit : category.unit,
    );
  }

  FuelCategory? _category(String name) {
    for (final category in FuelCategory.values) {
      if (category.name == name) return category;
    }
    return null;
  }
}
