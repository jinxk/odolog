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

@ProviderFor(odometerReadingRepository)
final odometerReadingRepositoryProvider = OdometerReadingRepositoryProvider._();

final class OdometerReadingRepositoryProvider
    extends
        $FunctionalProvider<
          OdometerReadingRepository,
          OdometerReadingRepository,
          OdometerReadingRepository
        >
    with $Provider<OdometerReadingRepository> {
  OdometerReadingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'odometerReadingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$odometerReadingRepositoryHash();

  @$internal
  @override
  $ProviderElement<OdometerReadingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OdometerReadingRepository create(Ref ref) {
    return odometerReadingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OdometerReadingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OdometerReadingRepository>(value),
    );
  }
}

String _$odometerReadingRepositoryHash() =>
    r'c7b68f0c0593c854ccb4635862a045bbce14f0b8';

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

@ProviderFor(serviceLogRepository)
final serviceLogRepositoryProvider = ServiceLogRepositoryProvider._();

final class ServiceLogRepositoryProvider
    extends
        $FunctionalProvider<
          ServiceLogRepository,
          ServiceLogRepository,
          ServiceLogRepository
        >
    with $Provider<ServiceLogRepository> {
  ServiceLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceLogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceLogRepositoryHash();

  @$internal
  @override
  $ProviderElement<ServiceLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ServiceLogRepository create(Ref ref) {
    return serviceLogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServiceLogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServiceLogRepository>(value),
    );
  }
}

String _$serviceLogRepositoryHash() =>
    r'a044d7de813b2d71e56c61cfb8a638eed044268c';

@ProviderFor(expenseRepository)
final expenseRepositoryProvider = ExpenseRepositoryProvider._();

final class ExpenseRepositoryProvider
    extends
        $FunctionalProvider<
          ExpenseRepository,
          ExpenseRepository,
          ExpenseRepository
        >
    with $Provider<ExpenseRepository> {
  ExpenseRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExpenseRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExpenseRepository create(Ref ref) {
    return expenseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExpenseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExpenseRepository>(value),
    );
  }
}

String _$expenseRepositoryHash() => r'7b7f0c752025d9e217e415280eb41a72f2e6dc1b';

/// The transaction boundary the import runs inside. Shares the one open
/// database with the repositories: a transaction it opens is picked up by every
/// DAO called underneath it.

@ProviderFor(unitOfWork)
final unitOfWorkProvider = UnitOfWorkProvider._();

/// The transaction boundary the import runs inside. Shares the one open
/// database with the repositories: a transaction it opens is picked up by every
/// DAO called underneath it.

final class UnitOfWorkProvider
    extends $FunctionalProvider<UnitOfWork, UnitOfWork, UnitOfWork>
    with $Provider<UnitOfWork> {
  /// The transaction boundary the import runs inside. Shares the one open
  /// database with the repositories: a transaction it opens is picked up by every
  /// DAO called underneath it.
  UnitOfWorkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unitOfWorkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unitOfWorkHash();

  @$internal
  @override
  $ProviderElement<UnitOfWork> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UnitOfWork create(Ref ref) {
    return unitOfWork(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnitOfWork value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnitOfWork>(value),
    );
  }
}

String _$unitOfWorkHash() => r'97b1b5472e14279e71df536df8fcd84dc1372837';

/// Permanently erases every vehicle and everything logged against it, for the
/// delete all data feature. Shares the same open database as the
/// repositories.

@ProviderFor(dataEraser)
final dataEraserProvider = DataEraserProvider._();

/// Permanently erases every vehicle and everything logged against it, for the
/// delete all data feature. Shares the same open database as the
/// repositories.

final class DataEraserProvider
    extends $FunctionalProvider<DataEraser, DataEraser, DataEraser>
    with $Provider<DataEraser> {
  /// Permanently erases every vehicle and everything logged against it, for the
  /// delete all data feature. Shares the same open database as the
  /// repositories.
  DataEraserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataEraserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataEraserHash();

  @$internal
  @override
  $ProviderElement<DataEraser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DataEraser create(Ref ref) {
    return dataEraser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataEraser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataEraser>(value),
    );
  }
}

String _$dataEraserHash() => r'59db72e5af52739a9e750fa315789c7ec0d227dc';

/// The platform notification scheduler. Widget tests can override this with a
/// no-op, though the real one already stands down off Android.

@ProviderFor(reminderScheduler)
final reminderSchedulerProvider = ReminderSchedulerProvider._();

/// The platform notification scheduler. Widget tests can override this with a
/// no-op, though the real one already stands down off Android.

final class ReminderSchedulerProvider
    extends
        $FunctionalProvider<
          ReminderScheduler,
          ReminderScheduler,
          ReminderScheduler
        >
    with $Provider<ReminderScheduler> {
  /// The platform notification scheduler. Widget tests can override this with a
  /// no-op, though the real one already stands down off Android.
  ReminderSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSchedulerHash();

  @$internal
  @override
  $ProviderElement<ReminderScheduler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReminderScheduler create(Ref ref) {
    return reminderScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderScheduler>(value),
    );
  }
}

String _$reminderSchedulerHash() => r'be7571a0b5f5b383c0752ec8bf9d7a94d39bce9c';

/// The backup file format. Presentation never reaches the JSON writer and
/// reader directly; it goes through this port via the export, import, and
/// template use cases.

@ProviderFor(dataBundleCodec)
final dataBundleCodecProvider = DataBundleCodecProvider._();

/// The backup file format. Presentation never reaches the JSON writer and
/// reader directly; it goes through this port via the export, import, and
/// template use cases.

final class DataBundleCodecProvider
    extends
        $FunctionalProvider<DataBundleCodec, DataBundleCodec, DataBundleCodec>
    with $Provider<DataBundleCodec> {
  /// The backup file format. Presentation never reaches the JSON writer and
  /// reader directly; it goes through this port via the export, import, and
  /// template use cases.
  DataBundleCodecProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataBundleCodecProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataBundleCodecHash();

  @$internal
  @override
  $ProviderElement<DataBundleCodec> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DataBundleCodec create(Ref ref) {
    return dataBundleCodec(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataBundleCodec value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataBundleCodec>(value),
    );
  }
}

String _$dataBundleCodecHash() => r'27e80acb0ba88b8e6016438c5f64eab3e8d08e38';

/// The uninstall surviving backup writer. Android writes to the shared
/// Downloads collection through a MethodChannel; off Android, and below
/// Android 10, it reports itself unavailable and the feature stands down.

@ProviderFor(autoBackupWriter)
final autoBackupWriterProvider = AutoBackupWriterProvider._();

/// The uninstall surviving backup writer. Android writes to the shared
/// Downloads collection through a MethodChannel; off Android, and below
/// Android 10, it reports itself unavailable and the feature stands down.

final class AutoBackupWriterProvider
    extends
        $FunctionalProvider<
          AutoBackupWriter,
          AutoBackupWriter,
          AutoBackupWriter
        >
    with $Provider<AutoBackupWriter> {
  /// The uninstall surviving backup writer. Android writes to the shared
  /// Downloads collection through a MethodChannel; off Android, and below
  /// Android 10, it reports itself unavailable and the feature stands down.
  AutoBackupWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoBackupWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoBackupWriterHash();

  @$internal
  @override
  $ProviderElement<AutoBackupWriter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AutoBackupWriter create(Ref ref) {
    return autoBackupWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoBackupWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoBackupWriter>(value),
    );
  }
}

String _$autoBackupWriterHash() => r'1488f36be78e7a98f4ca71e858e958b79abd3281';
