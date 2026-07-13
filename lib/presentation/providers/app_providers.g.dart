// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The id of the vehicle the dashboard and stats read from. Session scoped and
/// kept alive so switching screens does not lose the selection. Null means fall
/// back to the first vehicle.

@ProviderFor(ActiveVehicleId)
final activeVehicleIdProvider = ActiveVehicleIdProvider._();

/// The id of the vehicle the dashboard and stats read from. Session scoped and
/// kept alive so switching screens does not lose the selection. Null means fall
/// back to the first vehicle.
final class ActiveVehicleIdProvider
    extends $NotifierProvider<ActiveVehicleId, int?> {
  /// The id of the vehicle the dashboard and stats read from. Session scoped and
  /// kept alive so switching screens does not lose the selection. Null means fall
  /// back to the first vehicle.
  ActiveVehicleIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeVehicleIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeVehicleIdHash();

  @$internal
  @override
  ActiveVehicleId create() => ActiveVehicleId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$activeVehicleIdHash() => r'dfc5eb3dd729f4a91d4eac53ce586b9439e9a973';

/// The id of the vehicle the dashboard and stats read from. Session scoped and
/// kept alive so switching screens does not lose the selection. Null means fall
/// back to the first vehicle.

abstract class _$ActiveVehicleId extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Which history segment is showing. Session scoped and kept alive, like the
/// vehicle selection, so leaving the tab and coming back does not lose the
/// segment; the shell also reads it to decide which add button to float, and
/// the dashboard's service glance sets it before jumping to the tab.

@ProviderFor(HistoryTab)
final historyTabProvider = HistoryTabProvider._();

/// Which history segment is showing. Session scoped and kept alive, like the
/// vehicle selection, so leaving the tab and coming back does not lose the
/// segment; the shell also reads it to decide which add button to float, and
/// the dashboard's service glance sets it before jumping to the tab.
final class HistoryTabProvider
    extends $NotifierProvider<HistoryTab, HistorySegment> {
  /// Which history segment is showing. Session scoped and kept alive, like the
  /// vehicle selection, so leaving the tab and coming back does not lose the
  /// segment; the shell also reads it to decide which add button to float, and
  /// the dashboard's service glance sets it before jumping to the tab.
  HistoryTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyTabHash();

  @$internal
  @override
  HistoryTab create() => HistoryTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistorySegment value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistorySegment>(value),
    );
  }
}

String _$historyTabHash() => r'a8485422f25bbdb1c8da7be1b1bd9d070b9c056b';

/// Which history segment is showing. Session scoped and kept alive, like the
/// vehicle selection, so leaving the tab and coming back does not lose the
/// segment; the shell also reads it to decide which add button to float, and
/// the dashboard's service glance sets it before jumping to the tab.

