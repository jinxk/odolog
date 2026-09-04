# Changelog

## 1.4.0 - 2026-09-04

- Release builds are minified and have unused code and resources stripped.
- A privacy page, a public roadmap, this changelog, issue and pull request templates, a security policy, and a code of conduct.
- Dependency updates.
- The mileage card no longer overflows on a 360 dp wide screen.

## 1.3.0 - 2026-08-29

- Update the odometer without logging a refuel, from Home or from the history list, so the service countdown and cost per km stay current between fills.
- Undo on a snack bar after deleting a refuel, a service entry, an expense, or an odometer reading.
- Delete all data from Settings, Data, behind a typed confirmation.
- A warning on the refuel form when the quantity goes past the tank capacity, with an estimated top-up.
- A reminders section in Settings: what is scheduled and when, a switch per category, and a test notification.
- The notification permission is asked for when the first expiry date or the first service is saved, not at first launch.

## 1.2.0 - 2026-08-09

- Restoring a backup runs as one transaction and rolls back whole if any row fails.
- A backup row naming a vehicle that is neither in the file nor on the device is refused instead of being attached to the wrong vehicle.
- Error states with a retry in place of a raw error string, and a real empty state on Stats.
- The vehicle name and the switcher on History, Stats, Service and Expenses.
- Save shows progress, and a save that fails is reported on the form instead of doing nothing.
- The start-up sweep is shorter and can be tapped away.

## 1.1.0 - 2026-07-18

- The history tab folds the service log and the expenses into one place.
- JSON backup format. CSV backups from 1.0 still restore.
- Automatic daily backup to Downloads/OdoLog, kept to the last seven days, and restore from the welcome screen.
- Rupee first refuel entry: amount chips and litres derived from your last price.
- Screen reader labels throughout.
- The odometer check now reads the fills either side of the date, not just the last one.

## 1.0.0 - 2026-05-24

- Visual overhaul: Material 3, the Inter type scale, and a hero first dashboard.
- Mileage trend chart, one point per full tank window.
- CSV export and import, a blank template to fill in, and a currency picker.
- Company claimed mileage shown next to the real figure.
- Document expiry reminders for insurance, PUC, RC and fitness, as local notifications.
- Service log with due reminders, and non-fuel expenses folded into a total cost of ownership figure.

## 0.1.0 - 2026-04-11

- Vehicles, the refuel log, and the core stats: mileage between full tanks, cost per km, range per tank, and monthly spend.
- India first fuel catalog: IOCL, BPCL, HPCL, Shell, Nayara, Jio-bp, CNG and Auto LPG.
- SQLite storage, offline only.
