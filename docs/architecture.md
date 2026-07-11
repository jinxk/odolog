# OdoLog Architecture

## Stack summary

OdoLog is a single Flutter app targeting Android first, structured so the fuel economy math is testable in isolation and the storage layer can be swapped without touching screens. The packages were chosen to keep the moving parts few and the boundaries clear.

| Concern | Choice | Why |
|---|---|---|
| UI toolkit | Flutter (Material 3) | One codebase, native performance, Material 3 gives the theming and components the design calls for. iOS stays open for later. |
| State management | Riverpod with code generation | Compile-time-safe providers, easy to scope and dispose, testable without a widget tree. Codegen removes the boilerplate of hand-writing provider types. |
| Local database | sqflite | Mature SQLite binding for Flutter. Real SQL means the window and aggregate queries stay in the database where they belong, and an in-memory database makes repository tests fast. |
| Routing | go_router | Declarative routes, deep-link ready, plays well with a bottom navigation shell. |
| Functional error handling | fpdart | Gives `Either` so repositories return a typed failure or a value instead of throwing across layers. |
| Value equality | equatable | Cheap structural equality for domain models and stat value objects, which keeps Riverpod rebuilds honest and tests readable. |

No dependency injection framework beyond Riverpod, no ORM, no reactive database wrapper. The point is that a new contributor can read the whole thing.

## Layers

The dependency rule points inward: presentation and data both depend on domain, domain depends on nothing.

```
        +-----------------------------+
        |        Presentation         |
        |  widgets, screens, Riverpod |
        |     providers, go_router    |
        +--------------+--------------+
                       |
                       v  (calls use cases, reads models)
        +-----------------------------+
        |           Domain            |
        |  entities, value objects,   |
        |  repository interfaces,     |
        |  use cases, stat calculators|
        +--------------+--------------+
                       ^
                       |  (implements interfaces)
        +--------------+--------------+
        |            Data             |
        |  sqflite database, DAOs,    |
        |  repository implementations,|
        |  catalog JSON loader        |
        +-----------------------------+
```

Domain sits in the middle and knows about neither Flutter nor SQLite. Presentation and data both point at it. This is what lets every stat formula be unit tested with plain Dart and no database.

## Folder layout

```
lib/
  main.dart
  app/
    app.dart                 // MaterialApp.router, theme wiring
    router.dart              // go_router config, bottom-nav shell
    theme/
      colors.dart            // palette tokens (see Theme tokens)
      theme.dart             // light and dark ThemeData
  core/
    failures.dart            // Failure taxonomy
    typedefs.dart            // Result<T> = Either<Failure, T>
  domain/
    entities/
      vehicle.dart
      refuel_entry.dart
      fuel_variant.dart
    value_objects/
      window_mileage.dart
      vehicle_stats.dart
      entry_derived.dart
    repositories/
      vehicle_repository.dart      // interface
      refuel_repository.dart       // interface
      catalog_repository.dart      // interface
    calculators/
      mileage_calculator.dart      // pure full-tank window math
      aggregate_calculator.dart    // lifetime and monthly rollups
    usecases/
      add_vehicle.dart
      edit_vehicle.dart
      delete_vehicle.dart
      list_vehicles.dart
      log_refuel.dart
      edit_refuel.dart
      delete_refuel.dart
      get_vehicle_history.dart
      get_vehicle_stats.dart
      load_fuel_catalog.dart
      export_data.dart
      import_data.dart
  data/
    db/
      app_database.dart      // sqflite open, onCreate, onUpgrade
      migrations.dart
    daos/
      vehicle_dao.dart
      refuel_dao.dart
    models/
      vehicle_row.dart       // db row <-> entity mapping
      refuel_row.dart
    repositories/
      vehicle_repository_impl.dart
      refuel_repository_impl.dart
      catalog_repository_impl.dart
    catalog/
      catalog_loader.dart    // reads assets/fuel_catalog.json
  presentation/
    home/
    add_refuel/
    history/
    entry_detail/
    stats/
    vehicles/
    settings/
    common/                  // shared widgets: stat card, empty states
assets/
  fuel_catalog.json
```

## Domain model

Field listings below are Dart-ish, not final source. Ids are integers assigned by SQLite. Timestamps are stored as epoch milliseconds and surfaced as `DateTime`.

### Vehicle

```dart
class Vehicle {
  final int id;
  final String name;
  final VehicleType type;         // car | motorcycle | scooter | other
  final FuelCategory fuelCategory; // petrol | diesel | cng | lpg
  final String? registrationNo;   // optional
  final double? tankCapacity;     // optional, litres or kg per category
}
```

The fuel category fixes the unit for every entry on the vehicle: litre for petrol, diesel, and LPG, kg for CNG. Tank capacity only feeds projected range.

### RefuelEntry

