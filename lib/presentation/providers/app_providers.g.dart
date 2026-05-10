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
