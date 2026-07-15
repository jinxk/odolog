# Development

This is the working guide for anyone touching the code, including future me. Read `principles.md` first if you have not, because a few rules here (offline-only, math correctness) come straight from it.

## Prerequisites

- Flutter, stable channel. Whatever `flutter --version` reports on stable is what CI runs.
- Android SDK with a recent platform installed. OdoLog is Android-first, so the Android toolchain is the one that has to work.
- A device or emulator on Android for anything involving the database or navigation.

Run `flutter doctor` and clear any red marks before you start. Half the "it does not build" reports trace back to a doctor warning someone ignored.

## Getting started

```bash
git clone https://github.com/jinxk/odolog.git
cd odolog
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The `build_runner` step is not optional. Riverpod providers and a few other classes are generated, and the app will not compile without the generated files. Any time you change an annotated file, rerun it, or keep a watcher going:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Project layout

The code follows Clean Architecture in three layers, and the dependency rule points inward: presentation depends on domain, data depends on domain, and domain depends on nothing but pure Dart.

```text
lib/
  domain/        pure Dart, no Flutter imports
  data/          SQLite, repository implementations, asset catalog
  presentation/  widgets, providers, Material 3 theme
```

### domain

Entities, repository interfaces, and use cases. No Flutter imports live here, none at all. I keep the domain layer free of Flutter so the mileage math is testable without an emulator, which is most of the reason the tests run fast.

Each use case is a single class with one `execute()` method. If you find a use case growing a second public method, it is probably two use cases.

### data

Repository implementations, the sqflite database code, and the JSON asset that holds the fuel variant catalog (XP95, Shell V-Power, and the rest). This layer implements the interfaces declared in `domain` and knows about SQL and JSON. Nothing above it does.

### presentation

Widgets, Riverpod providers, routing with go_router, and the Material 3 theme. This layer talks to domain use cases, never to the database directly.

## Error handling

Operations that can fail return `Either` from fpdart, not thrown exceptions and not null. Left is a `Failure`, Right is the value.

```dart
Future<Either<Failure, Vehicle>> getVehicle(String id);
```

Define specific `Failure` subtypes (`DatabaseFailure`, `ValidationFailure`, and so on) rather than one catch-all. Handle both sides at the edges with `fold`. The point is that a caller reading the signature can see failure is possible and cannot forget to deal with it.

Reserve exceptions for genuinely unrecoverable programmer error. Expected, everyday failures (a bad input, a missing row) go through `Either`.

## State management

Riverpod with code generation. Use the `@riverpod` annotation and let build_runner produce the provider. Do not hand-write `StateProvider`/`Provider` declarations for new code.

```dart
@riverpod
class VehicleList extends _$VehicleList {
  @override
  Future<List<Vehicle>> build() async {
    // ...
  }
}
```

Keep provider bodies thin. They wire the UI to use cases; the actual logic belongs in `domain`.

## Database rules

- All database access goes through repositories. A widget or provider reaching into sqflite directly is a bug, even if it works.
- Any schema change bumps the schema version and ships a migration. Never edit an existing migration that has already been released, since someone's phone already ran it. Add the next one.
- Test migrations against a database created by the previous version. Fresh installs hide broken upgrade paths.

## Testing

- Every calculation in `domain` gets unit tests. Mileage between full tanks, partial-fill handling, cost per km, range per tank, spend rollups: all of it. This is the layer where a wrong number does real harm, so it carries the heaviest test weight.
- Forms get widget tests. The refuel entry form and the vehicle form are the important ones, including their validation.
- No absolute dates in tests. Never hardcode something like `2025-01-01`. Compute relative to `DateTime.now()` so the suite does not rot as the calendar moves and does not behave differently in January than in July.

```dart
final now = DateTime.now();
final lastWeek = now.subtract(const Duration(days: 7));
```

## Quality gates

These three commands must pass before every pull request. CI runs them and so should you, locally, before pushing:

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

The `--fatal-infos` flag is deliberate. Info-level hints count as failures, so the analyzer stays at zero noise instead of slowly filling with warnings everyone learns to skip.

## Release builds

Official releases are signed with a private keystore that never enters the repo: `android/.gitignore` blocks `key.properties` and every `*.jks`/`*.keystore`. Signing is a maintainer concern and is not documented here. A fork that wants its own releases should generate its own keystore and wire it through `android/key.properties`.

When `key.properties` is absent, release builds fall back to the debug key so `flutter run --release` works on a fresh clone. Debug-signed builds are fine for sideloading and useless for Play.

## Commits and branches

Conventional commits. The type prefixes in use are `feat`, `fix`, `docs`, `chore`, `refactor`, and `test`.

```text
feat: add range-per-tank card to vehicle detail
fix: correct mileage when a partial fill precedes a full tank
docs: explain full-tank rule in principles
```

Branch names carry a type prefix too:

```text
feature/range-per-tank
fix/partial-fill-mileage
```

Keep a branch focused on one change. A pull request that also reformats unrelated files or renames things you were not asked to touch is harder to review and more likely to hide a real bug.