```dart
class RefuelEntry {
  final int id;
  final int vehicleId;
  final DateTime filledAt;        // defaults to now at entry time
  final double odometer;          // km
  final double quantity;          // litres, or kg for CNG
  final double pricePaid;         // rupees, total for this fill
  final bool fullTank;            // defaults true
  final String? variantId;        // fuel_catalog product id, or null
  final String? variantOther;     // free text when variant is "Other"
  final String? stationName;      // optional
  final String? notes;            // optional
  final bool odometerOverride;    // set when a non-increasing odo was allowed
}
```

### FuelVariant

Loaded from the JSON asset, not stored in the database. An entry keeps only the `variantId` (or the free-text `variantOther`), so a later catalog rename never rewrites history.

```dart
class FuelVariant {
  final String id;          // e.g. "iocl_xp95"
  final String brandId;     // e.g. "iocl"
  final String brandName;   // e.g. "IndianOil"
  final String name;        // e.g. "XP95"
  final FuelCategory category;
  final String? tier;       // regular | premium | ultra, optional
  final String unit;        // "litre" | "kg"
}
```

### Computed value objects

These are outputs of the calculators, never persisted. They exist so a screen receives one typed object instead of a bag of loose doubles.

```dart
class EntryDerived {
  final double pricePerUnit;
  final double? distanceSincePrevious; // null for the first entry
}

class WindowMileage {
  final int openingEntryId;   // full fill that opened the window
  final int closingEntryId;   // full fill that closed it
  final double distance;      // km
  final double fuelConsumed;  // litres or kg
  final double mileage;       // km per unit
  final double costInWindow;  // rupees
  final double costPerKm;
}

class VehicleStats {
  final double totalSpend;
  final double totalDistance;
  final double totalQuantity;
  final double? averageMileage;    // null until a window closes
  final double? averageCostPerKm;  // null until a window closes
  final WindowMileage? latestWindow;
  final double? lastFillRange;
  final double? projectedRange;    // null without tank capacity
}
```

## Repository interfaces

Repositories return `Either<Failure, T>` (aliased as `Result<T>`) so callers handle failure explicitly instead of catching exceptions across layers.

```dart
typedef Result<T> = Either<Failure, T>;

abstract class VehicleRepository {
  Future<Result<List<Vehicle>>> getAll();
  Future<Result<Vehicle>> getById(int id);
  Future<Result<Vehicle>> add(Vehicle vehicle);
  Future<Result<Vehicle>> update(Vehicle vehicle);
  Future<Result<Unit>> delete(int id);
}

abstract class RefuelRepository {
  Future<Result<List<RefuelEntry>>> getForVehicle(int vehicleId); // ordered by odometer then filledAt
  Future<Result<RefuelEntry>> getById(int id);
  Future<Result<RefuelEntry>> add(RefuelEntry entry);
  Future<Result<RefuelEntry>> update(RefuelEntry entry);
  Future<Result<Unit>> delete(int id);
}

abstract class CatalogRepository {
  Future<Result<List<FuelVariant>>> load();
}
```

The domain calculators consume the plain ordered list from `getForVehicle` and produce the value objects above. Ordering by odometer first, then timestamp, is deliberate: the window algorithm walks entries in the sequence they were driven, and the odometer is the source of truth for that order.

## Use cases

Each use case is a thin, single-responsibility class that orchestrates repositories and calculators. One line each:

- **AddVehicle** validates and stores a new vehicle.
- **EditVehicle** updates a vehicle; changing tank capacity refreshes projected range only.
- **DeleteVehicle** removes a vehicle and, by cascade, its entries.
- **ListVehicles** returns all vehicles for the switcher.
- **LogRefuel** validates a fill (see validation rules) and stores it.
- **EditRefuel** updates a fill and triggers a window recompute for the affected vehicle.
- **DeleteRefuel** removes a fill and recomputes affected windows.
- **GetVehicleHistory** returns entries with their per-entry derived values for the timeline.
- **GetVehicleStats** runs the calculators to produce `VehicleStats` for the dashboard and stats screen.
- **LoadFuelCatalog** reads and parses the JSON asset into `FuelVariant` objects, filtered by category on request.
- **ExportData** serialises vehicles and entries to CSV or a JSON backup.
- **ImportData** parses and validates an incoming CSV or JSON backup before it touches the database.

## SQLite schema

Two tables. Money and quantities are stored as `REAL`; ids and flags as `INTEGER`. SQLite has no boolean, so flags are 0 or 1. Timestamps are epoch milliseconds.

