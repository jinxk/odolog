// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repositories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The open database. Overridden with a concrete instance in main() once the
/// file is opened, so every downstream provider stays synchronous. Widget tests
/// override the repository providers directly and never touch this one.

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// The open database. Overridden with a concrete instance in main() once the
/// file is opened, so every downstream provider stays synchronous. Widget tests
/// override the repository providers directly and never touch this one.

final class DatabaseProvider
    extends $FunctionalProvider<Database, Database, Database>
    with $Provider<Database> {
  /// The open database. Overridden with a concrete instance in main() once the
  /// file is opened, so every downstream provider stays synchronous. Widget tests
  /// override the repository providers directly and never touch this one.
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<Database> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Database create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Database value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Database>(value),
    );
  }
}

String _$databaseHash() => r'1273287de1dc4f34b709f4e38d8048bdb150408a';

@ProviderFor(vehicleRepository)
final vehicleRepositoryProvider = VehicleRepositoryProvider._();

final class VehicleRepositoryProvider
    extends
        $FunctionalProvider<
          VehicleRepository,
          VehicleRepository,
          VehicleRepository
        >
    with $Provider<VehicleRepository> {
  VehicleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vehicleRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vehicleRepositoryHash();

  @$internal
  @override
  $ProviderElement<VehicleRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VehicleRepository create(Ref ref) {
    return vehicleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VehicleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VehicleRepository>(value),
    );
  }
}

String _$vehicleRepositoryHash() => r'03ca08198f0a27d73ac28dfab6136c021a1fa544';

@ProviderFor(refuelRepository)
final refuelRepositoryProvider = RefuelRepositoryProvider._();

final class RefuelRepositoryProvider
    extends
        $FunctionalProvider<
          RefuelRepository,
          RefuelRepository,
          RefuelRepository
        >
    with $Provider<RefuelRepository> {
  RefuelRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'refuelRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$refuelRepositoryHash();

  @$internal
  @override
  $ProviderElement<RefuelRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RefuelRepository create(Ref ref) {
    return refuelRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RefuelRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RefuelRepository>(value),
    );
  }
}

String _$refuelRepositoryHash() => r'3e63ee155c017fa86a505597fad97b218d88af32';

@ProviderFor(catalogRepository)
final catalogRepositoryProvider = CatalogRepositoryProvider._();

final class CatalogRepositoryProvider
    extends
        $FunctionalProvider<
          CatalogRepository,
          CatalogRepository,
          CatalogRepository
        >
    with $Provider<CatalogRepository> {
  CatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogRepositoryHash();

  @$internal
  @override
  $ProviderElement<CatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CatalogRepository create(Ref ref) {
    return catalogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogRepository>(value),
    );
  }
}

String _$catalogRepositoryHash() => r'eea770e029bd6d17747b2d817ec488a37014f592';
