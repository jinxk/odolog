# Contributing

Thanks for looking at OdoLog. It is a small app maintained by one person, and outside help is welcome. This page covers how to report a problem, how to suggest a change, and what a pull request needs to pass.

## Reporting a bug

Open an issue and include enough for me to reproduce it:

- Device (make and model)
- Android version
- What you did, step by step
- What you expected, and what actually happened

A mileage or cost number that looks wrong is a bug. Include the refuel entries involved: litres, amount, odometer, and whether each fill was a full tank.

## Proposing a feature

Open an issue before writing code. Describe the problem you are trying to solve, not just the feature you have in mind.

OdoLog is a fuel log, not a car super-app (see `principles.md`). Requests that pull it toward tracking service schedules, insurance, or routes will usually be declined.

## Pull requests

Read `development.md` before your first PR. The short version:

- The change is on a `feature/...` or `fix/...` branch.
- Commits follow conventional commit style (`feat`, `fix`, `docs`, `chore`, `refactor`, `test`).
- New calculations in `domain` have unit tests, and forms you touched have widget tests.
- All three quality gates pass locally:

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

If you changed anything annotated for code generation, rerun `dart run build_runner build --delete-conflicting-outputs` and commit the generated files.

Keep pull requests small and focused. If a change is big or you are unsure about the approach, open a draft early.

## Localization and fuel presets

A good way to help. The app is Indian by default and the mileage math works anywhere, so translations of the UI text and fuel variant presets for other countries are welcome. If you know the common fuel grades where you live, adding them to the catalog is a small change.

## Code of conduct

Be kind. Assume good faith, keep it civil, and remember there is a person on the other end of every issue and review.