```sql
CREATE TABLE vehicles (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  name           TEXT    NOT NULL,
  type           TEXT    NOT NULL,   -- car | motorcycle | scooter | other
  fuel_category  TEXT    NOT NULL,   -- petrol | diesel | cng | lpg
  registration   TEXT,
  tank_capacity  REAL
);

CREATE TABLE refuel_entries (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  vehicle_id        INTEGER NOT NULL,
  filled_at         INTEGER NOT NULL,          -- epoch millis
  odometer          REAL    NOT NULL,
  quantity          REAL    NOT NULL,
  price_paid        REAL    NOT NULL,
  full_tank         INTEGER NOT NULL DEFAULT 1,
  variant_id        TEXT,
  variant_other     TEXT,
  station_name      TEXT,
  notes             TEXT,
  odometer_override INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (vehicle_id) REFERENCES vehicles (id) ON DELETE CASCADE
);

CREATE INDEX idx_entries_vehicle_odo
  ON refuel_entries (vehicle_id, odometer);

CREATE INDEX idx_entries_vehicle_time
  ON refuel_entries (vehicle_id, filled_at);
```

`ON DELETE CASCADE` handles vehicle deletion cleanly, and foreign keys are enabled per connection (`PRAGMA foreign_keys = ON`) since sqflite leaves them off by default. The composite index on `(vehicle_id, odometer)` backs the window walk; the timestamp index backs history and monthly grouping.

### Migration policy

The database carries a schema `version` integer. `onCreate` builds the tables above at the current version. `onUpgrade` receives `oldVersion` and `newVersion` and applies ordered, forward-only steps, one `if (oldVersion < N)` block per version bump, each an additive migration where possible (add a column, add a table, add an index). Destructive changes get a data-preserving path rather than a drop. Every migration ships with a test that opens a database at the old version, runs the upgrade, and asserts the data survived.

## Fuel catalog asset

The catalog lives at `assets/fuel_catalog.json`, registered in `pubspec.yaml`. `CatalogRepositoryImpl` loads it through `rootBundle`, parses it once, and caches the result for the session. Its own `version` field lets a future in-app update, or a shipped update, detect a newer catalog. Because entries store the product `id` and not a label, updating the catalog never invalidates existing history. A missing or unparseable asset degrades to an empty brand list plus the always-present "Other" free-text option, so fuel logging never blocks on the catalog.

## State management

Riverpod with codegen, one provider layer per screen:

- Repository and database providers are declared `keepAlive` (they hold the open database and the parsed catalog for the app's lifetime).
- Screen providers (dashboard stats, history list, stats page) are auto-disposed by default, so leaving a screen frees its state and re-entering recomputes from the source of truth.
- The add and edit refuel form uses a `keepAlive` form-state provider scoped to the flow, so a mis-tap that navigates away for a moment does not wipe half-typed input. It is disposed explicitly on save or cancel.
- Calculators are pure functions invoked inside providers, not providers themselves, which keeps the stat math trivially unit testable outside Riverpod.

## Error handling

Failures are a small sealed taxonomy in `core/failures.dart`. Repositories and use cases return them inside `Either`; the presentation layer maps each to a message or an inline field error.

- **ValidationFailure** carries a field and a reason (odometer not greater than previous, non-positive quantity or price, date in the future). The add form renders these against the specific field.
- **DatabaseFailure** wraps a sqflite error (disk full, constraint violation, corrupt file). Surfaced as a non-destructive error banner with a retry.
- **NotFoundFailure** for a vehicle or entry id that does not resolve, which mostly guards against a stale route argument.

Validation rules enforced before write: odometer strictly greater than the previous entry's unless `odometer_override` is set; quantity and price strictly positive; `filled_at` not in the future. These live in the `LogRefuel` and `EditRefuel` use cases so the same rules apply whether the write comes from the form or from an import.

## Testing strategy

Three tiers, weighted toward the math because that is where correctness matters most.

- **Pure unit tests** cover every calculator with hand-computed expected values: price per unit, distance since previous, the full-tank window algorithm (including a window that spans one or more partial fills, a partial-only history that yields no window, and the distance-weighted average mileage), cost per km, and both range figures. The worked example from the design doc becomes a test fixture so the documented numbers and the code cannot drift apart.
- **Repository tests** run against an in-memory sqflite database. They exercise CRUD, the `ON DELETE CASCADE`, ordering by odometer, and each migration (open old, upgrade, assert). Fast enough to run on every change.
- **Widget tests** cover the add refuel form: field order, the live price-per-unit hint, validation error rendering, the collapsed optional section, and the full-tank toggle default. Enough of the home dashboard is covered to confirm empty states render before the second entry and before the first closed window.

## Future-proofing

Kept short on purpose, since none of this is built in v1. iOS is a later target and the layering already keeps Flutter-specific code out of the domain, so the platform lift is mostly build config and platform-channel details, not a rewrite. An EV category would add a `kwh` unit and a `charge` fuel category, which the unit-follows-category design already anticipates; the window math is unit-agnostic and would report km/kWh without change. Both remain out of scope until the core logging and stats earn their keep.
