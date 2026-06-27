// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refuel_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps a refuel form's state alive for the duration of one add or edit flow,
/// keyed by a flow id so add and edit never share a buffer. Disposed explicitly
/// with ref.invalidate on save or cancel. A brief navigation away and back
/// therefore does not wipe half typed input.

@ProviderFor(RefuelForm)
final refuelFormProvider = RefuelFormFamily._();

/// Keeps a refuel form's state alive for the duration of one add or edit flow,
/// keyed by a flow id so add and edit never share a buffer. Disposed explicitly
/// with ref.invalidate on save or cancel. A brief navigation away and back
/// therefore does not wipe half typed input.
final class RefuelFormProvider
    extends $NotifierProvider<RefuelForm, RefuelFormState> {
  /// Keeps a refuel form's state alive for the duration of one add or edit flow,
  /// keyed by a flow id so add and edit never share a buffer. Disposed explicitly
  /// with ref.invalidate on save or cancel. A brief navigation away and back
  /// therefore does not wipe half typed input.
  RefuelFormProvider._({
    required RefuelFormFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'refuelFormProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$refuelFormHash();

  @override
  String toString() {
    return r'refuelFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RefuelForm create() => RefuelForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RefuelFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RefuelFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RefuelFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$refuelFormHash() => r'87e7a4a85cf4e8c6762079a1247d85841c320170';

/// Keeps a refuel form's state alive for the duration of one add or edit flow,
/// keyed by a flow id so add and edit never share a buffer. Disposed explicitly
/// with ref.invalidate on save or cancel. A brief navigation away and back
/// therefore does not wipe half typed input.

final class RefuelFormFamily extends $Family
    with
        $ClassFamilyOverride<
          RefuelForm,
          RefuelFormState,
          RefuelFormState,
          RefuelFormState,
          String
        > {
  RefuelFormFamily._()
    : super(
        retry: null,
        name: r'refuelFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Keeps a refuel form's state alive for the duration of one add or edit flow,
  /// keyed by a flow id so add and edit never share a buffer. Disposed explicitly
  /// with ref.invalidate on save or cancel. A brief navigation away and back
  /// therefore does not wipe half typed input.

  RefuelFormProvider call(String flowId) =>
      RefuelFormProvider._(argument: flowId, from: this);

  @override
  String toString() => r'refuelFormProvider';
}

/// Keeps a refuel form's state alive for the duration of one add or edit flow,
/// keyed by a flow id so add and edit never share a buffer. Disposed explicitly
/// with ref.invalidate on save or cancel. A brief navigation away and back
/// therefore does not wipe half typed input.

abstract class _$RefuelForm extends $Notifier<RefuelFormState> {
  late final _$args = ref.$arg as String;
  String get flowId => _$args;

  RefuelFormState build(String flowId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RefuelFormState, RefuelFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RefuelFormState, RefuelFormState>,
              RefuelFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
