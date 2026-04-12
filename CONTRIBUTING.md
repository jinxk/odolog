# Contributing to OdoLog

Thanks for taking a look. Bug fixes, features off the [roadmap](README.md#roadmap), and doc improvements are all welcome. Open an issue before starting anything big so we can agree on the shape of it. Small fixes can go straight to a PR. Browse the [open issues](https://github.com/jinxk/odolog/issues) if you want something to pick up.

## Reporting a bug

Open an issue and include enough for me to reproduce it:

- Device (make and model)
- Android version
- What you did, step by step
- What you expected, and what actually happened

A mileage or cost number that looks wrong is a bug. Include the refuel entries involved: litres, amount, odometer, and whether each fill was a full tank.

## Proposing a feature

Open an issue before writing code. Describe the problem you are trying to solve, not just the feature you have in mind. See [docs/principles.md](docs/principles.md) for the scope the app sticks to.

## Setup

You need Flutter on the stable channel and an Android SDK. Then:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The codegen step is required. Riverpod providers and a few other classes are generated, and the app will not compile without them. If you are editing annotated code, run `dart run build_runner watch --delete-conflicting-outputs` in a spare terminal instead of rebuilding by hand.

## Architecture

The code is Clean Architecture in three layers, dependency rule pointing inward. Rules a PR is held to:

- `lib/domain` is pure Dart. No Flutter imports. Its tests run without an emulator.
- The domain defines repository interfaces; `lib/data` implements them against SQLite. SQLite is the single source of truth for anything persisted.
- Operations that can fail return `Result<T>`, which is `Either<Failure, T>` from fpdart. Return a `Failure` on the left, do not throw across a layer boundary.
- `lib/presentation` holds the widgets, Riverpod providers, routing, and theme.
- Offline-first and privacy-first: everything stays on the device. No network calls, no analytics, no telemetry, no crash reporters.

See [docs/architecture.md](docs/architecture.md) for the longer version.

## Documentation standard

The codebase is moving toward this standard.

Every public class, method, and top-level function in `lib/domain` and `lib/data` gets a `///` dartdoc comment. In `lib/presentation`, document a widget when its job is not obvious from the name and skip the boilerplate ones.

What those comments should say:

- The first sentence is a one-line summary in the third person: "Computes the full-tank mileage windows.", "Stores a refuel row.". Not "This method computes...".
- Explain the why and the constraints, not the what. Say what the code cannot say for itself: units, edge cases, invariants, the reason a branch exists. A comment like `// increment counter` above `counter++` adds nothing.
- Every numeric API states its unit. Distance is km, volume is litres (mass in kg for CNG), money is in the vehicle's currency. If a value can be null, say what null means.
- Files with real logic (the calculators, repository implementations, migrations) get a library-level `///` doc comment at the top explaining what the file is responsible for.
- No `TODO` comments in a PR. Open an issue and link it instead.

`MileageCalculator` is a good example of the style.

## Quality gates

All three have to pass before a PR can merge, and CI runs them too:

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

`--fatal-infos` means infos fail the build, not just warnings.

## Conventions

- Files are snake_case, classes are PascalCase, variables are camelCase.
- A use case exposes a single public `execute()` and nothing else.
- Tests never hardcode an absolute date. Compute dates relative to `DateTime.now()`. The mileage tests already do this if you need a pattern.
- Tests live under `test/` mirroring `lib/`: domain logic gets plain unit tests, repositories get tested against a real in-memory database, widgets get widget tests.

## Commits and PRs

Conventional commit subjects, imperative mood, kept short:

```
feat: add Auto LPG to the fuel catalog
fix: drop windows with a non-increasing odometer
docs: document the mileage window math
```

Use `feat:`, `fix:`, `docs:`, or `chore:`. No trailers, and no body unless the change needs explaining. Put the work on a `feature/...` or `fix/...` branch. Keep a PR focused on one thing. If you spot something unrelated worth fixing, note it in the PR description or open a separate issue rather than folding it in.

## Localization and fuel presets

A good first contribution. The app is Indian by default and the mileage math works anywhere, so UI translations and fuel variant presets for other countries are welcome. If you know the common fuel grades where you live, adding them to the catalog is a small change.

## Code of conduct

Be kind. Assume good faith, keep it civil, and remember there is a person on the other end of every issue and review.
