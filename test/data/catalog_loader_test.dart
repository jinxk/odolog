import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/data/catalog/catalog_loader.dart';
import 'package:odolog/domain/entities/fuel_variant.dart';
import 'package:odolog/domain/entities/vehicle.dart';

/// Serves a fixed string as the catalog asset, or throws when the content is
/// null, standing in for a missing asset.
class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._content);

  final String? _content;

  @override
  Future<ByteData> load(String key) async {
    final content = _content;
    if (content == null) {
      throw FlutterError('Asset not found: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the shipped asset', () {
    late List<FuelVariant> variants;

    setUp(() async {
      variants = await CatalogLoader().load();
    });

    test('covers all seven brands', () {
      final brands = variants.map((v) => v.brandId).toSet();
      expect(brands, hasLength(7));
      expect(
        brands,
        containsAll(<String>[
          'iocl',
          'bpcl',
          'hpcl',
          'shell',
          'nayara',
          'jiobp',
          'generic',
        ]),
      );
    });

    test('parses IOCL XP100 as an ultra-tier petrol', () {
      final xp100 = variants.firstWhere((v) => v.id == 'iocl_xp100');
      expect(xp100.brandName, 'IndianOil');
      expect(xp100.name, 'XP100');
      expect(xp100.category, FuelCategory.petrol);
      expect(xp100.tier, 'ultra');
      expect(xp100.unit, 'litre');
    });

    test('parses generic CNG measured in kg with no tier', () {
      final cng = variants.firstWhere((v) => v.id == 'cng');
      expect(cng.category, FuelCategory.cng);
      expect(cng.unit, 'kg');
      expect(cng.tier, isNull);
    });

    test('filtering by category returns only that category', () {
      final petrol = variants
          .where((v) => v.category == FuelCategory.petrol)
          .toList();
      expect(petrol, hasLength(14));
      expect(petrol.every((v) => v.category == FuelCategory.petrol), isTrue);

      final diesel = variants
          .where((v) => v.category == FuelCategory.diesel)
          .toList();
      expect(diesel, hasLength(9));
    });
  });

  test('malformed JSON degrades to an empty list', () async {
    final loader = CatalogLoader(bundle: _FakeAssetBundle('{ not valid json'));
    expect(await loader.load(), isEmpty);
  });

  test('a missing asset degrades to an empty list', () async {
    final loader = CatalogLoader(bundle: _FakeAssetBundle(null));
    expect(await loader.load(), isEmpty);
  });
}