abstract class _$HistoryTab extends $Notifier<HistorySegment> {
  HistorySegment build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HistorySegment, HistorySegment>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistorySegment, HistorySegment>,
              HistorySegment,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(vehicleList)
final vehicleListProvider = VehicleListProvider._();

final class VehicleListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Vehicle>>,
          List<Vehicle>,
          FutureOr<List<Vehicle>>
        >
    with $FutureModifier<List<Vehicle>>, $FutureProvider<List<Vehicle>> {
  VehicleListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vehicleListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vehicleListHash();

  @$internal
  @override
  $FutureProviderElement<List<Vehicle>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Vehicle>> create(Ref ref) {
    return vehicleList(ref);
  }
}

String _$vehicleListHash() => r'27e16679aa4a260725b43c1ba263b9171e0db49d';

/// The vehicle currently in focus: the selected one when set and still present,
/// otherwise the first vehicle, or null when there are none.

@ProviderFor(currentVehicle)
final currentVehicleProvider = CurrentVehicleProvider._();

/// The vehicle currently in focus: the selected one when set and still present,
/// otherwise the first vehicle, or null when there are none.

final class CurrentVehicleProvider
    extends
        $FunctionalProvider<AsyncValue<Vehicle?>, Vehicle?, FutureOr<Vehicle?>>
    with $FutureModifier<Vehicle?>, $FutureProvider<Vehicle?> {
  /// The vehicle currently in focus: the selected one when set and still present,
  /// otherwise the first vehicle, or null when there are none.
  CurrentVehicleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentVehicleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentVehicleHash();

  @$internal
  @override
  $FutureProviderElement<Vehicle?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Vehicle?> create(Ref ref) {
    return currentVehicle(ref);
  }
}

String _$currentVehicleHash() => r'bd2cb7fdd1033df06c88b88519ec9abc96ecd9e1';

@ProviderFor(vehicleStats)
final vehicleStatsProvider = VehicleStatsFamily._();

final class VehicleStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<VehicleStats>,
          VehicleStats,
          FutureOr<VehicleStats>
        >
    with $FutureModifier<VehicleStats>, $FutureProvider<VehicleStats> {
  VehicleStatsProvider._({
    required VehicleStatsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'vehicleStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vehicleStatsHash();

  @override
  String toString() {
    return r'vehicleStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<VehicleStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VehicleStats> create(Ref ref) {
    final argument = this.argument as int;
    return vehicleStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VehicleStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vehicleStatsHash() => r'076752370dba6f89acb7587b10825184d428b8ec';

final class VehicleStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<VehicleStats>, int> {
  VehicleStatsFamily._()
    : super(
        retry: null,
        name: r'vehicleStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VehicleStatsProvider call(int vehicleId) =>
      VehicleStatsProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'vehicleStatsProvider';
}

@ProviderFor(history)
final historyProvider = HistoryFamily._();

final class HistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HistoryItem>>,
          List<HistoryItem>,
          FutureOr<List<HistoryItem>>
        >
    with
        $FutureModifier<List<HistoryItem>>,
        $FutureProvider<List<HistoryItem>> {
  HistoryProvider._({
    required HistoryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'historyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$historyHash();

  @override
  String toString() {
    return r'historyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<HistoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HistoryItem>> create(Ref ref) {
    final argument = this.argument as int;
    return history(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$historyHash() => r'4583d2b39a063d618ead6fefc584925f7f4f3479';

final class HistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<HistoryItem>>, int> {
  HistoryFamily._()
    : super(
        retry: null,
        name: r'historyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HistoryProvider call(int vehicleId) =>
      HistoryProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'historyProvider';
}

/// Per calendar month rollups for the stats screen and the this month card,
/// keyed by the first day of each month in chronological order.

@ProviderFor(vehicleMonthly)
final vehicleMonthlyProvider = VehicleMonthlyFamily._();

/// Per calendar month rollups for the stats screen and the this month card,
/// keyed by the first day of each month in chronological order.

final class VehicleMonthlyProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<DateTime, VehicleStats>>,
          Map<DateTime, VehicleStats>,
          FutureOr<Map<DateTime, VehicleStats>>
        >
    with
        $FutureModifier<Map<DateTime, VehicleStats>>,
        $FutureProvider<Map<DateTime, VehicleStats>> {
  /// Per calendar month rollups for the stats screen and the this month card,
  /// keyed by the first day of each month in chronological order.
  VehicleMonthlyProvider._({
    required VehicleMonthlyFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'vehicleMonthlyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vehicleMonthlyHash();

  @override
  String toString() {
    return r'vehicleMonthlyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<DateTime, VehicleStats>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<DateTime, VehicleStats>> create(Ref ref) {
    final argument = this.argument as int;
    return vehicleMonthly(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VehicleMonthlyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vehicleMonthlyHash() => r'a54aa0da7bc7b205deaaaef4e0bd1aad9bc28a95';

/// Per calendar month rollups for the stats screen and the this month card,
/// keyed by the first day of each month in chronological order.

final class VehicleMonthlyFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<DateTime, VehicleStats>>, int> {
  VehicleMonthlyFamily._()
    : super(
        retry: null,
        name: r'vehicleMonthlyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per calendar month rollups for the stats screen and the this month card,
  /// keyed by the first day of each month in chronological order.

  VehicleMonthlyProvider call(int vehicleId) =>
      VehicleMonthlyProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'vehicleMonthlyProvider';
}

/// The closed full tank windows for a vehicle, one point per window, for the
/// mileage trend on the home and stats screens.

@ProviderFor(vehicleWindows)
final vehicleWindowsProvider = VehicleWindowsFamily._();

/// The closed full tank windows for a vehicle, one point per window, for the
/// mileage trend on the home and stats screens.

final class VehicleWindowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WindowMileage>>,
          List<WindowMileage>,
          FutureOr<List<WindowMileage>>
        >
    with
        $FutureModifier<List<WindowMileage>>,
        $FutureProvider<List<WindowMileage>> {
  /// The closed full tank windows for a vehicle, one point per window, for the
  /// mileage trend on the home and stats screens.
  VehicleWindowsProvider._({
    required VehicleWindowsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'vehicleWindowsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vehicleWindowsHash();

  @override
  String toString() {
    return r'vehicleWindowsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<WindowMileage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WindowMileage>> create(Ref ref) {
    final argument = this.argument as int;
    return vehicleWindows(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VehicleWindowsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vehicleWindowsHash() => r'149fdae5b4cdbf0314613cc5e29dcdb5673e959f';

/// The closed full tank windows for a vehicle, one point per window, for the
/// mileage trend on the home and stats screens.

final class VehicleWindowsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<WindowMileage>>, int> {
  VehicleWindowsFamily._()
    : super(
        retry: null,
        name: r'vehicleWindowsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The closed full tank windows for a vehicle, one point per window, for the
  /// mileage trend on the home and stats screens.

  VehicleWindowsProvider call(int vehicleId) =>
      VehicleWindowsProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'vehicleWindowsProvider';
}

@ProviderFor(catalog)
final catalogProvider = CatalogFamily._();

final class CatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FuelVariant>>,
          List<FuelVariant>,
          FutureOr<List<FuelVariant>>
        >
    with
        $FutureModifier<List<FuelVariant>>,
        $FutureProvider<List<FuelVariant>> {
  CatalogProvider._({
    required CatalogFamily super.from,
    required FuelCategory super.argument,
  }) : super(
         retry: null,
         name: r'catalogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$catalogHash();

  @override
  String toString() {
    return r'catalogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FuelVariant>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FuelVariant>> create(Ref ref) {
    final argument = this.argument as FuelCategory;
    return catalog(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CatalogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$catalogHash() => r'a013a88fec2ca02e51477ab3d81bc15788ea14da';

final class CatalogFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FuelVariant>>, FuelCategory> {
  CatalogFamily._()
    : super(
        retry: null,
        name: r'catalogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CatalogProvider call(FuelCategory category) =>
      CatalogProvider._(argument: category, from: this);

  @override
  String toString() => r'catalogProvider';
}

/// A vehicle's service history, most recent first.

@ProviderFor(serviceLog)
final serviceLogProvider = ServiceLogFamily._();

/// A vehicle's service history, most recent first.

final class ServiceLogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ServiceLogEntry>>,
          List<ServiceLogEntry>,
          FutureOr<List<ServiceLogEntry>>
        >
    with
        $FutureModifier<List<ServiceLogEntry>>,
        $FutureProvider<List<ServiceLogEntry>> {
  /// A vehicle's service history, most recent first.
  ServiceLogProvider._({
    required ServiceLogFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'serviceLogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$serviceLogHash();

  @override
  String toString() {
    return r'serviceLogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ServiceLogEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ServiceLogEntry>> create(Ref ref) {
    final argument = this.argument as int;
    return serviceLog(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceLogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$serviceLogHash() => r'688187b52eabffcb26189c6834ed7221095e7141';

/// A vehicle's service history, most recent first.

final class ServiceLogFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ServiceLogEntry>>, int> {
  ServiceLogFamily._()
    : super(
        retry: null,
        name: r'serviceLogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A vehicle's service history, most recent first.

  ServiceLogProvider call(int vehicleId) =>
      ServiceLogProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'serviceLogProvider';
}

/// A vehicle's non-fuel expenses, most recent first.

@ProviderFor(expenses)
final expensesProvider = ExpensesFamily._();

/// A vehicle's non-fuel expenses, most recent first.

final class ExpensesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Expense>>,
          List<Expense>,
          FutureOr<List<Expense>>
        >
    with $FutureModifier<List<Expense>>, $FutureProvider<List<Expense>> {
  /// A vehicle's non-fuel expenses, most recent first.
  ExpensesProvider._({
    required ExpensesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'expensesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expensesHash();

  @override
  String toString() {
    return r'expensesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Expense>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Expense>> create(Ref ref) {
    final argument = this.argument as int;
    return expenses(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpensesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expensesHash() => r'6fd9366687817f46ead5298def421c60138c9f39';

/// A vehicle's non-fuel expenses, most recent first.

final class ExpensesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Expense>>, int> {
  ExpensesFamily._()
    : super(
        retry: null,
        name: r'expensesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A vehicle's non-fuel expenses, most recent first.

  ExpensesProvider call(int vehicleId) =>
      ExpensesProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'expensesProvider';
}

/// Where a vehicle's two maintenance templates stand right now, for the
/// dashboard glance and the service log screen's header.

@ProviderFor(serviceDue)
final serviceDueProvider = ServiceDueFamily._();

/// Where a vehicle's two maintenance templates stand right now, for the
/// dashboard glance and the service log screen's header.

final class ServiceDueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ServiceDueStatus>>,
          List<ServiceDueStatus>,
          FutureOr<List<ServiceDueStatus>>
        >
    with
        $FutureModifier<List<ServiceDueStatus>>,
        $FutureProvider<List<ServiceDueStatus>> {
  /// Where a vehicle's two maintenance templates stand right now, for the
  /// dashboard glance and the service log screen's header.
  ServiceDueProvider._({
    required ServiceDueFamily super.from,
    required Vehicle super.argument,
  }) : super(
         retry: null,
         name: r'serviceDueProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$serviceDueHash();

  @override
  String toString() {
    return r'serviceDueProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ServiceDueStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ServiceDueStatus>> create(Ref ref) {
    final argument = this.argument as Vehicle;
    return serviceDue(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceDueProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$serviceDueHash() => r'3439d58ff30f7ac1bdd2cb7e7a01bf2f22b4e8dd';

/// Where a vehicle's two maintenance templates stand right now, for the
/// dashboard glance and the service log screen's header.

final class ServiceDueFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ServiceDueStatus>>, Vehicle> {
  ServiceDueFamily._()
    : super(
        retry: null,
        name: r'serviceDueProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Where a vehicle's two maintenance templates stand right now, for the
  /// dashboard glance and the service log screen's header.

  ServiceDueProvider call(Vehicle vehicle) =>
      ServiceDueProvider._(argument: vehicle, from: this);

  @override
  String toString() => r'serviceDueProvider';
}

/// Keeps the scheduled document reminders in step with the vehicles. Watched
/// once by the app so it stays alive; it fires immediately on start and again
/// whenever the vehicle list changes (a saved edit invalidates that list), so
/// a newly entered or cleared expiry date reschedules without any extra call
/// site. The sync itself is best effort and a no-op off Android.

@ProviderFor(DocumentReminderSync)
final documentReminderSyncProvider = DocumentReminderSyncProvider._();

/// Keeps the scheduled document reminders in step with the vehicles. Watched
/// once by the app so it stays alive; it fires immediately on start and again
/// whenever the vehicle list changes (a saved edit invalidates that list), so
/// a newly entered or cleared expiry date reschedules without any extra call
/// site. The sync itself is best effort and a no-op off Android.
final class DocumentReminderSyncProvider
    extends $NotifierProvider<DocumentReminderSync, void> {
  /// Keeps the scheduled document reminders in step with the vehicles. Watched
  /// once by the app so it stays alive; it fires immediately on start and again
  /// whenever the vehicle list changes (a saved edit invalidates that list), so
  /// a newly entered or cleared expiry date reschedules without any extra call
  /// site. The sync itself is best effort and a no-op off Android.
  DocumentReminderSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentReminderSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentReminderSyncHash();

  @$internal
  @override
  DocumentReminderSync create() => DocumentReminderSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$documentReminderSyncHash() =>
    r'cf5a7212e034fa7136d0766adb7537bb815aa269';

/// Keeps the scheduled document reminders in step with the vehicles. Watched
/// once by the app so it stays alive; it fires immediately on start and again
/// whenever the vehicle list changes (a saved edit invalidates that list), so
/// a newly entered or cleared expiry date reschedules without any extra call
/// site. The sync itself is best effort and a no-op off Android.

abstract class _$DocumentReminderSync extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Keeps the scheduled service due reminders in step with the vehicles, the
/// same pattern [DocumentReminderSync] uses: it fires on start and again
/// whenever the vehicle list changes, so an edited interval reschedules
/// without an extra call site. Logging a service does not change the vehicle
/// list, so the service log screen also calls
/// `syncServiceRemindersProvider` directly after a save.

@ProviderFor(ServiceReminderSync)
final serviceReminderSyncProvider = ServiceReminderSyncProvider._();

/// Keeps the scheduled service due reminders in step with the vehicles, the
/// same pattern [DocumentReminderSync] uses: it fires on start and again
/// whenever the vehicle list changes, so an edited interval reschedules
/// without an extra call site. Logging a service does not change the vehicle
/// list, so the service log screen also calls
/// `syncServiceRemindersProvider` directly after a save.
final class ServiceReminderSyncProvider
    extends $NotifierProvider<ServiceReminderSync, void> {
  /// Keeps the scheduled service due reminders in step with the vehicles, the
  /// same pattern [DocumentReminderSync] uses: it fires on start and again
  /// whenever the vehicle list changes, so an edited interval reschedules
  /// without an extra call site. Logging a service does not change the vehicle
  /// list, so the service log screen also calls
  /// `syncServiceRemindersProvider` directly after a save.
  ServiceReminderSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceReminderSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceReminderSyncHash();

  @$internal
  @override
  ServiceReminderSync create() => ServiceReminderSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$serviceReminderSyncHash() =>
    r'67088510300a5e23bf645242e2d49423733154ba';

/// Keeps the scheduled service due reminders in step with the vehicles, the
/// same pattern [DocumentReminderSync] uses: it fires on start and again
/// whenever the vehicle list changes, so an edited interval reschedules
/// without an extra call site. Logging a service does not change the vehicle
/// list, so the service log screen also calls
/// `syncServiceRemindersProvider` directly after a save.

abstract class _$ServiceReminderSync extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
