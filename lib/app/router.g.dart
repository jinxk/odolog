// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single app router. It is built once and never rebuilt: recreating a
/// GoRouter that owns a StatefulShellRoute collides its GlobalKeys. So this
/// provider does not watch anything. Instead it listens to the vehicle list and
/// pushes the result into a refresh notifier that drives the onboarding
/// redirect, which keeps the router instance stable.

@ProviderFor(router)
final routerProvider = RouterProvider._();

/// The single app router. It is built once and never rebuilt: recreating a
/// GoRouter that owns a StatefulShellRoute collides its GlobalKeys. So this
/// provider does not watch anything. Instead it listens to the vehicle list and
/// pushes the result into a refresh notifier that drives the onboarding
/// redirect, which keeps the router instance stable.

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The single app router. It is built once and never rebuilt: recreating a
  /// GoRouter that owns a StatefulShellRoute collides its GlobalKeys. So this
  /// provider does not watch anything. Instead it listens to the vehicle list and
  /// pushes the result into a refresh notifier that drives the onboarding
  /// redirect, which keeps the router instance stable.
  RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'9c2124da1ae70296848e70472cc1fd6d17d002a8';
